# WorkflowManager.pm - Object class of Workflow Manager included in Administrator

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
# Created 7 June 2012

=pod
=begin classdoc

Manage workflows launched by rules. Manage WorkflowDef creation, association to rules, parameter definition,
and launch workflow related to rules.

=end classdoc
=cut

package Manager::WorkflowManager;
use base "Manager";

use strict;
use warnings;
use Kanopya::Exceptions;
use General;
use Hash::Merge;

use Log::Log4perl "get_logger";
my $log = get_logger("");
use Data::Dumper;

use Entity::Rule;
use Entity::Rule::AggregateRule;
use Entity::Rule::NodemetricRule;
use Entity::WorkflowDef;
use WorkflowDefManager;
use ParamPreset;
use Scope;
use ScopeParameter;
use NotificationSubscription;
use TryCatch;

sub methods {
  return {
    getWorkflowDefsIds => {
        description => 'getWorkflowDefsIds',
    },
    getWorkflowDefs => {
        description => 'getWorkflowDefs',
    },
    createWorkflowDef => {
        description => 'createWorkflowDef',
    },
    associateWorkflow => {
        description => 'associateWorkflow',
    },
    deassociateWorkflow => {
        description => 'deassociateWorkflow',
    }
  };
}


sub checkWorkflowManagerParams {
    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Create a new instance of WorkflowDef.

@param workflow_name String WorkflowDef instance name

@optional params hashref Parameters
                         $hash->{specific} parameters whose values will be instanciate after rule association
                         $hash->{automatic} parameters whose values will be instanciate after rule triggering
                                            w.r.t the context (see _getAutomaticValues method)
                         $hash->{internal} internal misc parameters (e.g. $hash->{internal}->{scope_id})

@optional workflow_def_origin_id link a workflow_def created by a workflow_def origin to its origin
                                 (currently used in rule-workflow association)

@return the created workflowDef instance

=end classdoc
=cut

sub createWorkflowDef {
    my ($self,%args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'workflow_name' ],
                         optional => {params                 => undef,
                                      workflow_def_origin_id => undef});

    #TODO refactor all the parameters management by clarifying mandatory and authorized parameters categories
    # (automatic, specific, internal, data, data->template_content etc...)

    if (defined $args{params}) {
        if ((!exists $args{params}->{automatic}) && (!exists $args{params}->{specific})) {
            if (defined $args{params}->{data}->{template_content} && defined $args{params}->{internal}->{scope_id}) {

                #sort the specific params from the automatic params
                my $params = $self->_extractAutomaticAndSpecificParams(
                                 template_content => $args{params}->{data}->{template_content},
                                 scope_id         => $args{params}->{internal}->{scope_id},
                             );

                #append the automatic and specific params to workflow params
                $args{params}->{automatic} = $params->{automatic};
                $args{params}->{specific}  = $params->{specific};
            }
        }
    }

    my $workflow = Entity::WorkflowDef->new(workflow_def_name   => $args{workflow_name},
                                            workflow_def_origin => $args{workflow_def_origin_id},
                                            params              => $args{params});

    #now associating the new workflow to the manager

    WorkflowDefManager->new(
        manager_id      => $self->id,
        workflow_def_id => $workflow->workflow_def_id,
    );

    return $workflow;
}


=pod
=begin classdoc

Deassociate a workflowDef from a rule

@param rule_id the id of the rule

Warning old parameter workflow_def_id is deprecated

=end classdoc
=cut

sub deassociateWorkflow {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['rule_id']);

    my $rule = Entity::Rule->get(id => $args{rule_id});
    my $workflow_def = $rule->workflow_def;
    $rule->workflow_def_id(undef);

    if (defined $workflow_def) {
        my $wf_def_origin_id = $workflow_def->workflow_def_origin;
        $workflow_def->delete();
        # Check if there's subscriptions on this rule
        my @notification_subscriptions  = NotificationSubscription->search(hash => {
                                              entity_id => $args{rule_id}
                                          });

        if (@notification_subscriptions > 0) {
            my $orig_name = Entity->get(id => $wf_def_origin_id)->workflow_def_name;

            if (! ($orig_name eq $rule->notifyWorkflowName)) {
                # If any, must re-associate the rule with the empty workflow
                $rule->associateWithNotifyWorkflow();
            }
        }
    }
}


=pod
=begin classdoc

Create a new instance of WorkflowDef that has defined specific
parameters. This instance will be used for future runs

@param origin_workflow_def_id id of the WorkflowDef instance to be associated to a Rule instance
@param rule_id id of Rule instance to which the WorkflowDef instance will be associated

@optional specific_params hashref of specific param to add in addition to origin ones
@optional new_workflow_name specify a workflowDef name

@return the created workflow object (get by calling createWorkflowDef())

=end classdoc
=cut

sub associateWorkflow {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'origin_workflow_def_id',
                                                       'rule_id', ],
                                         optional => { 'specific_params' => {},
                                                       'new_workflow_name' => undef},
    );

    my $rule  = Entity::Rule->get(id => $args{rule_id});
    my $wfdef = Entity::WorkflowDef->get(id => $args{origin_workflow_def_id});

    if (! defined $args{new_workflow_name}) {
        $args{new_workflow_name} = $rule->id . "_" . $wfdef->workflow_def_name;
    }

    if (defined $rule->workflow_def) {
        $self->deassociateWorkflow(rule_id => $args{rule_id});
    }

    #get the original workflow's params and replace undefined specific params
    #with the now defined specific params
    my $workflow_params = $wfdef->paramPresets;

    $workflow_params->{specific} = $args{specific_params};

    #add special parameter to indicate that the workflow is associated
    #to a rule
    $workflow_params->{internal}->{association} = 1;

    my $workflow = $self->createWorkflowDef(
                       workflow_name          => $args{new_workflow_name},
                       params                 => $workflow_params,
                       workflow_def_origin_id => $args{origin_workflow_def_id}
                   );

    $rule->workflow_def_id($workflow->id);

    return $workflow;
}


=pod
=begin classdoc

Create a new instance of WorkflowDef from an existing instance and associate it to a rule

@param workflow_def_id id of the original WorkflowDef instance
@param rule_id id of the rule

=end classdoc
=cut

sub cloneWorkflow {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'workflow_def_id', 'rule_id' ]);
    my $rule_id = $args{rule_id};

    # Get original workflow def and params
    my $wf_def      = Entity::WorkflowDef->get(id => $args{workflow_def_id});
    my $workflow_def_origin_id = $wf_def->workflow_def_origin;

    if (! defined $workflow_def_origin_id) {
        throw Kanopya::Exception::Internal(error => 'Cannot clone WorfklowDef instance without origin');
    }

    my $wf_params   = $wf_def->paramPresets;
    my $wf_name     = $wf_def->workflow_def_name;

    # Replacing in workflow name the id of original rule with id of this rule
    # TODO change associated workflow naming convention (currently: <ruleid>_<origin_wf_def_name>) UGLY!
    $wf_name =~ s/^[0-9]*/$rule_id/;

    # Associate to the rule a copy of the workflow
    return $self->associateWorkflow(
               'new_workflow_name'         => $wf_name,
               'origin_workflow_def_id'    => $workflow_def_origin_id,
               'specific_params'           => $wf_params->{specific} || {},
               'rule_id'                   => $rule_id,
           );
}


=pod
=begin classdoc

Run a workflow the associated to a rule

@param rule Rule instance responsible for the workflow triggering
@optional host_name String node hostname responsible for the rule triggering

@return the corresponding Workflow instance

=end classdoc
=cut

sub runWorkflow {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['rule'], optional => {host_name => undef});

    my $execution_manager;

    try {
        $execution_manager = $self->service_provider->getManager(manager_type => 'ExecutionManager');
    }
    catch ($err) {
        my $error = 'Service provider <'. $self->service_provider->label
                    .'> has no Execution Manager. Cannot run workflow';
        throw Kanopya::Exception::Internal(error => $error);
    }

    my $wfdef = $args{rule}->workflow_def;

    #gather the workflow params
    my $all_params = $wfdef->paramPresets;

    #resolve the automatic params values
    my $automatic_values = $self->_getAutomaticValues(
                               automatic_params    => $all_params->{automatic} || {},
                               scope_id            => $all_params->{internal}->{scope_id},
                               service_provider_id => $args{rule}->service_provider_id,
                               host_name           => $args{host_name},
                           );

    #replace the undefined automatic params with the defined ones
    $all_params->{automatic} = $automatic_values;

    #prepare final workflow params hash
    my $workflow_params = $self->_defineFinalParams(
                              all_params        => $all_params,
                              workflow_def_name => $wfdef->workflow_def_name,
                              rule_id           => $args{rule}->id,
                              sp_id             => $args{rule}->service_provider_id,
                          );

    #run the workflow with the fully defined params
    return $execution_manager->run(
               name       => $wfdef->workflow_def_name,
               related_id => $args{rule}->service_provider_id,,
               params     => $workflow_params,
               rule       => $args{rule},
           );
}


=pod
=begin classdoc

Get a list of workflow defs related to the manager.

@optional no_associate if defined only original workflow defs (not associated to a rule)

=end classdoc
=cut

sub getWorkflowDefs {
    my ($self,%args) = @_;

    #first we gather all the workflow def related to the current manager
    my @manager_workflow_defs = WorkflowDefManager->search (
                            hash => {manager_id => $self->id}
                        );

    #then we create a list of workflow_def from the manager workflow_defs
    my @workflow_defs;

    my $validator = sub {return 1};

    if ($args{no_associate}) {
        $validator = sub {
            my $wfdef = shift;
            my $all_params = $wfdef->paramPresets;
            return ! defined $all_params->{internal}{association};
        }
    }

    for my $manager_workflow_def (@manager_workflow_defs) {
        my $workflow_def = $manager_workflow_def->workflow_def;
        if ($validator->($workflow_def)) {
            push @workflow_defs, $workflow_def;
        }
    }

    return \@workflow_defs;
}


=pod
=begin classdoc

Get specific and automatic params from workflow_def_id. Usefull for
GUI when retriving specific and automatic params is required

@workflow_def_id id of the WorkflowDef instance

=end classdoc
=cut

sub getParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'workflow_def_id' ]);
    my $all_params = Entity::WorkflowDef->get(id => $args{workflow_def_id})->paramPresets();

    my %params;

    $params{automatic} = $all_params->{automatic};
    $params{specific}  = $all_params->{specific};

    return \%params;
}


=pod
=begin classdoc

With the given params for a workflow def, extract the "data" params,
and then differenciate between them the automatic and specific
parameters.

@param template_content String from which will be extracted automatic and specific params
@parma scope_id Scope id. Automatic params depends on the scope id

=end classdoc
=cut

sub _extractAutomaticAndSpecificParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'template_content', 'scope_id' ]);

    #extract the parameter from the raw data given as parameter to the workflow
    my $paramsFromTemplate = $self->_extractParamsFromTemplate(template => $args{template_content});

    my $scope_parameter_list = ScopeParameter->getNames(scope_id => $args{scope_id});

    # Transform parameters list into hash in order to search in 0(1)
    my %scope_parameter_hash = map { $_ => 1 } @$scope_parameter_list;

    #now differenciate automatic params from specific ones
    my $sorted_params = {automatic => {}, specific => {}};

    for my $param (@$paramsFromTemplate) {
        if (defined $scope_parameter_hash{$param}) {
            $sorted_params->{automatic}->{$param} = undef;
        }
        else {
            $sorted_params->{specific}->{$param} = undef;
        }
    }

    return $sorted_params;
}


=pod
=begin classdoc

Get the list of ids of workflowDef related to the workflow manager

@return the list reference

=end classdoc
=cut

sub getWorkflowDefsIds {
    my $self = shift;

    my @workflow_defs = WorkflowDefManager->search(
                            hash => {manager_id => $self->id}
                        );

    my @wfids = map {$_->workflow_def_id} @workflow_defs;
    return \@wfids;
}


=pod
=begin classdoc

Extract in hashref templated parameters from template

@param template template string

@return hashref {param => undef}

=end classdoc
=cut

sub _extractParamsFromTemplate {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, optional => {template => ''});

    my @lines = split (/\n/, $args{template});

    my @paramsFromTemplate = ();

    foreach my $line (@lines) {
        my @split = split(/\[\%\s*|\s*\%\]/, $line);
        for (my $i = 1; $i < (scalar @split); $i+=2){
            push @paramsFromTemplate, $split[$i];
        }
    }

    return \@paramsFromTemplate;
}

1;
