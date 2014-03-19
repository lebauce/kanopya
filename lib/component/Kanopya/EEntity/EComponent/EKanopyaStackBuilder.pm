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
                         required => [ 'services', 'stack_id', 'iprange', 'user', 'workflow' ]);

    # Check no cluster are active for this stack id
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {
                       'owner_id' => $args{user}->id,
                       'active'   => 1,
                       'entity_tags.tag.tag' => "stack_" . $args{stack_id}
                   });

    if (scalar(@clusters) > 0) {
        throw Kanopya::Exception::Internal(
                  error => "Found " . scalar(@clusters) . " active cluster(s) with tag " .
                           "stack_" . $args{stack_id} . ", can not build stack."
              );
    }

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
        entity_tags => [ Entity::Tag->findOrCreate(tag => "stack_" . $args{stack_id})->id ]
    };

    # Create each instance in an embedded workflow
    for my $servicedef (@{ $args{services} }) {
        General::checkParams(args => $servicedef, required => [ 'service_template_id' ]);

        # Build the cluster name from owner infos
        my $cluster_name = $args{user}->user_login . "_" . $servicedef->{service_template_id} . "_" .
                           $args{stack_id};

        $log->info("Creating 1 service with service_template " . $servicedef->{service_template_id} .
                   " for stack $args{stack_id}, with name $cluster_name.");

        # If some inactive instance exists from old builds, add a version numer to the name
        my @old = Entity::ServiceProvider::Cluster->search(hash => {
                       'owner_id'            => $args{user}->id,
                       'service_template_id' => $servicedef->{service_template_id},
                       'entity_tags.tag.tag' => "stack_" . $args{stack_id}
                   });

        if (scalar(@old)) {
            $cluster_name .= "_v" . scalar(@old);

            $log->info("Found " . scalar(@old) . " old service(s) of stack " . $args{stack_id} .
                       ", add version number to the service name: $cluster_name");
        }

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
                         required => [ 'user', 'workflow', 'stack_id' ],
                         optional => { 'erollback' => undef });

    # Retrieve the created cluster from name
    # NOTE: the service of a current stack are active
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {
                       'owner_id' => $args{user}->id,
                       'active'   => 1,
                       'entity_tags.tag.tag' => "stack_" . $args{stack_id}
                   });

    $log->info("Found " . scalar(@clusters) . " services for stack $args{stack_id}.");
    if (scalar(@clusters) <= 0) {
        throw Kanopya::Exception::Internal(
                  error => "Unable to find active clusters of the stack, " . 
                           "no active cluster found with owner " .  $args{user}->user_login .
                           ", with tag stack_" . $args{stack_id}
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

    $log->info("Check components extra configuration.");

    # Check the extra configuration
    General::checkParams(args => $components->{neutron}->{component}->extraConfiguration,
                         required => [ 'network' ]);
    General::checkParams(args => $components->{glance}->{component}->extraConfiguration,
                         required => [ 'images' ]);

    $log->info("Configuring cross stack components references.");

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

    $log->info("Creating volume group for cinder volumes.");

    # Create a volume group on the controller for Cinder.
    my $vg = Lvm2Vg->new(lvm2_id           => $components->{lvm}->{component}->id,
                         lvm2_vg_name      => "cinder-volumes",
                         lvm2_vg_freespace => 0,
                         lvm2_vg_size      => 10 * 1024 * 1024 * 1024);

    Lvm2Pv->new(lvm2_vg_id => $vg->id, lvm2_pv_name => "/dev/sda2");

    $log->info("Creating and exporting logical volume nova-instances-" . $args{user}->user_login .
               " on Kanopya");

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
            push @bypriority, $components->{$component}->{serviceprovider};
        }
    }

    # Finally start the instances
    # Note: reverse the array as enqueueNow insert operations at the head of the list.
    for my $instance (reverse @bypriority) {
        $log->info("Starting service " . $instance->label. " in an embedded workflow...");
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

sub configureStack {
    my ($self, %args) = @_;
    my ($result, $command);

    General::checkParams(args     => \%args,
                         required => [ 'user', 'keystone', 'novacontroller',
                                       'neutron', 'glance', 'novacompute', 'cinder' ]);

    try {
        # Get the network form neutron extra conf
        General::checkParams(args => $args{neutron}->extraConfiguration, required => [ 'network' ]);

        my $neutron_net = $args{neutron}->extraConfiguration->{network};

        # Get the image list form glance extra conf
        General::checkParams(args => $args{glance}->extraConfiguration, required => [ 'images' ]);

        my $images = $args{glance}->extraConfiguration->{images};

        my $mirror_url = 'http://mirror.intranet.hederatech.com/cloudimages';

        # Create openrc file
        my $openrc = "# Environement variables needed by OpenStack CLI commands.\n" .
                     "# See http://docs.openstack.org/user-guide/content/cli_openrc.html\n".
                     "export OS_TENANT_NAME=openstack\nexport OS_USERNAME=admin\n" .
                     "export OS_PASSWORD=keystone\nexport OS_AUTH_URL=http://" .
                     $args{novacontroller}->getMasterNode->host->getAdminIface->getIPAddr . ":5000/v2.0/";

        $command = 'echo "'. $openrc . '" > /root/openrc.sh && chmod +x /root/openrc.sh';
        $result = $args{novacontroller}->getEContext->execute(command => $command);
        if ($result->{exitcode}) {
            throw Kanopya::Exception::Execution(
                      error => "Failed to create openrc.sh on NovaContoller:\n$result->{stderr}"
                  );
        }

        # Check user ssh key
        if (! $args{user}->user_sshkey) {
            # throw Kanopya::Exception::Internal::NotFound('User has no SSH key registred !');
            $log->warn("User <" . $args{user}->user_login . "> has no SSH key registred !");
        }
        else {
            # Add SSH key
            $command = 'source /root/openrc.sh && echo "' . $args{user}->user_sshkey .
                       '" > /tmp/sshkey.pub && nova keypair-add --pub-key /tmp/sshkey.pub "' .
                       $args{user}->user_login . '" && rm /tmp/sshkey.pub';
            $result = $args{novacontroller}->getEContext->execute(command => $command);
            if ($result->{exitcode}) {
                throw Kanopya::Exception::Execution(
                          error => "Failed to add SSH key on Nova:\n$result->{stderr}"
                      );
            }
        }

        # Add Neutron Network
        (my $neutron_prefix = $neutron_net) =~ s/(\d{1,3}).(\d{1,3}).(\d{1,3}).(\d{1,3})\/24/$1.$2.$3/g;

        $command = "source /root/openrc.sh && neutron net-create --provider:network_type=flat " .
                   "--provider:physical_network=physnetflat --shared " . $args{user}->user_login .
                   "_network";
        $result = $args{neutron}->getEContext->execute(command => $command);
        if ($result->{exitcode}) {
            if ($result->{stderr} !~ m/Physical network physnetflat is in use/) {
                throw Kanopya::Exception::Execution (
                          error => "Failed to create network " . $args{user}->user_login .
                                   "_network on Neutron:\n$result->{stderr}"
                      );
            }
            $log->error("Failed to create network " . $args{user}->user_login .
                        "_network on Neutron:\n$result->{stderr}");
        }

        $command = "source /root/openrc.sh && neutron subnet-create " . $args{user}->user_login .
                   "_network " . $neutron_net . " --name " . $args{user}->user_login . "_subnet " .
                   "--no-gateway --allocation-pool start=$neutron_prefix.100,end=$neutron_prefix" .
                   ".200 --dns-nameserver " . $args{novacontroller}->service_provider->cluster_nameserver1 .
                   " --host-route destination=0.0.0.0/0,nexthop=$neutron_prefix.254";
        $result = $args{neutron}->getEContext->execute(command => $command);
        if ($result->{exitcode}) {
            if ($result->{stderr} !~ m/overlaps with another subnet/) {
                throw Kanopya::Exception::Execution (
                          error => "Failed to create network " . $args{user}->user_login .
                                   "_network on Neutron:\n$result->{stderr}"
                      );
            }
            $log->error("Failed to create network " . $args{user}->user_login .
                        "_network on Neutron:\n$result->{stderr}");
        }

        # Add images to Glance
        $args{glance}->getEContext->execute(command => 'mkdir -p /tmp/glance');
        foreach my $imgname (keys %{ $images }) {
            my $destpath = "/tmp/glance/" . $images->{$imgname};

            if ($args{glance}->getEContext->execute(command => "file $destpath")->{exitcode}) {
                $command = "source /root/openrc.sh && cd /tmp/glance && " .
                           "wget $mirror_url/$images->{$imgname} && glance image-create --name " .
                           "$imgname --disk-format=qcow2 --container-format=bare --is-public=True " .
                           "--file=$destpath";

                $result = $args{glance}->getEContext->execute(command => $command);
                if ($result->{exitcode}) {
                    throw Kanopya::Exception::Execution(
                              error => "Failed to import image " . $imgname .
                                       " on Glance:\n$result->{stderr}"
                          );
                }
            }
            else {
                $log->warn("Image $destpath laready exists in glance, skipping...");
            }
        }

        $args{glance}->getEContext->execute(command => 'rm -rf /tmp/glance');
    }
    catch ($err) {
        throw Kanopya::Exception::Execution::OperationInterrupted(
                  error => "Stack validation failed, interrupting the workflow.\n$err"
              );
    }

}


sub endStack {
    my ($self, %args) = @_;
    my ($result, $command);

    General::checkParams(args => \%args, required => [ 'user', 'stack_id' ]);

    # Retrieve the clusters of the current stack
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {
                       'owner_id' => $args{user}->id,
                       'active'   => 1,
                       'entity_tags.tag.tag' => "stack_" . $args{stack_id}
                   });

    $log->info("Found " . scalar(@clusters) . " services for stack $args{stack_id}.");
    if (scalar(@clusters) <= 0) {
        throw Kanopya::Exception::Internal(
                  error => "Unable to find active clusters of the stack, " .
                           "no active cluster found with owner " .  $args{user}->user_login .
                           ", with tag stack_" . $args{stack_id}
              );
    }

    # Stop the instances in embedded workflows
    for my $instance (@clusters) {
        # Set the cluster as inactive for this stack
        $instance->active(0);

        my ($state, $timestamp) = $instance->getState;
        if ($state ne 'down') {
            $log->info("Stopping service " . $instance->label. " in an embedded workflow...");
            $args{workflow}->enqueueNow(operation => {
                type       => 'StopCluster',
                priority   => 200,
                related_id => $self->service_provider->id,
                params     => {
                    context => {
                        cluster => $instance,
                    },
                },
            });
        }
        else {
            $log->info("Service " . $instance->label. " is down do not stopping it.");
        }

    }
}


sub unconfigureStack {
    my ($self, %args) = @_;
    my ($result, $command);

    General::checkParams(args => \%args, required => [ 'user', 'stack_id' ]);
}


sub cancelBuildStack {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'user' ]);

    # Retrieve the clusters of the current stack
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {
                       'owner_id' => $args{user}->id,
                       'active'   => 1,
                       'entity_tags.tag.tag' => "stack_" . $args{stack_id}
                   });

    for my $service (@clusters) {
        # Set the cluster as inactive for this stack
        $service->active(0);
    }
}

sub cancelStartStack {
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

sub cancelEndStack {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'user' ]);

}

1;
