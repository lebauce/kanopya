# EResubmitNode.pm - Operation class implementing Cluster creation operation

#    Copyright © 2012 Hedera Technology SAS
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
# Created 25 sept 2012

=head1 NAME

EEntity::Operation::EResubmitNode - Operation class implementing a node resubmition its IAAS

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement a node resubmition to its IAAS operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EEntity::EOperation::EResubmitNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Entity;
use Externalnode::Node;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;
    General::checkParams(args => $self->{context}, required => [ "host" ]);
}


sub prepare {
    my ($self, %args) = @_;
    $self->SUPER::prepare();

    my $node = $self->{context}->{host}->node;

    if (! defined $node) {
        my $error = 'Host must be promoted to node to be resubmited';
        throw Kanopya::Exception::Internal::WrongValue(error => $error);
    }

    $self->{context}->{vm_cluster} = $node->inside;

    $self->{context}->{cloudmanager_comp} = EFactory::newEEntity(
                                                data => Entity->get(
                                                    id => $self->{context}->{host}->host_manager_id
                                                )
                                            );

    $self->{params}->{host_ram_origin}  = $self->{context}->{host}->host_ram;
    $self->{params}->{host_core_origin} = $self->{context}->{host}->host_core;

    if (! defined $self->{context}->{hypervisor}) {

        my $host_manager_params = $self->{context}->{vm_cluster}->getManagerParameters(manager_type => 'host_manager');

        $self->{context}->{host}->updateMemory(memory => $host_manager_params->{ram});
        $self->{context}->{host}->updateCPU(cpu_number => $host_manager_params->{core});

        my $cm = CapacityManagement->new(
                     cloud_manager => $self->{context}->{cloudmanager_comp},
        );

        my $hypervisor_id = $cm->getHypervisorIdResubmitVM(
                                vm_id           => $self->{context}->{host}->id,
                                wanted_values   => {
                                    ram           => $self->{params}->{host_ram_origin},
                                    cpu           => $self->{params}->{host_core_origin},
                                    ram_effective => 1*1024*1024*1024
                                }
                            );
    
        #TODO implement remediation like in EAddNode
        if (! defined $hypervisor_id) {
            my $error = 'Cannot find free hypervisor to resubmit node';
            throw Kanopya::Exception::Internal::WrongValue(error => $error);
        }

        $self->{context}->{hypervisor} = Entity->get(id => $hypervisor_id);

    }
}

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute();

    $self->{context}->{cloudmanager_comp}->onevm_resubmit(
        vm_nameorid => $self->{context}->{host}->host_hostname,
    );

    sleep(5); # Wait 5 seconds for the VM to be pending

    $self->{context}->{cloudmanager_comp}->onevm_deploy(
        vm_nameorid    => $self->{context}->{host}->host_hostname,
        host_nameorid  => $self->{context}->{hypervisor}->host_hostname,
    );

    sleep(5);

    $self->{context}->{cloudmanager_comp}->onevm_resubmit(
        vm_nameorid => $self->{context}->{host}->host_hostname,
    );

    sleep(5); # Wait 5 seconds for the VM to be pending

    $self->{context}->{cloudmanager_comp}->onevm_deploy(
        vm_nameorid    => $self->{context}->{host}->host_hostname,
        host_nameorid  => $self->{context}->{hypervisor}->host_hostname,
    );

    $self->{context}->{host}->setState(state => 'starting');
}

# Almost the same code than postStartNode prerequisite
sub postrequisites {
    my ($self, %args)  = @_;

    $self->{context}->{cloudmanager_comp} = EFactory::newEEntity(
                                                data => Entity->get(
                                                    id => $self->{context}->{host}->host_manager_id
                                                )
                                            );

    # Duration to wait before retrying prerequistes
    my $delay = 10;

    # Duration to wait for setting host broken
    my $broken_time = 240;

    my $host_id    = $self->{context}->{host}->id;

    # Check how long the host is 'starting'
    my @state = $self->{context}->{host}->getState;

    my $starting_time = time() - $state[1];
    if($starting_time > $broken_time) {
        $self->{context}->{host}->timeOuted();
    }

    my $node_ip = $self->{context}->{host}->adminIp;
    if (not $node_ip) {
        throw Kanopya::Exception::Internal(error => "Host <$host_id> has no admin ip.");
    }

    my $vm_state = $self->{context}->{cloudmanager_comp}->getVMState(
                           host => $self->{context}->{host},
    );

    $log->info('Vm <'.$host_id.'> opennebula status <'.($vm_state->{state}).'>');

    if ($vm_state->{state} eq 'runn') {
        $log->info('VM running try to contact it');
    }
    elsif ($vm_state->{state} eq 'boot') {
        $log->info('VM still booting');
        return $delay;
    }
    elsif ($vm_state->{state} eq 'fail' ) {
        my $lastmessage = $self->{context}->{cloudmanager_comp}->vmLoggedErrorMessage(opennebula3_vm => $self->{context}->{host});
        throw Kanopya::Exception(error => 'Vm fail on boot: '.$lastmessage);
    }
    elsif ($vm_state->{state} eq 'pend' ) {
        $log->info('timeout in '.($broken_time - $starting_time).' s');
        $log->info('VM still pending'); #TODO check HV state
        return $delay;
    }

    # Instanciate an econtext to try initiating an ssh connexion.
       if ( not $self->{context}->{'host'}->checkUp() ) {
            $log->info("Host <$host_id> not yet reachable at <$node_ip>");
            return $delay;
        }

    # Check if all host components are up.
    my @components = $self->{context}->{vm_cluster}->getComponents(category => "all");

    foreach my $component (@components) {
        my $component_name = $component->component_type->component_name;
        $log->debug("Browse component: " . $component_name);

        my $ecomponent = EFactory::newEEntity(data => $component);

        if (not $ecomponent->isUp(host => $self->{context}->{host}, cluster =>$self->{context}->{vm_cluster})) {
            $log->info("Component <$component_name> not yet operational on host <$host_id>");
            return $delay;
        }
    }

    # Node is up
    $self->{context}->{host}->setState(state => "up");
    $self->{context}->{host}->setNodeState(state => "in");
    $self->{context}->{host}->setAttr(name => 'hypervisor_id', value => $self->{context}->{hypervisor}->getId);

    my $ram = $self->{context}->{host}->getTotalMemory;
    my $cpu = $self->{context}->{host}->getTotalCpu;
    $self->{context}->{host}->setAttr(name => 'host_ram', value => $ram);
    $self->{context}->{host}->setAttr(name => 'host_core', value => $cpu);

    $self->{context}->{host}->save();
    $log->debug("Host <$host_id> is 'up'");

    return 0;
}


sub finish {
    my ($self) = @_;
    # Insert context for next operation defined in workflow_def (scalecpu and scalememory)
    $self->{params}->{cpu_number} = $self->{params}->{host_core_origin};
    $self->{params}->{memory}     = $self->{params}->{host_ram_origin};
    delete $self->{params}->{host_core_origin};
    delete $self->{params}->{host_ram_origin};
    delete $self->{context}->{hypervisor};
    delete $self->{context}->{vm_cluster};
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

