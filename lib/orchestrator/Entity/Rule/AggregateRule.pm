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

Logical formula of aggregate conditions

@see <package>Entity::AggregateCondition</package>

=end classdoc

=cut

package Entity::Rule::AggregateRule;
use base 'Entity::Rule';

use strict;
use warnings;

use Entity::AggregateCondition;
use Data::Dumper;
use Switch;
use List::Util qw {reduce};
use List::MoreUtils qw {any} ;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    aggregate_rule_id => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0,
    },
    aggregate_rule_last_eval => {
        pattern         => '^(0|1)$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    workflow_id => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    workflow_untriggerable_timestamp => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    formula_label => {
        is_virtual      => 1,
        is_editable     => 0,
        label           => 'Formula'
    }
};

sub getAttrDef { return ATTR_DEF; }


sub methods {
  return {
    'toString'  => {
      'description' => 'toString',
      'perm_holder' => 'entity'
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

Create a new instance of the class. Verify that the formula contains only AggregateCondition ids.
Update formula_string with toString() methods and the rule_name if not provided in attribute.

@return a class instance

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;

    # Clone case
    if ($args{aggregate_rule_id}) {
        return $class->get( id => $args{aggregate_rule_id})->clone(
            dest_service_provider_id => $args{service_provider_id}
        );
    }

    my $formula = (\%args)->{formula};
    _verify ($args{formula});

    my $self = $class->SUPER::new(%args);

    my $toString = $self->toString();
    if ((! defined $args{rule_name}) || $args{rule_name} eq '') {
        $self->setAttr(name=>'rule_name', value => $toString);
    }
    $self->setAttr(name=>'formula_string', value => $toString);
    $self->save();
    return $self;
}


=pod

=begin classdoc

Verify that the formula contains only AggregateCondition ids. throw
Kanopya::Exception::Internal::WrongValue if an id of the formula is not an AggregateCondition id

=end classdoc

=cut

sub _verify {

    my $formula = shift;

    my @array = split(/(id\d+)/,$formula);

    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            if (! (Entity::AggregateCondition->search(hash => {'aggregate_condition_id'=>substr($element,2)}))){
             my $errmsg = "Creating rule formula with an unknown aggregate condition id ($element) ";
             $log->error($errmsg);
             throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }
        }
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

    my @array = split (/(id\d+)/, $self->formula);
    for my $element (@array) {
        if ($element =~ m/id(\d+)/) {
            $element = Entity::AggregateCondition->get ('id'=>substr($element,2))->aggregate_condition_formula_string ;
        }
    }

    return List::Util::reduce { $a . $b } @array;
}


=pod

=begin classdoc

Evaluate the rule. Call evaluation of all depending conditions then evaluate the logical formula
of the rule according to conditions evaluation.

@return hash reference {service_provider_id => 1} is rule is verified
                       {service_provider_id => 0} otherwise

=end classdoc

=cut

sub evaluate {
    my ($self, %args) = @_;

    # Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$self->formula);

    # Replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id(\d+)/) {
            $element = Entity::AggregateCondition->get ('id'=>substr($element,2))->evaluate(%args);
            if (! defined $element) {
                $self->setAttr(name => 'aggregate_rule_last_eval', value=>undef);
                $self->save();
                return {$self->service_provider_id => undef};
            }
        }
    }

    my $res = -1;
    my $arrayString = '$res = '."(@array)";

    #Evaluate the logic formula
    eval $arrayString;

    if (defined $res){
        my $store = ($res)?1:0;
        return {$self->service_provider_id => $store};
    }

    return {$self->service_provider_id => undef};

}


=pod

=begin classdoc

Override setAttr to check the formula before updating

=end classdoc

=cut

sub setAttr {
    my $class = shift;
    my %args = @_;
    if ($args{name} eq 'formula'){
        _verify($args{value});
    }
    $class->SUPER::setAttr(%args);
};


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
        $attrs->{formula}    = $self->_cloneFormula(
            dest_sp_id              => $attrs->{service_provider_id},
            formula                 => $attrs->{formula},
            formula_object_class    => 'Entity::AggregateCondition'
        );
        $attrs->{aggregate_rule_last_eval}  = undef;
        $attrs->{workflow_def_id}           = undef;
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
    return "NotifyWorkflow service_provider";
}


=pod

=begin classdoc

Update the last evaluation of the rule in DB according to the given evaluation

@param evaluation hash table with only one key (service_provider_id => rule evaluation).

=end classdoc

=cut

sub setEvaluation {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['evaluation']);

    $self->setAttr(name => 'timestamp',value=>time());

    my $evaluation = (values %{$args{evaluation}})[0];

    $self->setAttr(name => 'aggregate_rule_last_eval',value=>$evaluation);
    $self->save();
}


=pod

=begin classdoc

Update the state of the rule in DB  according to the state of the workflow the rules had triggered earlier

=end classdoc

=cut

sub _updateWorkflowStatus {
    my ($self, %args) = @_;

    my $workflow_def = $self->workflow_def;

    if (! defined $workflow_def) {
        # Skip workflow status update if no WorkflowDef linked
        $log->info('No workflow defined for rule <' . $self->id . '>');
        return;
    }

    my $workflow = $self->workflow;

    if (! defined $workflow) {
        # Skip workflow status update if no workflow has been launched earlier
        $log->info('No workflow launched buy rule <' . $self->id . '>');
        return;
    }

    if ($workflow->state eq 'running') {
        $log->info('Workflow <'.$workflow->id.'> still running');
    }
    elsif ($workflow->state eq 'failed' || $workflow->state eq 'cancelled') {
        $log->info('Workflow <'.$workflow->id .'>, <'.$workflow->state .'> re-enable rule');
        $self->setAttr(name  => 'state', value => 'enabled' );
        $self->setAttr(name  => 'workflow_id',  value => undef );
        $self->save();
    }
    elsif ($workflow->state eq 'done') {
        $log->info('Workflow <'.$workflow->id.'> done');
        $self->setAttr(name  => 'state', value => 'enabled' );
        $self->setAttr(name  => 'workflow_id',  value => undef );
        $self->save();
    }
    elsif ($workflow->state eq 'delayed') {
        # Manage delay between 2 workflows triggering
        # Check whether delay is finished or rule has to wait
        my $delta = $self->workflow_untriggerable_timestamp - time();
        if (0 >= $delta) {
            $log->info('Workflow <'.$workflow->id.'> done, end of delay time, re-enable rule');
            $self->setAttr(name  => 'state', value => 'enabled' );
            $self->setAttr(name  => 'workflow_id', value => undef );
            $self->setAttr(name  => 'workflow_untriggerable_timestamp', value => undef );
            $self->save();
        }
        else {
            $log->info('Workflow <'.$workflow->id.'> done, still delaying time for <'.($delta).'> sec');
        }
    }
    elsif ($workflow->state eq 'triggered') {
        my $wf_params = $workflow_def->paramPresets;
        my $delay = $wf_params->{specific}->{delay};
        $log->info('wf_params = '.(Dumper $wf_params));

        if ((not defined $delay) || $delay <= 0) {
            $log->info('Workflow <'.$workflow->id.'> done, no delay or delay <= 0, re-enable rule');
            $self->setAttr(name  => 'state', value => 'enabled' );
            $self->setAttr(name  => 'workflow_id',  value => undef );
            $self->save();
        }
        else {
            $log->info('Workflow <'.$workflow->id.'> done, delay new workflow launch');
            $self->setAttr(name  => 'state', value => 'delayed' );
            $self->setAttr(name  => 'workflow_untriggerable_timestamp', value => time() + $delay);
            $self->save();
         }
    }
    else {
      $log->info('unknown case <'.($self->state).'>');
    }
    return;
}


=pod

=begin classdoc

Launch a workflow when rule is linked to a WorkflowDef according to its evaluation.

@param evaluation hash table with only one key (service_provider_id => rule evaluation).

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
        $log->info('No workflow manager in service provider <' . $sp->id . '>');
        return;
    }

    # Update last workflow possibly launched status before trying to trigger a new one
    $self->_updateWorkflowStatus();

    my $workflow_def_id = $self->workflow_def_id;

    if (! defined $workflow_def_id) {
        # Skip workflow management when service provider has no workflow_def
        $log->info('No workflow defined for rule <' . $self->id . '>');
        return;
    }

    my $evaluation = (values %{$args{evaluation}})[0];

    if (! defined $evaluation) {
        # Skip workflow management when rule is not verified
        $log->info('Rule <'. $self->id. '> result undefined');
        return;
    }

    if ($evaluation == 1){
        $log->info('Rule <'. $self->id. '> is verified');
        if ($self->state eq 'enabled') {
            $log->info('Rule <'. $self->id. '> has launched a new workflow (' . $workflow_def_id . ') and was defined as triggered');

            # Rule is enable, is verified and has a WorkflowDef => trigger the workflow !
            my $workflow = $workflow_manager->runWorkflow(
                               workflow_def_id     => $workflow_def_id,
                               rule_id             => $self->id,
                               service_provider_id => $sp->id
                           );

            $self->setAttr(name => 'state', value => 'triggered');
            $self->setAttr(name => 'workflow_id', value => $workflow->id);
            $self->save();
        }
        elsif ($self->state eq 'triggered') {
            $log->info('Rule: '.$self->id. ' is verified but a workflow is already triggered');
        }
        elsif ($self->state eq 'delayed') {
            $log->info('Rule: '.$self->id. ' is verified but workflow launching is delayed');
        }
        else {
            throw Kanopya::Exception(error => 'unkown case');
        }
    }
    elsif ($evaluation == 0) {
        $log->info('Rule <'. $self->id. '> is not verified');
    }
    else {
        my $errmsg = "Unkown rule evaluation value <$evaluation>";
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}
1;
