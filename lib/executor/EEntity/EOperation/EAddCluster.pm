#    Copyright © 2009-2013 Hedera Technology SAS
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

Add a cluster to the system.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EAddCluster;
use base EEntity::EOperation;

use strict;
use warnings;

use Kanopya::Exceptions;
use EEntity;

use Entity::ServiceProvider::Cluster;
use Entity::Systemimage;
use Entity::Gp;

use Log::Log4perl "get_logger";
use Data::Dumper;
use TryCatch;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

@param cluster_params the params required to create the cluster.
@param managers the manager definition to apply on the cluster.

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;
    $self->SUPER::check(%args);

    # Check if all required params group are defined
    General::checkParams(args => $self->{params}, required => [ "cluster_params", "managers" ]);

    # Check required params within cluster params
    General::checkParams(args     => $self->{params}->{cluster_params},
                         required => [ "cluster_name", "cluster_si_persistent",
                                       "cluster_min_node", "cluster_max_node", "cluster_priority" ]);

    # Check required params within managers
    General::checkParams(args     => $self->{params}->{managers},
                         required => [ "host_manager", "disk_manager" ]);
}


=pod
=begin classdoc

Create the cluster and apply the configuration.

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    if (defined $self->{params}->{cluster_params}->{kernel_id} and
        not $self->{params}->{cluster_params}->{kernel_id}) {
        delete $self->{params}->{cluster_params}->{kernel_id};
    }

    # Check the boot policy or the export manager
    if (not ($self->{params}->{cluster_params}->{cluster_boot_policy} or
             $self->{params}->{managers}->{export_manager}->{manager_id})) {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => "One must specify either boot_policy or export_manager_id."
              );
    }

    # Cluster creation
    my $cluster = Entity::ServiceProvider::Cluster->new(%{ $self->{params}->{cluster_params} });
    $self->{context}->{cluster} = EEntity->new(data => $cluster);

    $self->{context}->{cluster}->create(managers        => $self->{params}->{managers},
                                        components      => $self->{params}->{components},
                                        interfaces      => $self->{params}->{interfaces},
                                        billing_limits  => $self->{params}->{billing_limits},
                                        orchestration   => $self->{params}->{orchestration},
                                        erollback       => $self->{erollback});

    $log->info("Cluster <" . $self->{context}->{cluster}->cluster_name . "> is now added");
}


=pod
=begin classdoc

Set the cluster as down.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;
    $self->SUPER::finish(%args);

    $self->{context}->{cluster}->setState(state => 'down');

    # Do not need params in the workflow any more
    delete $self->{params}->{managers};
    delete $self->{params}->{components};
    delete $self->{params}->{interfaces};
    delete $self->{params}->{billing_limits};
    delete $self->{params}->{orchestration};
    delete $self->{params}->{cluster_params};
}


=pod
=begin classdoc

Remove the cluster.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;

    try {
        # Deactivate and remove the cluster
        $self->{context}->{cluster}->active(0);
        $self->{context}->{cluster}->remove();
    }
    catch ($err) {
        $log->error("Unable to remove cluster:\n$err");
    }
}

1;
