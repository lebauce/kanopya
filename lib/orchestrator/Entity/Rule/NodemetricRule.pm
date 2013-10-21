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

=pod

=begin classdoc

Logical formula of node metric conditions

@see <package>Entity::NodemetricCondition</package>

=end classdoc

=cut

package Entity::Rule::NodemetricRule;
use base 'Entity::Rule';

use strict;
use warnings;

use Node;
use Entity::NodemetricCondition;
use Entity::ServiceProvider;
use VerifiedNoderule;
use WorkflowNoderule;

use List::MoreUtils qw {any} ;

use Data::Dumper;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    nodemetric_rule_id =>  {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0,
    },
    formula_label => {
        is_virtual      => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        toString => {
            description => 'toString',
        },
        isVerifiedForANode => {
            description => 'isverifiedForANode',
        }
    }
}

# Virtual attribute getter
sub formula_label {
    my $self = shift;
    return $self->formula_string;
}


=pod

=begin classdoc

@constructor

Create a new instance of the class.
Update formula_string with toString() methods and the rule_name if not provided in attribute.
Set rule evaluation 'undef' for each nodes of the service provider when rule is enabled.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Clone case
    if ($args{nodemetric_rule_id}) {
        return $class->get( id => $args{nodemetric_rule_id})->clone(
            dest_service_provider_id => $args{service_provider_id}
        );
    }

    my $self = $class->SUPER::new(%args);

    my $toString = $self->toString();

    $self->setAttr(name=>'formula_string', value => $toString);
    if (! defined $args{rule_name} || $args{rule_name} eq ''){
        $self->setAttr(name=>'rule_name', value => $toString);
    }
    $self->save();

    # When enabled, set undef for each node (will be update next orchestrator loop)
    if ($self->state eq 'enabled'){
        $self->setUndefForEachNode();
    }

    return $self;
}


=pod

=begin classdoc

For each nodes of the service provider, insert a VerifiedNodeRule entry with state 'undef'.

=end classdoc

=cut

sub setUndefForEachNode{
    my ($self) = @_;
    #ADD A ROW IN VERIFIED_NODERULE TABLE indicating undef data

    my @nodes = $self->service_provider->nodes;

    foreach my $node (@nodes) {
        $self->{_dbix}
        ->verified_noderules
        ->update_or_create({
            verified_noderule_node_id   => $node->id,
            verified_noderule_state     => 'undef',
        });
    }
}


=pod

=begin classdoc

Transform formula to human readable String

@return human readable String of the formula

=end classdoc

=cut

sub toString {
    my $self = shift;

    my @array = split(/(id\d+)/,$self->formula);
    for my $element (@array) {
        if ($element =~ m/id(\d+)/) {
            $element = Entity::NodemetricCondition->get('id'=>substr($element,2))->nodemetric_condition_formula_string;
        }
     }
     return "@array";
};


=pod

=begin classdoc

Evaluate the rule. Call evaluation of all depending conditions then evaluate the logical formula
of the rule according to conditions evaluation.

@return hash reference {node_id => 1} is rule is verified for node node_id
                       {node_id => 0} otherwise

=end classdoc

=cut

sub evaluate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'nodes' => undef });

    # If @nodes not provided, get all non-disabled nodes of the service provider
    my @nodes = (defined $args{nodes}) ? @{$args{nodes}}
                                       : $self->service_provider->searchRelated(
                                            filters => ['nodes'],
                                            hash    => {-not => {monitoring_state => 'disabled'}}
                                         );

    $args{nodes} = \@nodes;
    if (@nodes == 0) {
        return {};
    }

    # Get values of each NodemetricConditions
    my @nm_cond_ids = ($self->formula =~ m/id(\d+)/g);

    my %values = map { $_ => Entity::NodemetricCondition->get('id'=>$_)->evaluate(%args)
                 } @nm_cond_ids;


    # Evaluate conditionfor each node
    my %evaluation_for_each_node;
    NODE:
    for my $node (@nodes) {
        my %values_node = map { $_ => $values{$_}{$node->id}} @nm_cond_ids;

        for my $value (values %values_node) {
            if (!defined $value) {
                $evaluation_for_each_node{$node->id} = undef; next NODE;
            }
        }

        my $formula = $self->formula;
        $formula =~ s/id(\d+)/$values_node{$1}/g;
        $evaluation_for_each_node{$node->id} = (eval $formula) ? 1 : 0;
        $log->debug('NM rule evaluation for node <'.$node->id.">: $formula => ".$evaluation_for_each_node{$node->id});
    }

    return \%evaluation_for_each_node;
}


=pod

=begin classdoc

Check if the rule is verified in database for a given node

=end classdoc

=cut

sub isVerifiedForANode{
    my ($self, %args) = @_;

    my $node_id = (defined $args{node_hostname}) ?
                          Node->find (hash => {node_hostname => $args{node_hostname}})->id :
                          $args{node_id};

    my $verified_noderule_state;
    eval {
        $verified_noderule_state = VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node_id,
            verified_noderule_nodemetric_rule_id => $self->id,
        })->verified_noderule_state;
    };
    if($@) {
        return 0;
    }

    if ($verified_noderule_state eq 'verified') {
        return 1;
    }
    elsif ($verified_noderule_state eq 'undef') {
        return undef;
    }

    throw Kanopya::Exception::Internal::WrongValue(error => 'Wrong state value '.
    $verified_noderule_state.' for rule <'.$self->id.'> and node <'.($node_id).'>');
};


=pod

=begin classdoc

Set the rule state for a given node

=end classdoc

=cut

sub setVerifiedRule{
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node_id',
                                                       'state',
    ]);

    $self->{_dbix}
         ->verified_noderules
         ->update_or_create({
               verified_noderule_node_id    => $args{node_id},
               verified_noderule_state      => $args{state},
    });
}


=pod

=begin classdoc

Disable the rule

=end classdoc

=cut

sub disable {
    my $self = shift;

    $self->{_dbix}->verified_noderules->delete_all;
    $self->setAttr(name => 'state', value => 'disabled');
    $self->save();
};


=pod

=begin classdoc

Enable the rule and set it undef for each nodes of the service provider

=end classdoc

=cut

sub enable {
    my $self = shift;
    $self->setUndefForEachNode();
    $self->setAttr(name => 'state', value => 'enabled');
    $self->save();
}


=pod

=begin classdoc

Set the rule undef for each nodes of the service provider

=end classdoc

=cut

sub setAllRulesUndefForANode{
    my (%args) = @_;

    General::checkParams(args => \%args, required => ['cluster_id', 'node_id']);

    my $cluster_id     = $args{cluster_id};
    my $node_id        = $args{node_id};

    my @nodemetric_rules = Entity::NodemetricRule->search(
                               hash => {
                                   service_provider_id => $cluster_id,
                                   state               => 'enabled',
                               },
                           );

    foreach my $nodemetric_rule (@nodemetric_rules){
        $nodemetric_rule->{_dbix}
            ->verified_noderules
            ->update_or_create({
                verified_noderule_node_id    =>  $node_id,
                verified_noderule_state              => 'undef',
        });
    }
}


=pod

=begin classdoc

Clones the rule and all related objects.
Links clones to the specified service provider. Only clones objects that do not exist in service provider.

@param dest_service_provider_id id of the service provider where to import the clone

@return clone object

=end classdoc

=cut

sub clone {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_service_provider_id']);

    # Specific attrs management
    my $attrs_cloner = sub {
        my %args = @_;
        my $attrs = $args{attrs};
        $attrs->{formula}  = $self->_cloneFormula(
            dest_sp_id              => $attrs->{service_provider_id},
            formula                 => $attrs->{formula},
            formula_object_class    => 'Entity::NodemetricCondition'
        );
        $attrs->{workflow_def_id}   = undef;
        return %$attrs;
    };

    # Generic clone
    my $clone = $self->_importToRelated(
        dest_obj_id         => $args{'dest_service_provider_id'},
        relationship        => 'service_provider',
        label_attr_name     => 'rule_name',
        attrs_clone_handler => $attrs_cloner
    );

    # Clone workflow
    $self->cloneAssociatedWorkflow(
        dest_rule => $clone
    );

    return $clone;
}


sub notifyWorkflowName {
    return "NotifyWorkflow node";
}


=pod

=begin classdoc

Delete VerifiedNoderule entry corresponding to the node_id

@param node_id

=end classdoc

=cut

sub deleteVerifiedRule {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'node_id' ]);

    my $verified_noderule;
    eval{
        $verified_noderule = VerifiedNoderule->find(hash=>{
                                verified_noderule_node_id               => $args{node_id},
                                verified_noderule_nodemetric_rule_id    => $self->id,
                             });
    };

    if (defined $verified_noderule) {
        $verified_noderule->delete();
    }
}

=pod

=begin classdoc

Update the last evaluation of the rule in DB according to the given evaluation

@param evaluation hash table with evaluation for each nodes (node_id => rule evaluation).

=end classdoc

=cut

sub setEvaluation {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['evaluation']);

    # Loop on each nodes and its evaluation
    while (my ($node_id, $evaluation) = each(%{$args{evaluation}})) {
        if (defined $evaluation) {
            if ($evaluation eq 0) {
                $self->deleteVerifiedRule(node_id => $node_id);
            }
            else {
                $self->setVerifiedRule(
                    node_id => $node_id,
                    state   => 'verified',
                );
            }
        }
        else {
            $self->setVerifiedRule(
                node_id => $node_id,
                state   => 'undef',
            );
        }
    }
}


=pod

=begin classdoc

Launch a workflow when rule is linked to a WorkflowDef according to its evaluation.

@param evaluation hash table (node_id => rule evaluation).

=end classdoc

=cut

sub manageWorkflows {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['evaluation']);

    my $workflow_manager;
    my $sp = $self->service_provider;
    eval{
        if (defined $args{memoization}->{$sp->id}->{'WorkflowManager'}) {
            $workflow_manager = $args{memoization}->{$sp->id}->{'WorkflowManager'}
        }
        else {
            $workflow_manager = $sp->getManager(manager_type => 'WorkflowManager');
            $args{memoization}->{$sp->id}->{'WorkflowManager'} = $workflow_manager;
        }
    };
    if($@){
        # Skip workflow management when service provider has no workflow manager
        $log->info('No workflow manager in service provider <'.$sp->id.'>');
        return;
    }

    while (my ($node_id, $evaluation) = each %{$args{evaluation}}) {

        # Update last workflow possibly launched status before trying to trigger a new one
        my $workflowState = WorkflowNoderule->manageWorkflowState(
                                node_id            => $node_id,
                                nodemetric_rule_id => $self->id,
                            );

        $log->debug('Managing workflow state of rule <'.$self->id."> for node <$node_id> <"
                    .$workflowState->{state}.'>');

        if (! (defined $self->workflow_def_id && defined $evaluation && $evaluation == 1)) {
            # Skip workflow management when service provider has no workflow_def or rule
            # is not verified for this node

            $log->debug('Managing workflow state of rule <'.$self->id."> for node <$node_id> :
                         WorkflowDefId <".$self->workflow_def_id.">
                         Evaluation <$evaluation> => No worflow triggered");
            return;
        }

        if ($workflowState->{state} eq 'ready_to_launch') {
            $log->info('Trigger Workflow <'.$self->workflow_def_id.'>');

            # Launch workflow
            my $workflow = $workflow_manager->runWorkflow(
                               rule      => $self,
                               host_name => Node->get(id => $node_id)->node_hostname,
                           );

            WorkflowNoderule->new(node_id            => $node_id,
                                  nodemetric_rule_id => $self->id,
                                  workflow_id        => $workflow->id,);
        }
        elsif ($workflowState->{state} eq 'delayed') {
           $log->info('Not trigger workflow <'.$self->workflow_def_id.'> : delayed');
        }
        elsif ($workflowState->{state} eq 'running') {
           $log->info('Not trigger workflow <'.$self->workflow_def_id.'> : a workflow is still running');
        }
        else {
            throw Kanopya::Exception(error => 'unkown case <'.$workflowState->{state}.'>');
        }
    } #End node loop while
}

1;

