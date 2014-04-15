#    Copyright © 2014 Hedera Technology SAS
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

KanopyaServiceManager manage components installed on one or more nodes,
aggragte them as a unique entity called a service. A service provides
scale-in/scale out operations for the components, is defined by a set
of drivers used to manage the nodes on wihch the components are installed,
and can be pre-defined by a set of policies combined into service templates.

@since    2014-Apr-9
@instance hash
@self     $self

=end classdoc
=cut

package Entity::Component::KanopyaServiceManager;
use base Entity::Component;

use strict;
use warnings;

use Entity::Node;

use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Use the executor to run the operation AddCluster.

=end classdoc
=cut

sub createService {
    my ($self, %args) = @_;

    $args{context}->{service_manager} = $self;
    return $self->executor_component->enqueue(
               type       => 'AddCluster',
               params     => \%args,
           );
}


=pod
=begin classdoc

Use the executor to run the operation RemoveCluster.

=end classdoc
=cut

sub removeService {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'service' ],
                         optional => { 'keep_systemimages' => 0 });

    $log->debug("New Operation Remove Cluster with cluster id : " .  $args{service}->id);
    my $workflow = $self->executor_component->enqueue(
                       type   => 'RemoveCluster',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                           },
                           keep_systemimages => $args{keep_systemimages}
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}


=pod
=begin classdoc

Use the executor to run the operation ForceStopCluster.

=end classdoc
=cut

sub forceStopService {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    $log->debug("New Operation Force Stop Cluster with cluster: " . $args{service}->id);
    my $workflow = $self->executor_component->enqueue(
                       type   => 'ForceStopCluster',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                           }
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}


=pod
=begin classdoc

Use the executor to run the operation ActivateCluster.

=end classdoc
=cut

sub activateService {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    $log->debug("New Operation ActivateCluster with cluster_id : " . $args{service}->id);
    my $workflow = $self->executor_component->enqueue(
                       type   => 'ActivateCluster',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                           }
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}


=pod
=begin classdoc

Use the executor to run the operation DeactivateCluster.

=end classdoc
=cut

sub deactivateService {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    $log->debug("New Operation DeactivateCluster with cluster_id : " . $args{service}->id);
    my $workflow = $self->executor_component->enqueue(
                       type   => 'DeactivateCluster',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                           }
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}


=pod
=begin classdoc

Use the executor to execute the workflow addNode.

=end classdoc
=cut

sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    # Add the component type list to the args if defined
    my $components_params = {};
    if (defined $args{component_types}) {
        $components_params = {
            component_types => $args{component_types},
        };
    }

    my $workflow = $self->executor_component->run(
                       name   => 'AddNode',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                               host_manager    => $args{service}->getManager(manager_type => 'HostManager'),
                               disk_manager    => $args{service}->getManager(manager_type => 'DiskManager'),
                               export_manager  => $args{service}->getManager(manager_type => 'ExportManager'),
                           },
                           %$components_params
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}


=pod
=begin classdoc

Use the executor to execute the workflow StopNode.

=end classdoc
=cut

sub removeNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    my $workflow = $self->executor_component->run(
                       name   => 'StopNode',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                               host            => Entity::Node->get(id => $args{node_id})->host,
                           },
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}


=pod
=begin classdoc

Start the service by adding the first node.

=end classdoc
=cut

sub startService {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    return $args{service}->addNode();
}


=pod
=begin classdoc

Use the executor to execute the workflow StopCluster.

=end classdoc
=cut

sub stopService {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    my $workflow = $self->executor_component->enqueue(
                       type   => 'StopCluster',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                           },
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}


=pod
=begin classdoc

Use the executor to execute the operation UpdateCluster.

=end classdoc
=cut

sub reconfigureService {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'service' ]);

    my $workflow = $self->executor_component->enqueue(
                       type   => 'UpdateCluster',
                       params => {
                           context => {
                               service_manager => $self,
                               cluster         => $args{service},
                           },
                       }
                   );

    $workflow->addPerm(consumer => $args{service}->owner, method => 'get');
    $workflow->addPerm(consumer => $args{service}->owner, method => 'cancel');
    return $workflow;
}

1;
