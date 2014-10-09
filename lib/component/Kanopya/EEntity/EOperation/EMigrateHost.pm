#    Copyright © 2012-2013 Hedera Technology SAS
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

TODO

=end classdoc
=cut

package EEntity::EOperation::EMigrateHost;
use base EEntity::EOperation;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::Host;
use EntityState;
use CapacityManagement;
use TryCatch;

my $log = get_logger("");
my $errmsg;

sub check {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "host", "vm" ]);

    if (not defined $self->{context}->{cloudmanager_comp}) {
        $self->{context}->{cloudmanager_comp} = $self->{context}->{vm}->getHostManager();
    }
}


sub prepare {
    my ($self, %args) = @_;
    $self->{context}->{cloudmanager_comp}->increaseConsumers(operation => $self);
}

sub prerequisites {
    my ($self, %args) = @_;

    if (defined $self->{params}->{optimiaas}) {
        return 0;
    }

    my $diff_infra_db = $self->{context}->{cloudmanager_comp}
                             ->checkHypervisorVMPlacementIntegrity(host => $self->{context}->{host});
    eval {
        $diff_infra_db = $self->{context}->{cloudmanager_comp}
                              ->checkVMPlacementIntegrity(host          => $self->{context}->{vm},
                                                          diff_infra_db => $diff_infra_db);
    };
    if ($@) {
        my $error = $@;

        # Vm is not found in infrastructure
        # Enqueue synchronization in *new* workflow to repair DB
        # Throw exception to stop migration
        $self->_executor->enqueue(
            priority => 200,
            type     => 'SynchronizeInfrastructure',
            params   => {
                context => {
                    hypervisor => $self->{context}->{host},
                    vm         => $self->{context}->{vm},
                },
                diff_infra_db => $diff_infra_db,
            }
        );
        throw Kanopya::Exception(error => $error);
    }

    if (! $self->{context}->{cloudmanager_comp}->isInfrastructureSynchronized(hash => $diff_infra_db)) {

        # Repair infra before retrying AddNode

        $self->workflow->enqueueBefore(
            current_operation => $self,
            operation => {
                priority => 200,
                type     => 'SynchronizeInfrastructure',
                params   => {
                    context => {
                        hypervisor => $self->{context}->{host},
                        vm         => $self->{context}->{vm},
                    },
                    diff_infra_db => $diff_infra_db,
                }
            }
        );
        return -1;
    }
    return 0;
}

sub execute {
    my ($self, %args) = @_;

    # check if host is deactivated
    if ($self->{context}->{host}->active == 0) {
        throw Kanopya::Exception::Internal(error => 'hypervisor is not active');
    }

    # Check if the destination differs from the source
    my $vm_state = $self->{context}->{cloudmanager_comp}->getVMState(
        host => $self->{context}->{vm},
    );

    $log->debug('Destination hv <' . $self->{context}->{host}->node->node_hostname .
               '> vs cloud manager hv <' . $vm_state->{hypervisor} . '>');

    if ($self->{context}->{host}->node->node_hostname eq $vm_state->{hypervisor}) {
        $log->info('VM is on the same hypervisor, no need to migrate');
        $self->{params}->{no_migration} = 1;
    }
    else {
        # Check if there is enough resource in destination host
        my $vm_id = $self->{context}->{vm}->getAttr(name => 'entity_id');
        my $hv_id = $self->{context}->{'host'}->id();
        my $cm = CapacityManagement->new(
                     cloud_manager => $self->{context}->{cloudmanager_comp},
                 );

        my $check = $cm->isMigrationAuthorized(vm_id => $vm_id, hv_id => $hv_id);

        if ($check->{authorization} == 0) {
            throw Kanopya::Exception::Internal(error => $check->{error});
        }
    }

    if (defined $self->{params}->{no_migration}) {
        delete $self->{params}->{no_migration};
    }
    else {

        $log->info('Virtual machine <'
                   . $self->{context}->{vm}->node->node_hostname
                   . '> is migrating to hypervisor <'
                   . $self->{context}->{host}->node->node_hostname . '>');

        $self->{context}->{cloudmanager_comp}->migrateHost(
            host => $self->{context}->{vm},
            hypervisor => $self->{context}->{host},
        );
    }
}

sub finish {
    my ($self, %args) = @_;

    $self->{context}->{cloudmanager_comp}->decreaseConsumers(operation => $self);
    delete $self->{context}->{vm};
    delete $self->{context}->{host};
}

sub postrequisites {
    my $self = shift;

    my $migr_state = $self->{context}->{cloudmanager_comp}->getVMState(
                         host => $self->{context}->{vm},
                     );

    $log->info('Virtual machine <' . $self->{context}->{vm}->node->node_hostname
               . '> state: <'. $migr_state->{state} . '>, current hypervisor: <'
               . $migr_state->{hypervisor} . '>, destination hypervisor: <'
               . $self->{context}->{host}->node->node_hostname . '>');

    if ($migr_state->{state} eq 'runn') {

        if ($migr_state->{hypervisor} eq $self->{context}->{host}->node->node_hostname) {

            # After checking migration -> store migration in DB
            $self->{context}->{vm}->hypervisor_id($self->{context}->{host}->id);
            return 0;
        }
        else {
            # Vm is running but not on its hypervisor
            my $error = 'Migration of vm <' . $self->{context}->{vm}->node->node_hostname
                        . '> failed, but vm is still running...';
            $log->warn($error);
            Message->send(
                from    => 'EMigrateHost',
                level   => 'error',
                content => $error,
            );
            throw Kanopya::Exception(error => $error);
        }
    }
    elsif ($migr_state->{state} eq 'migr') {
        # vm is still migrating
        return 15;
    }
    throw Kanopya::Exception(error => 'Unattended state <'.$migr_state->{state}.'>');
}


=pod
=begin classdoc

Restore

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;
    $self->finish(%args);
}

1;
