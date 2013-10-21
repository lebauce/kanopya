# KanopyaWorkflow.pm - Kanopya Workflow component
#    Copyright 2011 Hedera Technology SAS
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
# Created 5 june 2012

package Entity::Component::Kanopyaworkflow0;
use base 'Entity::Component';
use base 'Manager::WorkflowManager';

use strict;
use warnings;
use General;
use Kanopya::Exceptions;
use Entity::Host;

use Hash::Merge qw( merge);
use Log::Log4perl 'get_logger';
use WorkflowStep;
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

sub associateWorkflow {
    my ($self,%args) = @_;

    my $new_wf_def = $self->SUPER::associateWorkflow(%args);

    my @steps = WorkflowStep->search(
        hash => {
            workflow_def_id => $args{origin_workflow_def_id},
        }
    );

    for my $step (@steps) {
        WorkflowStep->new(
            workflow_def_id  => $new_wf_def->id,
            operationtype_id => $step->operationtype_id,
        );
    }

    return $new_wf_def;
}

sub _getAutomaticValues{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['automatic_params'],
                                         optional => {service_provider_id => undef});

    my $automatic_params = $args{automatic_params};

    if (exists $automatic_params->{context}->{host}) {
        my $host = Entity::Host->find(hash => {'node.node_hostname' => $args{host_name}});
        $automatic_params->{context}->{host} = $host;
    }
    if (exists $automatic_params->{context}->{cloudmanager_comp}) {
        my $host = Entity::Host->find(hash => {'node.node_hostname' => $args{host_name}});
        my $cloudmanager_id   = $host->getAttr(name => 'host_manager_id');
        my $cloudmanager_comp = Entity->get(id => $cloudmanager_id);
        $automatic_params->{context}->{cloudmanager_comp} = $cloudmanager_comp;
    }
    if (exists $automatic_params->{context}->{cluster}) {
        my $service_provider = Entity->get(id => $args{service_provider_id});
        $automatic_params->{context}->{cluster} = $service_provider;
    }

    return $automatic_params;
}


sub _defineFinalParams{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [
                                            'all_params',
                                         ]);
    my $workflow_params = merge(
        $args{all_params}->{automatic},
        $args{all_params}->{specific},
    );


    return $workflow_params;
}

1;
