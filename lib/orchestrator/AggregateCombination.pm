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
package AggregateCombination;

use strict;
use warnings;
use Data::Dumper;
use base 'BaseDB';
use Clustermetric;
use TimeData::RRDTimeData;
use Kanopya::Exceptions;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("orchestrator");

use constant ATTR_DEF => {
    aggregate_combination_id      =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    aggregate_combination_formula =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }


sub new {
    my $class = shift;
    my %args = @_;
    
    my $formula = (\%args)->{aggregate_combination_formula};
    
    _verify($formula);
    my $self = $class->SUPER::new(%args);
    return $self;
}

sub _verify {

    my $formula = shift;
    
    my @array = split(/(id\d+)/,$formula);

    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            if (!(Clustermetric->search(hash => {'clustermetric_id'=>substr($element,2)}))){
             my $errmsg = "Creating combination formula with an unknown clusterMetric id ($element) ";
             $log->error($errmsg);
             throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }
        }
    }
}


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    #my $aggregate_combination_id       = $self->getAttr(name => 'aggregate_combination_id');
    #my $aggregate_combination_formula  = $self->getAttr(name => 'aggregate_combination_formula');

    my $formula = $self->getAttr(name => 'aggregate_combination_formula');
    
    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            $element = Clustermetric->get('id'=>substr($element,2))->toString();
        }
    }
    return "@array";
}

sub computeValues{
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => ['start_time','stop_time'];
    
    my @cm_ids = $self->dependantClusterMetrics();
    my %allTheCMValues;
    foreach my $cm_id (@cm_ids){
        my $cm = Clustermetric->get('id' => $cm_id);
        $allTheCMValues{$cm_id} = $cm -> getValuesFromDB(%args);
    }
    return computeFromArrays(%allTheCMValues);
}

sub computeLastValue{
    my $self = shift;
    
    my $formula = $self->getAttr(name => 'aggregate_combination_formula');
    
    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            $element = Clustermetric->get('id'=>substr($element,2))->getLastValueFromDB();
        }
     }
     
    my $res = -1;
    my $arrayString = '$res = '."@array"; 
    
    
    #Evaluate the logic formula
    #print 'Evaluate combination :'.($self->toString())."\n";
    #$log->info('Evaluate combination :'.($self->toString()));
    eval $arrayString;
    print "$arrayString = ";
    $log->info("$arrayString");
    return $res;
}

sub compute{
    my $self = shift;
    my %args = @_;
 
    my @requiredArgs = $self->dependantClusterMetrics();
    
    checkMissingParams(args => \%args, required => \@requiredArgs);
    
    foreach my $cm_id (@requiredArgs){
        if( ! defined $args{$cm_id}){
            return undef;
        }
    }
    
    my $formula = $self->getAttr(name => 'aggregate_combination_formula');
    
    print Dumper \%args;
    
    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            $element = $args{substr($element,2)};
        }
     }
     
    my $res = -1;
    my $arrayString = '$res = '."@array"; 
    
    #Evaluate the logic formula
    #print 'Evaluate combination :'.($self->toString())."\n";
    #$log->info('Evaluate combination :'.($self->toString()));
    eval $arrayString;
    print "$arrayString = $res\n";
    $log->info("$arrayString");
    return $res;
}

sub dependantClusterMetrics() {
    my $self = shift;
    my $formula = $self->getAttr(name => 'aggregate_combination_formula');
    
    my @clusterMetricsList;
    
    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            push @clusterMetricsList, substr($element,2);
        }
     }
     return @clusterMetricsList;
}

# Remove duplicate from an array, return array without doublons 
sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}

sub computeFromArrays{
    my $self = shift;
    my %args = @_;
    
    print Dumper \%args;
    
    my @requiredArgs = $self->dependantClusterMetrics();
    
#    print "******* @requiredArgs \n";
#    print Dumper \%args;
    
    General::checkParams args => \%args, required => \@requiredArgs;
    
    #Merge all the timestamps keys in one arrays
    
    my @timestamps;
    foreach my $cm_id (@requiredArgs){
       @timestamps = (@timestamps, (keys %{$args{$cm_id}}));
    }
    @timestamps = uniq @timestamps;
    
    print " @timestamps \n";
    my %rep;
    foreach my $timestamp (@timestamps){
        my %valuesForATimeStamp;
        foreach my $cm_id (@requiredArgs){
            $valuesForATimeStamp{$cm_id} = $args{$cm_id}->{$timestamp};
        }
        print Dumper \%valuesForATimeStamp;
        $rep{$timestamp} = $self->compute(%valuesForATimeStamp);
    }
    print Dumper \%rep;
} 

sub checkMissingParams {
    my %args = @_;
    
    my $caller_args = $args{args};
    my $required = $args{required};
    my $caller_sub_name = (caller(1))[3];
        
    for my $param (@$required) {
        if (! exists $caller_args->{$param} ) {
            my $errmsg = "$caller_sub_name needs a '$param' named argument!";
            
            # Log in general logger
            # TODO log in the logger corresponding to caller package;
            $log->error($errmsg);
            print "$caller_sub_name : $errmsg \n";
            throw Kanopya::Exception::Internal::IncorrectParam();
        }
    }
}
1;
