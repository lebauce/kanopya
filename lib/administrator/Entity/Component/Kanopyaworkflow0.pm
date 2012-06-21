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

use Data::Dumper;
use Hash::Merge qw( merge);
use Log::Log4perl 'get_logger';
use WorkflowStep;
my $log = get_logger('administrator');
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
            workflow_def_id  => $new_wf_def->getId(),
            operationtype_id => $step->getAttr(name => 'operationtype_id'),
        );
    }
}

sub _getAutomaticValues{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['automatic_params']);

    my $automatic_params = $args{automatic_params};

    if (exists $automatic_params->{context}->{host}) {
        my $host = Entity::Host->find(hash => {'host_hostname' => $args{host_name}}); 
        $automatic_params->{context}->{host} = $host;
    }
    if (exists $automatic_params->{context}->{cloudmanager_comp}) {
        my $host = Entity::Host->find(hash => {'host_hostname' => $args{host_name}});
        my $cloudmanager_id   = $host->getAttr(name => 'host_manager_id');
        my $cloudmanager_comp = Entity->get(id => $cloudmanager_id);
        $automatic_params->{context}->{cloudmanager_comp} = $cloudmanager_comp;
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

sub runWorkflow_old {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [
                                            'workflow_def_id',
                                         ]);
    my $workflow_def_id = $args{workflow_def_id};
    my $workflow        = $self->getWorkflowDef(
                              workflow_def_id => $workflow_def_id
                          );
    my $workflow_name   = $workflow->getAttr(
                              name => 'workflow_def_name'
                          );

    #gather the workflow params
    my $all_params = $self->_getAllParams(
                        workflow_def_id => $workflow_def_id
                     );

    #resolve the automatic params values
    # NOT FULLY FUNCTIONNAL YET
    my $automatic_values = $self->_getAutomaticValues(
                                automatic_params => $all_params->{automatic},
                                sp_id            => $args{service_provider_id},
                                %args,
                           );
    #replace the undefined automatic params with the defined ones
    $all_params->{automatic} = $automatic_values;

    #run the workflow with fully the defined param
    my $workflow_params = merge(
    $all_params->{automatic},
    $all_params->{specific},
    );


    $log->info('*************************************************');
    $log->info(Dumper keys %$workflow_params);

    Workflow->run(name => $workflow_name, params => $workflow_params);
}


1;
