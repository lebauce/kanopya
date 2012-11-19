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

package Entity::AggregateRule;

use strict;
use warnings;
use TimeData::RRDTimeData;
use base 'Entity';
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
    aggregate_rule_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    aggregate_rule_service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 0,
    },
    aggregate_rule_formula => {
        pattern         => '^((id\d+)|and|or|not|[ ()!&|])+$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
        description     => "Construct a formula by condition's names with logical operators (and, or, not)."
                           . " It's possible to use parenthesis with spaces between each element of the formula."
                           . " Press a letter key to obtain the availalbe choice.",
    },
    aggregate_rule_formula_string => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    aggregate_rule_last_eval => {
        pattern         => '^(0|1)$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    aggregate_rule_timestamp => {
        pattern        => '^.*$',
        is_mandatory   => 0,
        is_extended    => 0,
        is_editable    => 1,
    },
    aggregate_rule_state => {
        pattern         => '(enabled|disabled|delayed|triggered)$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    },
    workflow_def_id => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    aggregate_rule_description => {
        pattern         => '^.*$',
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
    return $self->aggregate_rule_formula_string;
}

sub new {
    my ($class, %args) = @_;

    # Clone case
    if ($args{aggregate_rule_id}) {
        return $class->get( id => $args{aggregate_rule_id})->clone(
            dest_service_provider_id => $args{service_provider_id}
        );
    }

    my $formula = (\%args)->{aggregate_rule_formula};
    _verify ($args{aggregate_rule_formula});

    my $self = $class->SUPER::new(%args);

    my $toString = $self->toString();
    if ((! defined $args{aggregate_rule_label}) || $args{aggregate_rule_label} eq '') {
        $self->setAttr(name=>'aggregate_rule_label', value => $toString);
    }
    $self->setAttr(name=>'aggregate_rule_formula_string', value => $toString);
    $self->save();
    return $self;
}

sub setLabel{
    my ($self,%args) = @_;
    if((!defined $args{label}) || $args{label} eq ''){
        $self->setAttr(name=>'aggregate_rule_label', value => $self->toString());
    }else{
        $self->setAttr(name=>'aggregate_rule_label', value => $args{label});
    }
    $self->save();
}

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

sub toString {
    my $self = shift;

    my @array = split (/(id\d+)/, $self->aggregate_rule_formula);
    for my $element (@array) {
        if ($element =~ m/id(\d+)/) {
            $element = Entity::AggregateCondition->get ('id'=>substr($element,2))->aggregate_condition_formula_string ;
        }
    }

    return List::Util::reduce { $a . $b } @array;
}


sub eval {
    my $self = shift;

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$self->aggregate_rule_formula);

    #replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id(\d+)/) {
            $element = Entity::AggregateCondition->get ('id'=>substr($element,2))->eval();
            if( !defined $element) {
                $self->setAttr(name => 'aggregate_rule_last_eval', value=>undef);
                $self->save();
                return undef;
            }
        }
     }

    my $res = -1;
    my $arrayString = '$res = '."(@array)";

    #Evaluate the logic formula
    eval $arrayString;

    $self->setAttr(name => 'aggregate_rule_timestamp',value=>time());

    if (defined $res){
        my $store = ($res)?1:0;
        $self->setAttr(name => 'aggregate_rule_last_eval',value=>$store);
        $self->save();
        return $store;
    }

    $self->setAttr(name => 'aggregate_rule_last_eval',value=>undef);
    $self->save();
    return undef;

}


sub enable(){
    my $self = shift;
    $self->setAttr(name => 'aggregate_rule_state', value => 'enabled');
    #$self->setAttr(name => 'aggregate_rule_timestamp', value => time());
    $self->setAttr(name => 'aggregate_rule_last_eval', value => undef);
    $self->save();
}

sub disable(){
    my $self = shift;
    $self->setAttr(name => 'aggregate_rule_state', value => 'disabled');
    #$self->setAttr(name => 'aggregate_rule_timestamp', value => time());
    $self->save();
}

sub disableTemporarily(){
    my $self = shift;
    my %args = @_;
    General::checkParams args => \%args, required => ['length'];

    my $length = $args{length};

    $self->setAttr(name => 'aggregate_rule_state', value => 'disabled_temp');
    $self->setAttr(name => 'aggregate_rule_timestamp', value => time() + $length);
    $self->save();
}

sub isEnabled(){
    my $self = shift;
    #$self->updateState();
    return ($self->getAttr(name=>'aggregate_rule_state') eq 'enabled');
}

sub getRules() {
    my $class = shift;
    my %args = @_;

    my $state               = $args{'state'};
    my $service_provider_id = $args{'service_provider_id'};

    my @rules;
    if (defined $service_provider_id) {
        @rules = Entity::AggregateRule->search (hash => {'aggregate_rule_service_provider_id' => $service_provider_id});
    } else {
        @rules = Entity::AggregateRule->search (hash => {});
    }


    switch ($state){
        case "all"{
            return @rules; # All the rules
        }
        else {
            my @rep;
            foreach my $rule (@rules){
                #update state and return $rule only if state is corresponding
                #$rule->updateState();

                if($rule->getAttr(name=>'aggregate_rule_state') eq $state){
                    push @rep, $rule;
                }
            }
            return @rep;
        }
    }
}

sub updateState() {
    my $self = shift;

    if ($self->getAttr(name=>'aggregate_rule_state') eq 'disabled_temp') {
        if( $self->getAttr(name => 'aggregate_rule_timestamp') le time()) {
            $self->setAttr(name => 'aggregate_rule_timestamp', value => time());
            $self->setAttr(name => 'aggregate_rule_state'    , value => 'enabled');
            $self->save();
        }
    }
}

sub getDependentConditionIds {
    my $self = shift;
    my %ids = map { $_ => undef } ($self->aggregate_rule_formula =~ m/id(\d+)/g);
    return keys %ids;
}


sub isCombinationDependent{
    my $self         = shift;
    my $condition_id = shift;
    my @dep_cond_id = $self->getDependentConditionIds();
    my $rep = any {$_ eq $condition_id} @dep_cond_id;
    return $rep;
}

sub setAttr {
    my $class = shift;
    my %args = @_;
    if ($args{name} eq 'aggregate_rule_formula'){
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
        $attrs->{aggregate_rule_formula}    = $self->_cloneFormula(
            dest_sp_id              => $attrs->{aggregate_rule_service_provider_id},
            formula                 => $attrs->{aggregate_rule_formula},
            formula_object_class    => 'Entity::AggregateCondition'
        );
        $attrs->{aggregate_rule_last_eval}  = undef;
        $attrs->{workflow_def_id}           = undef;
        return %$attrs;
    };

    # Generic clone
    my $clone = $self->_importToRelated(
        dest_obj_id         => $args{'dest_service_provider_id'},
        relationship        => 'aggregate_rule_service_provider',
        label_attr_name     => 'aggregate_rule_label',
        attrs_clone_handler => $attrs_cloner
    );

    # Manage associated workflow
    # Clone only if both services use the same workflow manager
    if ($self->workflow_def_id) {
        eval {
            my $src_workflow_manager = ServiceProviderManager->find( hash => {
                 manager_type        => 'workflow_manager',
                 service_provider_id => $self->aggregate_rule_service_provider_id
            });
            my $dest_workflow_manager = ServiceProviderManager->find( hash => {
                manager_type        => 'workflow_manager',
                service_provider_id => $args{'dest_service_provider_id'}
            });
            if ($src_workflow_manager->manager_id == $dest_workflow_manager->manager_id) {
                my $manager = Entity->get(id => $src_workflow_manager->manager_id );
                $manager->cloneWorkflow(
                    workflow_def_id => $self->workflow_def_id,
                    rule_id         => $clone->id
                );
            }
        };
    }

    return $clone;
}

sub updateFormulaString {
    my $self = shift;
    $self->setAttr(name=>'aggregate_rule_formula_string', value => $self->toString());
    $self->save();
}

sub update {
    my ($self, %args) = @_;

    my $rep = $self->SUPER::update (%args);
    $self->updateFormulaString;
    return $rep;
}

sub delete {
    my $self = shift;
    my $workflow_def = $self->workflow_def;
    $self->SUPER::delete();
    if (defined $workflow_def) { $workflow_def->delete(); };
}

1;
