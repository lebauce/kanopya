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

use Entity::ServiceProvider::Cluster;
use Entity::ServiceTemplate;

use IscsiPortal;
use Entity::Masterimage;
use Lvm2Vg;
use Lvm2Pv;

use Kanopya::Database;
use Kanopya::Exceptions;
use Kanopya::Config;

use Log::Log4perl "get_logger";
my $log = get_logger("");


sub buildStack {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'stack', 'owner_id', 'workflow' ]);

    # TODO: parse the stack, deduce the list of service to intanciate
    # my ($services, $params) = $self->parseStack(stack => $args{stack});

    # Hardcoded stack, DistributedOpenStack:
    #  - 1 node instance of service "PMS DB and Messaging",
    #  - 1 node instance of service "PMS Distributed Controller"
    #  - 1 node instance of service "PMS Hypervisor"
    my $services = [
        Entity::ServiceTemplate->find(hash => { service_name => "PMS DB and Messaging" }),
        Entity::ServiceTemplate->find(hash => { service_name => "PMS Distributed Controller" }),
        Entity::ServiceTemplate->find(hash => { service_name => "PMS Hypervisor" })
    ];

    # Hardcoded params, inspired from lib test
    my $stackparams = {
        # TODO: Find the proper masterimage from stack definition
        masterimage_id => Entity::Masterimage->find()->id,
        # TODO: Find the proper iscsi portal from network given in params
        iscsi_portals  => [ IscsiPortal->find()->id ],
        vg_id          => Lvm2Vg->find()->id,
    };

    # Create each instance in an embedded workflow
    for my $service (@{ $services }) {
        my $user = Entity::User->get(id => $args{owner_id});

        # Build the cluster name from owner infos
        # TODO: name the instance as you want :)
        my $cluster_name = $user->user_login . "_" . $service->id;
        my $params = Entity::ServiceProvider::Cluster->buildInstantiationParams(
                         cluster_name        => $cluster_name,
                         service_template_id => $service->id,
                         owner_id            => $args{owner_id},
                         %{ $stackparams }
                     );

        # TODO: add netconf on interfaces, but it seems not trivial...
        #       Do it at startStack step instead.

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

    General::checkParams(args => \%args, required => [ 'owner_id', 'workflow' ]);

    # Retrieve the created cluster from name
    # TODO: Be sure to imprive the search pattern to not get old stacks of the user
    my $user = Entity::User->get(id => $args{owner_id});
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {
                       cluster_name => { 'LIKE' => $user->user_login . '_%' } }
                   );

    if (scalar(@clusters) <= 0) {
        throw Kanopya::Exception::Internal(
                  error => 'Unable to find clusters of the stack, ' . 
                           'no cluster found with name starting with ' .  $user->user_login . '_'
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
        $components->{lc($type)} = Entity::Component->find(hash => {
                                       'component_type.component_name' => $type,
                                       'service_provider_id'           => \@clusterids,
                                   });
    }

    $components->{keystone}->setConf(conf => {
        mysql5_id => $components->{mysql}->id,
    });

    $components->{novacontroller}->setConf(conf => {
        mysql5_id   => $components->{mysql}->id,
        keystone_id => $components->{keystone}->id,
        amqp_id     => $components->{amqp}->id
    });

    $components->{glance}->setConf(conf => {
        mysql5_id          => $components->{mysql}->id,
        nova_controller_id => $components->{novacontroller}->id
    });

    $components->{neutron}->setConf(conf => {
        mysql5_id          => $components->{mysql}->id,
        nova_controller_id => $components->{novacontroller}->id
    });

    $components->{cinder}->setConf(conf => {
        mysql5_id          => $components->{mysql}->id,
        nova_controller_id => $components->{novacontroller}->id
    });

    $components->{novacompute}->iaas_id($components->{novacontroller}->id);

    my $vg = Lvm2Vg->new(lvm2_id           => $components->{lvm}->id,
                         lvm2_vg_name      => "cinder-volumes",
                         lvm2_vg_freespace => 0,
                         lvm2_vg_size      => 10 * 1024 * 1024 * 1024);

    Lvm2Pv->new(lvm2_vg_id   => $vg->id,
                lvm2_pv_name => "/dev/sda2");

    # Code pasted from openstack.t, need to be adapted

    # my $kanopya = Kanopya::Tools::Retrieve::retrieveCluster();
    # my $lvm = EEntity->new(data => $kanopya->getComponent(name => "Lvm"));
    # my $nfs = EEntity->new(data => $kanopya->getComponent(name => "Nfsd"));
    # my $shared;
    # my $export;

    # $shared = $lvm->createDisk(
    #               name       => "nova-instances",
    #               size       => 1 * 1024 * 1024 * 1024,
    #               filesystem => "ext4",
    #           );

    # $export = $nfs->createExport(
    #                container => $shared,
    #                client_name => "*",
    #                client_options => "rw,sync,fsid=0,no_root_squash"
    #            );

    # my $system = $compute->getComponent(category => "System");

    # for my $export ($nfs->container_accesses) {
    #     $system->addMount(
    #         mountpoint => "/var/lib/nova/instances",
    #         filesystem => "nfs",
    #         options => "vers=3",
    #         device => $export->container_access_export
    #     );
    # }

    # Finally start the instances
    for my $instance (@clusters) {
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
}

sub validateStack {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'owner_id' ]);

    $log->info("Validate stack");

    # All stuff to configure access to the stack for users
}

1;
