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
package NodemetricCombination;

use strict;
use warnings;
use base 'BaseDB';
use Indicator;
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    nodemetric_combination_id      =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    nodemetric_combination_label     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_combination_service_provider_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_combination_formula =>  {pattern       => '^((id\d+)|[ .+*()-/]|\d)+$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1,
                                 description    => "Construct a formula by indicator's names with all mathematical operators. It's possible to use parenthesis with spaces between each element of the formula."},
};

sub getAttrDef { return ATTR_DEF; }

sub getAttr {
    my $self = shift;
    my %args = @_;

    if ($args{name} eq "unit") {
        return $self->getUnit();
    }
    else {
        return $self->SUPER::getAttr(%args);
    }
}

sub methods {
    return {
        'toString'  => {
            'description' => 'toString',
            'perm_holder' => 'entity'
        },
        'getUnit'   => {
            'description' => 'getUnit',
            'perm_holder' => 'entity',  
        },
    }
}


sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);

    if(!defined $args{nodemetric_combination_label} || $args{nodemetric_combination_label} eq ''){
        $self->setAttr(name=>'nodemetric_combination_label', value => $self->toString());
        $self->save();
    }

    # Ask the collector manager to collect the related indicator
    my $service_provider = $self->nodemetric_combination_service_provider;
    my $collector = $service_provider->getManager(manager_type => "collector_manager");
    my $indicator_id = (split('id', $self->nodemetric_combination_formula))[1];
    $collector->collectIndicator(indicator_id        => $indicator_id,
                                 service_provider_id => $service_provider->getId);

    return $self;
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my ($self, %args) = @_;
    my $depth;
    if(defined $args{depth}) {
        $depth = $args{depth};
    }
    else {
        $depth = -1;
    }
    if($depth == 0) {
        return $self->getAttr(name => 'nodemetric_combination_label');
    }
    else{
        my $formula             = $self->getAttr(name => 'nodemetric_combination_formula');
        my $service_provider_id = $self->getAttr(name => 'nodemetric_combination_service_provider_id');
        my $service_provider    = Entity::ServiceProvider->get(id => $service_provider_id);
        my $collector           = $service_provider->getManager(manager_type => "collector_manager");

        #Split aggregate_rule id from $formula
        my @array = split(/(id\d+)/,$formula);
        #replace each rule id by its evaluation
        for my $element (@array) {
            if( $element =~ m/id\d+/)
            {
                #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
                $element = $collector->getIndicator(id => substr($element,2))->toString();
            }
        }
        return join('',@array);
    }
}

# C/P of homonym method of AggregateCombination
sub getDependantIndicatorIds{
    my $self = shift;
    my $formula = $self->getAttr(name => 'nodemetric_combination_formula');

    my @indicator_ids;

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);

    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            push @indicator_ids, substr($element,2);
        }
     }
     return @indicator_ids;
}

=head2 computeValueFromMonitoredValues

    desc: Compute Node Combination Value with the formula from given Indicator values

=cut

sub computeValueFromMonitoredValues {
    my $self = shift;
    my %args = @_;

    my $monitored_values_for_one_node = $args{monitored_values_for_one_node};
    my $service_provider_id = $self->getAttr(name => 'nodemetric_combination_service_provider_id');

    my $service_provider = Entity::ServiceProvider->get(id => $service_provider_id);
    my $collector = $service_provider->getManager(manager_type => "collector_manager");

    my $formula = $self->getAttr(name => 'nodemetric_combination_formula');

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);

    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            my $indicator_id  = substr($element,2);
            my $indicator_oid = $collector->getIndicator(id => $indicator_id)->indicator_oid;

            # Replace $element by its value
            $element          = $monitored_values_for_one_node->{$indicator_oid};

            if(not defined $element){
                return undef;
            }
        }
     }

    my $res = -1;
    my $arrayString = '$res = '."@array";
    #print $arrayString."\n";

    #Evaluate the logic formula
    eval $arrayString;

    $log->info("NM Combination value = $arrayString");
    return $res;
}

sub checkFormula {
    my ($class, %args) = @_;

    my $formula             = $args{formula};
    my $service_provider_id = $args{service_provider_id};

    my $service_provider  = Entity::ServiceProvider->get(id => $service_provider_id);
    my $collector_manager = $service_provider->getManager(manager_type => 'collector_manager');
    my $indicators = $collector_manager->getIndicators();

    # Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/, $formula);

    my @unkownIds;
    #replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            # Check if element is a SCOM indicator
            my $indicator_id = substr($element, 2);
            if (not (grep {$_->getId eq $indicator_id} @$indicators)) {
                push @unkownIds, $indicator_id;
            }
        }
    }

    return @unkownIds;
}

=head2 getUnit

    desc: Return the formula of the combination in which the indicator id is
          replaced by its Unit or by '?' when unit is not specified in database

=cut

sub getUnit {
    my ($self, %args) = @_;

    my $formula             = $self->getAttr(name => 'nodemetric_combination_formula');
    my $service_provider_id = $self->getAttr(name => 'nodemetric_combination_service_provider_id');
    my $service_provider    = Entity::ServiceProvider->get(id => $service_provider_id);
    my $collector           = $service_provider->getManager(manager_type => "collector_manager");

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    my $ref_element;
    my $are_same_units = 0;
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            $element = $collector->getIndicator(id => substr($element,2))->getAttr(name => 'indicator_unit') || '?';
            if (not defined $ref_element) {
                $ref_element = $element;
            } else {
                if ($ref_element eq $element) {
                    $are_same_units = 1;
                } else {
                    $are_same_units = 0;
                }
            }
        }
    }
    if ($are_same_units == 1) {
        @array = $ref_element;
    }
    return join('',@array);
}


1;
