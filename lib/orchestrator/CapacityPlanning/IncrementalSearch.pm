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
package CapacityPlanning::IncrementalSearch;

use Log::Log4perl "get_logger";
use base "CapacityPlanning";
use Data::Dumper;
use strict;
use warnings;

my $log = get_logger("orchestrator");

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new( %args );
    return $self;
}

sub search {
    
    my $self = shift;
    my %args = @_;

    # No needs to check args, done by parent
    
    my $nb_tiers = $self->{_nb_tiers};    
    my $workload_amount = $args{workload_amount};
    my %workload_class = %{ $args{workload_class} };
    #print Dumper \%workload_class;
    
    my @min_node = map { $_->{min_node} || 1 } @{ $self->{_search_spaces} };
    my @max_node = map { $_->{max_node} || 1 } @{ $self->{_search_spaces} };
            
            
    # new conf
    my @AC     = ();
    my @LC     = ();
    for (0..$nb_tiers-1) {
        push @AC, $min_node[$_];
        
        my $max_mpl = $self->{_search_spaces}[$_]{max_mpl};
        if (not defined $max_mpl) {
            $log->warn("No 'max_mpl' defined in search space");
            $max_mpl = 0;    
        }
        push @LC, $max_mpl;
    }
    #
    
    my %perf;
    my @next_AC = @AC;
    my @curr_AC;
    my $try_count = 0;
    my $max_try = 1000; #Wonder wether this is usefull ? 

    my $error = 0; 
    my $new_conf = 1;
    
    
    TRY:
    while ($try_count == 0 || not $self->matchConstraints( perf => \%perf )) {
        
        if (($try_count++ > $max_try)) {
            $log->warn("Can not find configuration to meet constraints after $max_try iterations (max)");
            print("[DEBUG] Can not find configuration to meet constraints after $max_try iterations (max)\n");
            return { AC => \@curr_AC, LC => \@LC };;
            
            # /!\ IMPROVABLE WHEN ONLY 1 TIER IS BOTTLENECK
#            for my $i (0..$nb_tiers-1){
#                $curr_AC[$i] = -1;
#            }
#            return { AC => \@curr_AC, LC => \@LC };
#            last TRY;
        }
        if (not $new_conf) {
            $log->warn("Can not find configuration to meet constraints: max node reached [" . join(',', @max_node) . "]");
            print("[DEBUG] Can not find configuration to meet constraints: max node reached [" . join(',', @max_node) . "]\n");
            return { AC => \@curr_AC, LC => \@LC };;
            # /!\ IMPROVABLE WHEN ONLY 1 TIER IS BOTTLENECK
#            for my $i (0..$nb_tiers-1){
#                $curr_AC[$i] = -1;
#            }
#            return { AC => \@curr_AC, LC => \@LC };
#            last TRY;
        }
       
        @curr_AC = @next_AC;
        #print "AC: @curr_AC  #  LC: @LC\n";
        #print Dumper \%workload_class;
        
        %perf = $self->{_model}->calculate( configuration => { M => $nb_tiers, AC => \@curr_AC, LC => \@LC},
                                             workload_class => \%workload_class,
                                             workload_amount => $workload_amount);
        
        # Add one node on each tiers if possible
        $new_conf = 0;
        for my $i (0..$nb_tiers-1) {
            if ($curr_AC[$i] < $max_node[$i]) {
                $next_AC[$i] += 1;
                $new_conf = 1;
            }
        }
        #@next_AC = map { $_ + 1 } @curr_AC;
        #print "@curr_AC : latency = $perf{latency} abort_rate = $perf{abort_rate} \n";
        
    };  #END WHILE
    
    #print "##### CURR ####\n";
    #print Dumper \@curr_AC;
    
    for my $i (0..$nb_tiers-1) {
        my $first_try = 1;
        #print "######### AC: @curr_AC\n";
        TRY:
        while ($first_try || $self->matchConstraints( perf => \%perf )){
            $curr_AC[$i] -= 1;
            #print "AC: @curr_AC\n";
            last TRY if ($curr_AC[$i] < $min_node[$i] ); 
            %perf = $self->{_model}->calculate( configuration => { M => $nb_tiers, AC => \@curr_AC, LC => \@LC},
                                                 workload_class => \%workload_class,
                                                 workload_amount => $workload_amount);
            $first_try = 0;
        };
        $curr_AC[$i] += 1;
    }
    
#    print "##### BEST ####\n";
#    print Dumper \@curr_AC;
    $log->debug(Dumper \@curr_AC);
    return { AC => \@curr_AC, LC => \@LC };
}

1;