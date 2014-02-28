# Copyright © 2014 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

Kanopya executor runs workflows and operations

=end classdoc
=cut

package EEntity::EComponent::EKanopyaStackBuilder;
use base EEntity::EComponent;

use strict;
use warnings;

use TryCatch;
use Clone qw(clone);
use NetAddr::IP;

use Entity::ServiceProvider::Cluster;
use Entity::ServiceTemplate;

use IscsiPortal;
use Entity::Masterimage;
use Entity::Container;
use Entity::Netconf;
use Entity::NetconfRole;
use Lvm2Vg;
use Lvm2Pv;

use Kanopya::Database;
use Kanopya::Exceptions;
use Kanopya::Config;

use Log::Log4perl "get_logger";
my $log = get_logger("");


sub buildStack {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'services', 'iprange', 'user', 'workflow' ]);

    # Deduce the network to use from iprange
    my $ip = NetAddr::IP->new($args{iprange});
    my $network = Entity::Network->find(hash => { network_addr => $ip->addr, network_netmask => $ip-> mask});
    my $poolip = ($network->poolips)[0];

    # Try to use the iscsi portal corresponding to the iprange, use the kanopya one instead
    my $portal;
    my $portalip = $ip + 253;
    try {
        $portal = IscsiPortal->find(hash => { iscsi_portal_ip => $portalip });
    }
    catch ($err) {
        $log->warn("Unable to find iscsi portal with ip " . $portalip);
        $portal = IscsiPortal->find();
    }

    # Create a dedicated netconf without network connectivity for vm bridges
    my $vmsrole = Entity::NetconfRole->find(hash => { netconf_role_name => "vms" });
    my $vmsnetconf = Entity::Netconf->findOrCreate(netconf_name    => $args{user}->user_login . "-vms",
                                                   netconf_role_id => $vmsrole->id);

    # Define the common params for all services
    my $common_params = {
        owner_id       => $args{user}->id,
        active         => 1,
        # TODO: Find the proper masterimage from stack definition
        masterimage_id => Entity::Masterimage->find()->id,
        # TODO: Find the proper iscsi portal from network given in params
        iscsi_portals  => [ $portal->id ],
        interfaces     => [
            {
                interface_name => 'eth0',
                netconfs       => [ ($poolip->netconfs)[0]->id ]
            },
            {
                interface_name => 'eth1',
                netconfs       => [ $vmsnetconf->id ]
            },
        ],
    };

    # Create each instance in an embedded workflow
    for my $servicedef (@{ $args{services} }) {
        General::checkParams(args => $servicedef, required => [ 'service_template_id' ]);

        # Build the cluster name from owner infos
        my $cluster_name = $args{user}->user_login . "_" . $servicedef->{service_template_id};
        my $params = Entity::ServiceProvider::Cluster->buildInstantiationParams(
                         cluster_name => $cluster_name,
                         # Add the specific params
                         %{ $servicedef },
                         # Add the common params
                         %{ clone($common_params) }
                     );

        $args{workflow}->enqueueNow(operation => {
            type       => 'AddCluster',
            priority   => 200,
            params     => $params,
            related_id => $self->service_provider->id
        });
    }
}

sub startStack {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'user', 'workflow' ],
                         optional => { 'erollback' => undef });

    # Retrieve the created cluster from name
    # TODO: Be sure to imprive the search pattern to not get old stacks of the user
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {
                       owner_id => $args{user}->id,
                       active   => 1,
                   });

    if (scalar(@clusters) <= 0) {
        throw Kanopya::Exception::Internal(
                  error => 'Unable to find active clusters of the stack, ' . 
                           'no cluster found with owner ' .  $args{user}->user_login
              );
    }

    # Configure the stack :
    #   - Retrieve all components distributed on clusters of the stack
    #   - Set required inter-component references
    my $components = {};
    my @clusterids = map { $_->id } @clusters;
    for my $type ('Mysql', 'Amqp', 'Keystone', 'NovaController',
                  'NovaCompute', 'Glance', 'Neutron', 'Cinder', 'Lvm') {

        # Search for a component of type $type and that belongs to one of the cluster list
        $components->{lc($type)}->{component} = Entity::Component->find(
                                                    ensure_unique => 1,
                                                    hash => {
                                                        'component_type.component_name' => $type,
                                                        'service_provider_id'           => \@clusterids,
                                                    },
                                                );

        # Keep the service provider to sort services by components priority
        $components->{lc($type)}->{serviceprovider}
            = $components->{lc($type)}->{component}->service_provider;
    }

    $components->{keystone}->{component}->setConf(conf => {
        mysql5_id => $components->{mysql}->{component}->id,
    });

    $components->{novacontroller}->{component}->setConf(conf => {
        mysql5_id   => $components->{mysql}->{component}->id,
        keystone_id => $components->{keystone}->{component}->id,
        amqp_id     => $components->{amqp}->{component}->id
    });

    $components->{glance}->{component}->setConf(conf => {
        mysql5_id          => $components->{mysql}->{component}->id,
        nova_controller_id => $components->{novacontroller}->{component}->id
    });

    $components->{neutron}->{component}->setConf(conf => {
        mysql5_id          => $components->{mysql}->{component}->id,
        nova_controller_id => $components->{novacontroller}->{component}->id
    });

    $components->{cinder}->{component}->setConf(conf => {
        mysql5_id          => $components->{mysql}->{component}->id,
        nova_controller_id => $components->{novacontroller}->{component}->id
    });

    $components->{novacompute}->{component}->iaas_id(
        $components->{novacontroller}->{component}->id
    );

    # Create a volume group on the controller fro Cinder.
    my $vg = Lvm2Vg->new(lvm2_id           => $components->{lvm}->{component}->id,
                         lvm2_vg_name      => "cinder-volumes",
                         lvm2_vg_freespace => 0,
                         lvm2_vg_size      => 10 * 1024 * 1024 * 1024);

    Lvm2Pv->new(lvm2_vg_id => $vg->id, lvm2_pv_name => "/dev/sda2");

    # Create a logical volume on Kanopya to store nova instance meta data.
    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
    my $lvm = EEntity->new(data => $kanopya->getComponent(name => "Lvm"));
    my $nfs = EEntity->new(data => $kanopya->getComponent(name => "Nfsd"));

    my $shared;
    try {
        $shared = $lvm->createDisk(name       => "nova-instances-" . $args{user}->user_login,
                                   size       => 1 * 1024 * 1024 * 1024,
                                   filesystem => "ext4",
                                   erollback  => $args{erollback});
    }
    catch (Kanopya::Exception::Execution::AlreadyExists $err) {
        $log->warn("Logical volume nova-instances-" . $args{user}->user_login .
                   " already exists, skip creation...");

        $shared = EEntity->new(data => Entity::Container->find(hash => {
                      container_name => "nova-instances-" . $args{user}->user_login
                  }));
    }
    catch ($err) {
        $err->rethrow();
    }

    # Export the volume and the mount entry in all compute nodes
    my $export;
    try {
        $export = $nfs->createExport(container      => $shared,
                                     client_name    => "*",
                                     client_options => "rw,sync,fsid=0,no_root_squash",
                                     erollback      => $args{erollback});
    }
    catch (Kanopya::Exception::Execution::ResourceBusy $err) {
        $log->warn("Nfs export for volume nova-instances-" . $args{user}->user_login .
                   " already exists, skip creation...");

        $export = EEntity->new(data => Entity::ContainerAccess::NfsContainerAccess->find(hash => {
                      container_id => $shared->id
                  }));
    }
    catch ($err) {
        $err->rethrow();
    }

    $components->{novacompute}->{component}->service_provider->getComponent(category => "System")->addMount(
        mountpoint => "/var/lib/nova/instances",
        filesystem => "nfs",
        options    => "vers=3",
        device     => $export->container_access_export
    );

    # Start the database first, then the controller, then the compute
    my @bypriority;
    for my $component ('mysql', 'novacontroller', 'novacompute') {
        if (scalar(grep { $_->id == $components->{$component}->{serviceprovider}->id } @bypriority) <= 0) {
            $log->info("Start service " . $components->{$component}->{serviceprovider}->label .
                       " in the current workflow.");

            push @bypriority, $components->{$component}->{serviceprovider};
        }
    }

    # Finally start the instances
    # Note: reverse the array as enqueueNow insert operations at the head of the list.
    for my $instance (reverse @bypriority) {
        $args{workflow}->enqueueNow(workflow => {
            name       => 'AddNode',
            related_id => $instance->id,
            params     => {
                context => {
                    cluster => $instance,
                },
            },
        });
    }

    # Return the component instances to the operation that will keep its in the operation context
    return {
        keystone       => $components->{keystone}->{component},
        novacontroller => $components->{novacontroller}->{component},
        neutron        => $components->{neutron}->{component},
        glance         => $components->{glance}->{component},
        novacompute    => $components->{novacompute}->{component},
        cinder         => $components->{cinder}->{component},
    }
}

sub validateStack {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'user', 'keystone', 'novacontroller',
                                       'neutron', 'glance', 'novacompute', 'cinder' ]);

    $log->info("Validate stack");

    # All stuff to configure access to the stack for users
}

sub cancelStack {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'user' ]);

    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
    my $lvm = EEntity->new(data => $kanopya->getComponent(name => "Lvm"));

    try {
        my $container = Entity::Container->find(
                            container_name => "nova-instances-" . $args{user}->user_login
                        );

        # Remove the nova instances exports
        try {
            for my $export ($container->container_accesses) {
                if (defined $export->export_manager_id) {
                    EEntity->new(data => $export->export_manager)->removeExport(
                        container_access => EEntity->new(data => $export)
                    );
                }
            }
        }
        catch ($err) {
            $log->warn("Unable to remove exports:\n$err");
        }

        # Remove the nova instances disk
        try {
            $lvm->removeDisk(container => EEntity->new(data => $container));
        }
        catch ($err) {
            $log->warn("Unable to remove disk:\n$err");
        }
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        # No container created, skip
    }
    catch (Kanopya::Exception $err) {
        $err->rethrow()
    }
    catch ($err) {
        throw Kanopya::Exception(error => "$err");
    }
}

1;
