#    Copyright © 2009-2012 Hedera Technology SAS
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

package EEntity::EOperation::EAddCluster;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;

use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use Entity::Gp;
use Entity;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;
our $VERSION = '1.00';


sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    # Check if all required params group are defined
    General::checkParams(args => $self->{params}, required => [ "cluster_params", "managers" ]);

    # Check required params within cluster params
    General::checkParams(args     => $self->{params}->{cluster_params},
                         required => [ "cluster_name", "cluster_si_shared", "cluster_si_persistent",
                                       "cluster_min_node", "cluster_max_node", "cluster_priority" ]);

    # Check required params within managers
    General::checkParams(args     => $self->{params}->{managers},
                         required => [ "host_manager", "disk_manager" ]);

    if (defined $self->{params}->{cluster_params}->{kernel_id} and
        not $self->{params}->{cluster_params}->{kernel_id}) {
        delete $self->{params}->{cluster_params}->{kernel_id};
    }

    # Check the boot policy or the export manager
    if (not ($self->{params}->{cluster_params}->{cluster_boot_policy} xor
             $self->{params}->{managers}->{export_manager}->{manager_id})) {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => "Can not specify boot_policy and export_manager_id at the same time."
              );
    }

    # Cluster creation
    eval {
        my $cluster = Entity::ServiceProvider::Inside::Cluster->new(%{$self->{params}->{cluster_params}});
        $self->{context}->{cluster} = EFactory::newEEntity(data => $cluster);
    };
    if($@) {
        $errmsg = "Cluster instanciation failed because : " . $@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

sub execute {
    my $self = shift;

    $self->{context}->{cluster}->create(managers        => $self->{params}->{managers},
                                        components      => $self->{params}->{components},
                                        interfaces      => $self->{params}->{interfaces},
                                        billing_limits  => $self->{params}->{billing_limits},
                                        orchestration   => $self->{params}->{orchestration},
                                        erollback       => $self->{erollback});

    $log->info("Cluster <" . $self->{context}->{cluster}->cluster_name . "> is now added");
}

sub finish {
    my $self = shift;

    delete $self->{context}->{service_template};
}

1;
