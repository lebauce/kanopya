#    Copyright © 2011-2013 Hedera Technology SAS
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
my $err;

sub methods {
    return {
        createWorkflowDef => {
            description => 'create a workflow definition for this workflow manager.',
        },
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

@return the created workflowDef instance

=end classdoc
=cut

sub createWorkflowDef {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'workflow_name' ],
                         optional => { 'params' => undef, 'steps' => [], 'description' => '' });

    #TODO refactor all the parameters management by clarifying mandatory and authorized parameters categories
    # (automatic, specific, internal, data, data->template_content etc...)

    if ((defined $args{params}) &&
        (! exists $args{params}->{automatic} && ! exists $args{params}->{specific}) &&
        (defined $args{params}->{data}->{template_content})&&
        (defined $args{params}->{internal}->{scope_id})) {

        # Sort the specific params from the automatic params
        my $params = $self->_extractAutomaticAndSpecificParams(
                         template_content => $args{params}->{data}->{template_content},
                         scope_id         => $args{params}->{internal}->{scope_id},
                     );

        # Append the automatic and specific params to workflow params
        $args{params}->{automatic} = $params->{automatic};
        $args{params}->{specific}  = $params->{specific};
    }

    my $workflowdef = Entity::WorkflowDef->new(workflow_def_name => $args{workflow_name},
                                               description       => $args{description},
                                               param_presets     => $args{params});

    # Add step if defined
    for my $step (@{ $args{steps} }) {
        $workflowdef->addStep(operationtype_id => $step);
    }

    # Now associating the new workflow to the manager
    WorkflowDefManager->new(manager_id => $self->id, workflow_def_id => $workflowdef->id);

    return $workflowdef;
}


=pod
=begin classdoc

Specify automatic values of Workflow Manager.

=end classdoc
=cut

sub _getAutomaticValues {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Create the final hash param for workflow->run() for Workflow Manager.

=end classdoc
=cut

sub _defineFinalParams {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
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
    my ($self, %args) = @_;

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

Extract in hashref templated parameters from template

@param template template string

@return hashref {param => undef}

=end classdoc
=cut

sub _extractParamsFromTemplate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { template => '' });

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


=pod
=begin classdoc

Link the workflow manager with the common default workflow definitions

=end classdoc
=cut

sub linkCommonWorkflowsDefs {
    my ($self, %args) = @_;

    # Get the common worfkflow definitions for notification/validation purpose.
    my @notity_workflows_defs = Entity::WorkflowDef->search(hash => {
                                    workflow_def_name =>  { 'LIKE' =>  'NotifyWorkflow %' }
                                });

    for my $notify_workflow_def (@notity_workflows_defs) {
        try {
            WorkflowDefManager->new(manager_id => $self->id, workflow_def_id => $notify_workflow_def->id);
        }
        catch (Kanopya::Exception::DB::DuplicateEntry $err) {
            $log->warn("The workflow manager <" . $self->id . "> is alreday linked to the workflow " .
                       "definition <" . $notify_workflow_def->workflow_def_name . ">");
        }
        catch ($err) {
            $err->rethrow();
        }
    }
}

1;
