# EPreStopNode.pm - Operation class implementing Cluster creation operation

#    Copyright © 2011 Hedera Technology SAS
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
# Created 14 july 2010

=head1 NAME

EEntity::Operation::EPreStopNode - Operation class implementing Host creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Host creation operation

=head1 DESCRIPTION

EPreStopNode allows to prepare cluster for node addition.
It takes as parameters :
- host_id : Int (Scalar) : host_id identifies host
    which will be migrated into cluster to become a node.
- cluster_id : Int (Scalar) : cluster_id identifies cluster which will grow.

=head1 METHODS

=cut
package EOperation::EPreStopNode;
use base "EOperation";

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Externalnode::Node;
use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;

my $log = get_logger("");
my $errmsg;

my $config = {
    INCLUDE_PATH => '/templates/internal/',
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 0,               # cleanup whitespace
    EVAL_PERL    => 1,               # evaluate Perl code blocks
    RELATIVE => 1,                   # desactive par defaut
};


=head2 prerequisites

=cut

sub prerequisites {
    my ($self, %args) = @_;
    General::checkParams(args => $self->{context}, required => []);

    my $delay = 10;

    # Choose a random non master node
    if ((not defined $self->{context}->{host}) && (defined $self->{context}->{cluster})) {
        $log->info('No node selected, select a random node');

        my @nodes = Externalnode::Node->search(hash => {
                inside_id   => $self->{context}->{cluster}->getId(),
                master_node => 0,
        });

        if((scalar @nodes) == 0) {
            throw Kanopya::Exception(error => 'Cannot remove a node from cluster <'.($self->{context}->{cluster}->getId()).'> only one master left');
        }
        my $random_int = int(scalar (@nodes) * rand);

        my $node = $nodes[$random_int];

        $log->info('Node <'.$node->getId().'> selected to be removed between <'.(scalar @nodes).'> nodes');
        my $host = $node->host;

        $self->{context}->{host} = EFactory::newEEntity(data => $host);
    }

    # Check if there is a remediation_workflow
    # Currently : all vm migrations when removing an hypervisor

    if (not defined $self->{params}->{remediation_workflow_id}) {
        $log->info('no remediation workflow');
        $self->{params}->{remediation_workflow_id} = $self->{context}->{host}->checkStoppable->{remediation_workflow_id};
    }

    if (defined $self->{params}->{remediation_workflow_id}){

        my $wf = Workflow->get(id => $self->{params}->{remediation_workflow_id});
        $log->info('Remediation Workflow <'.($self->{params}->{remediation_workflow_id}).'> state <'.($wf->getAttr(name => 'state')).'> ');

        if($wf->getAttr(name => 'state') eq 'cancelled') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> cancelled, EXCEPTION');
            throw Kanopya::Exception::Internal(error => 'Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> has been cancelled');
        }
        elsif ($wf->getAttr(name => 'state') eq 'done') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> done, let us continue');
            # HERE NO RETURN => CONTINUE AFTER THE IF
        }
        elsif ($wf->getAttr(name => 'state') eq 'running') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> still running, waiting for its end');
            if(defined $self->{context}->{cluster}) {
                $self->{context}->{cluster}->unlock(workflow => $self->getWorkflow);
            }
            $self->{context}->{cluster} = undef;
            return $delay;
        }
        else {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> status unknown : '.($wf->getAttr(name => 'state')).', EXCEPTION');
            throw Kanopya::Exception::Internal(error => 'Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> has been cancelled');
        }
    }
    if(not defined $self->{context}->{cluster}) {
         my $cluster = Entity->get(id => $self->{context}->{host}->node->service_provider_id);
         $self->{context}->{cluster} = $cluster;
    }
    return 0;
}


=head2 prepare

=cut

sub prepare {

    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();
    General::checkParams(args => $self->{context}, required => [ 'host', 'cluster' ]);


    my $master_node_id = $self->{context}->{cluster}->getMasterNodeId();
    my $node_count     = $self->{context}->{cluster}->getCurrentNodesCount();
    my $host_id        = $self->{context}->{host}->getAttr(name => 'entity_id');

    if ($node_count > 1 && $master_node_id == $host_id){
        $errmsg = "Node <$host_id> is master node and not alone";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg, hidden => 1);
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my $components = $self->{context}->{cluster}->getComponents(category => "all");
    $log->info('Inform cluster components about node removal');

    foreach my $i (keys %$components) {
        my $comp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is " . ref($comp));
        $comp->preStopNode(host      => $self->{context}->{host},
                           cluster   => $self->{context}->{cluster},
                           erollback => $self->{erollback});
    }
    $self->{context}->{host}->setNodeState(state => "pregoingout");
}

1;
__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
