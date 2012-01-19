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
package MultiTuning;

use strict;
use warnings;
use Data::Dumper;


sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {};
    bless $self, $class;
    
    $self->{_model} = $args{model};
    
    return $self;
}

=head2 modelTuning

    Desc : compute model internal parmaters (Si, Di) according to simulated output and measured output
    
    Args :

    Return :
    
=cut

sub modelTuning {
    
    my $self = shift;
    my %args = @_;
    
    my $algo_conf           = $args{algo_conf};
    my $learning_data       = $args{learning_data};
    my $STEP_PRECISION      = $algo_conf->{precision}; #10**(-6)
    my $NB_STEPS            = $algo_conf->{nb_steps}; #15;
    my $INIT_STEP_SIZE      = $algo_conf->{init_step_size}; #5;
    my $service_time_mask   = $algo_conf->{service_time_mask};
    my $delay_mask          = $algo_conf->{delay_mask};
    my @best_S              = @{$algo_conf->{S_init}};
    my @best_D              = @{$algo_conf->{D_init}};
    $best_D[0]              = 0.;   
    
    my @monitored_latencies   = map {$_->{curr_perf}->{latency}} @$learning_data;
    my @monitored_throughputs = map {$_->{curr_perf}->{throughput}} @$learning_data;
    
    my $M                   = @$learning_data[0]->{infra_conf}->{M};
    

    my $best_gain           = -10000;
    my $dim_best_gain       = 0;
    my $evo_best_gain       = 0;
    
    my $evo_step            = $INIT_STEP_SIZE;

    my $num_benchs          = scalar(@$learning_data);
    my $continue            = 1;
    my @gain_historique     = (0)x4;
    
    
    #for my $step (0..($NB_STEPS-1)) {
      my $step = 0;
      while($continue && $step < $NB_STEPS){
        #print "Step $step, evo = $evo_step\n";
        $best_gain = -100_000_000;
        $best_gain = 0;
        $dim_best_gain = 0;
        $evo_best_gain = 0;
        my $deviation_best;
        my $deviation_curr;
        my $cumulated_best_results;

        my @S_rand= (0)x$M; 
        my @D_rand=(0)x$M;
        
        my @S_start = @best_S;
        my @D_start = @best_D;
        
        my $temp;
         #Add noise
#        for my $S_index (0..$M-1){
#            $temp = 2*(rand() - 0.5) * $evo_step;
#            
#            if($S_start[$S_index] + $temp >0){
#                $S_rand[$S_index] = $temp;
#                $S_start[$S_index] += $temp;
#            }
#             
#        }  
#        for my $D_index (1..$M-1){
#            $temp = 2*(rand() - 0.5) * $evo_step;
#            
#            if($D_start[$D_index] + $temp >0){
#                $D_rand[$D_index] = $temp;
#                $D_start[$D_index] += $temp;
#            }
#             
#        }
        

        #print "Step $step\n";
        # For each space dimension (internal parameters except D1)
        for my $dim (0..(2*$M-1-1)) { # -1 for D1 and -1 because we start at 0
            # print " Dim $dim\n";
            # Evolution direction for this dimension
            

            
            EVO:
            for (my $evo = -$evo_step; $evo <= $evo_step; $evo += 2*$evo_step ) {
            #for (my $evo = -$evo_step; $evo <= $evo_step; $evo += 2*$evo_step ) {
                
#                my @S = @best_S;
#                my @D = @best_D;

                my @S = @S_start;
                my @D = @D_start;

                
                #print "@S @D \n";
                #print "$M stm $dim = $service_time_mask->[$dim] ; dt = $delay_mask->[$dim - $M + 1] \n";
                
                if ($dim < $M) { #S proceeding when dim in (0..$M-1) ($M values)
                    if (($service_time_mask->[$dim]) > 0){
                        $S[$dim] += $evo;
                        
                        if ($S[$dim] <= 0){ # Prevent null or negative Si
                            #print "dim $dim evo $evo negative S\n";
                            next EVO;
                        }
                        if($S[$dim] < (1-$algo_conf->{authorized_deviation} ) * $algo_conf->{S_init}->[$dim])
                        {
                           next EVO; 
                        }
                        if($S[$dim] > (1+$algo_conf->{authorized_deviation} ) *  $algo_conf->{S_init}->[$dim])
                        {
                           next EVO; 
                        }
                    } else {
                        #print "sorry mask !\n";
                    }
                  
                } else {       #D proceeding when dim in ($M 2*$M-2) ($M - 1 values)
                    if($delay_mask->[$dim - $M + 1] > 0){
                        $D[$dim - $M + 1] += $evo;
                        if ($D[$dim - $M + 1] < 0){ # Null delay allowed
                           # print "dim $dim evo $evo negative D\n";
                            next EVO;
                        }
                    }
                }
                

                
                #print "evo = $evo ; [@S] ; [@best_S] ; [@D] ; [@best_D]\n";

                my $cumulated_evo_results = {
                    latencies  => [],
                    throughputs => [],
                    abort_rates => [],
                };
                
                $cumulated_best_results = {
                    latencies  => [],
                    throughputs => [],
                    abort_rates => [],
                };
                

                for my $i (0..$num_benchs-1) { 

                    my $infra_conf = @$learning_data[$i] -> {infra_conf};
                    my $workload   = @$learning_data[$i] ->{workload};
                    my $curr_perf  = @$learning_data[$i] ->{curr_perf};
                    
                    my %model_params = (
                            configuration => $infra_conf,
                            workload_amount => $workload->{workload_amount},
                            workload_class => {
                                                visit_ratio => $workload->{workload_class}{visit_ratio},
                                                think_time  => $workload->{workload_class}{think_time},
                                                service_time => \@S,
                                                delay => \@D,
                                               }
                    );
                    
                    
#                    print "Model_params \n";
#                    print Dumper \%model_params;
                    
                    
                    my %new_out = $self->{_model}->calculate( %model_params );
                    $cumulated_evo_results->{latencies}[$i]   = $new_out{latency};
                    $cumulated_evo_results->{throughputs}[$i] = $new_out{throughput};
                    $cumulated_evo_results->{abort_rates}[$i] = $new_out{abort_rate};
                    
                    
                
                    #print "## NEW out ##\n";
                    #print Dumper \%new_out;
                    
                    
                    
                    $model_params{workload_class}{service_time} = \@best_S;
                    $model_params{workload_class}{delay}        = \@best_D;
                    
                    # TODO optimize algo by keeping best output
                    
                    #print Dumper \%model_params;
                    my %best_out = $self->{_model}->calculate( %model_params );
                    $cumulated_best_results->{latencies}[$i]   = $best_out{latency};
                    $cumulated_best_results->{throughputs}[$i] = $best_out{throughput};
                    $cumulated_best_results->{abort_rates}[$i] = $best_out{abort_rate};

                     
                    #print "## BEST out ##\n";
                    #print Dumper \%best_out;
                    

#                    $deviation_best = $self->_computeDiffMulti(
#                                    model_output => \%best_out, 
#                                    monitored_perf => 
#                                    {
#                                        latency    => $v_curr_perf->{latency}[$i],
#                                        abort_rate => $v_curr_perf->{abort_rate}[$i],
#                                        throughput => $v_curr_perf->{throughput}[$i],
#                                    }
#                    );
#                    
#                    $deviation_curr = $self->_computeDiffMulti( 
#                                    model_output => \%new_out, 
#                                    monitored_perf =>
#                                    {
#                                        latency    => $v_curr_perf->{latency}[$i],
#                                        abort_rate => $v_curr_perf->{abort_rate}[$i],
#                                        throughput => $v_curr_perf->{throughput}[$i],
#                                    }
#                    );
                    
                    
                    #$curr_per_sum{latency}    += $v_curr_perf->{latency}[$i];
                    #$curr_per_sum{abort_rate} += $v_curr_perf->{abort_rate}[$i];
                    #$curr_per_sum{throughput} += $v_curr_perf->{throughput}[$i];

                      
                    #$total_curr_dev{latency}    += $deviation_curr->{latency};
                    #$total_curr_dev{abort_rate} += $deviation_curr->{abort_rate};
                    #$total_curr_dev{throughput} += $deviation_curr->{throughput};
                    
                    #$total_best_dev{latency}    += $deviation_best->{latency};
                    #$total_best_dev{abort_rate} += $deviation_best->{abort_rate};
                    #$total_best_dev{throughput} += $deviation_best->{throughput};
                    
                     #print "lat $i $deviation_curr->{latency}\n";
                   # print "   $i : latency $new_out{latency} ($v_curr_perf->{latency}[$i]) gain = $gain\n";
                    
                   # $gain_total += $gain;
                   # print "bench $i : DBest = $pDBest ; pDNew = $pDNew ; gain = $gain ; best_gain = $best_gain\n";
                }
                
                #print Dumper $cumulated_best_results;
                #print Dumper $cumulated_evo_results;
                
                
                
                 
                my $latency_evo_diff =_array_square_sum (
                   \@monitored_latencies, 
                    $cumulated_evo_results->{latencies}
                );
                
          
                my $throughput_evo_diff =_array_square_sum (
                   \@monitored_throughputs,
                    $cumulated_evo_results->{throughputs}
                );
          
                my $latency_best_diff =_array_square_sum (
                   \@monitored_latencies, 
                   $cumulated_best_results->{latencies}
                );
                
                my $throughput_best_diff =_array_square_sum (
                    \@monitored_throughputs,
                    $cumulated_best_results->{throughputs}
                );
                
                #print "@{$v_curr_perf->{throughput}}\n";
                #print "best_diff = $throughput_best_diff  @{$cumulated_best_results->{throughputs}}\n";
                #print "evo_diff = $throughput_evo_diff @{$cumulated_evo_results->{throughputs}}\n";
                
                
                my $latency_gain    = $latency_best_diff - $latency_evo_diff;
                my $throughput_gain = $throughput_best_diff - $throughput_evo_diff;
                
                #my $total_gain = $latency_gain *100000+ $throughput_gain;
                my $total_gain = $latency_gain;
                #print("".($throughput_gain/$latency_gain)."\n.");
                
                
                #print "dim $dim evo $evo : S = @S D = @D| total_gain = $total_gain \n";
                
                
                #print "ff @{$cumulated_evo_results->{latencies}} @{$v_curr_perf->{latency}} $latency_evo_diff";
                
                                #$total_dev{latency}    /= $curr_per_sum{latency};
                #$total_dev{abort_rate} /= $curr_per_sum{abort_rate};
                #$total_dev{throughput} /= $curr_per_sum{throughput};
#                my $diff_lat = - $total_curr_dev{latency}    + $total_best_dev{latency};
#                my $diff_ar  = - $total_curr_dev{abort_rate} + $total_best_dev{abort_rate};
##                my $diff_tp  = - $total_curr_dev{throughput} + $total_best_dev{throughput};
#                $diff_tp  = 0;
#                
#                my $gain_total = $diff_lat + $diff_ar + $diff_tp;
                
                #print "total $total_curr_dev{latency}\n";
                
                #print "Evo : $evo ; Dim : $dim ; (@S,@D) ; Gain Total : $total_gain (best $best_gain) : $latency_evo_diff vs $latency_best_diff et $throughput_evo_diff vs $throughput_best_diff \n";
                 
                #print "pDBest = $pDBest ; pDNew = $pDNew ; gain = $gain ; best_gain = $best_gain\n";
                
                #if ($gain > $best_gain) {

                if ($total_gain > $best_gain) {
                    $best_gain      = $total_gain;
                    $dim_best_gain  = $dim;
                    $evo_best_gain  = $evo;
                }
            } # end evo
        } #end dim
        
        if($best_gain >0)
        {
            print "$step *** BEST GAIN $best_gain *** S = @best_S ; D = @best_D : estep = $evo_step \n";
           # print Dumper $cumulated_best_results;
        
            if ($dim_best_gain < $M) {
                if (($service_time_mask->[$dim_best_gain]) > 0){
                    $best_S[$dim_best_gain] += $evo_best_gain;
                }
            } else {
                 if (($delay_mask->[$dim_best_gain - $M + 1]) > 0){
                    $best_D[$dim_best_gain - $M + 1] += $evo_best_gain;
                 }
            }
            
            #Add noise
            for my $S_index (0..$M-1){
                $best_S[$S_index] += $S_rand[$S_index];
            }  
            for my $D_index (1..$M-1){
                $best_D[$D_index] += $D_rand[$D_index];
            }
        }
        # Avoid oscillations around optimal
        if($evo_step < $STEP_PRECISION / 10){
            $continue = 0;
            print "required precision reached !\n"; 
        }
        if ($best_gain <= 0) {
            $evo_step /= 2;
        }
        
        #Store x last evo_step in order to increase evo_step when still
        #the same during x steps
        
        unshift(@gain_historique,$evo_step);
        pop @gain_historique;
        
        # Check if all the values are equals
        #TODO this algo can be done with 1 var and 1 counter 
        
        my $ok = 1;
        my $i = 1;
        while ($ok && $i<scalar(@gain_historique))
        {
           if($gain_historique[$i] != $gain_historique[0])
           {
               $ok = 0; 
           }
           $i++;
        }
        
        if($ok == 1) {
            $evo_step *= 2;
            unshift(@gain_historique,$evo_step);
            pop @gain_historique;
        }
        $step++;
    } # end step
    
    
 
    my @score = $self->computeSolutionScore(
        learning_data => $learning_data,
        S             => \@best_S,
        D             => \@best_D,
    );
    print "score = @score\n";
    
    return { D => \@best_D, S => \@best_S };
}

sub _computeDiff {
    my $self = shift;
    my %args = @_;
    
    my $curr_perf = $args{monitored_perf};
    my $model_perf = $args{model_output};
    
    # weight of each parameters
    my %weights = ( latency => 1, abort_rate => 1, throughput => 1);

    my %deviations  = ( latency => 0, abort_rate => 0, throughput => 0);
    
    my $weight = 0;
    for my $metric ('latency', 'abort_rate', 'throughput') {
        if ($curr_perf->{$metric} > 0) {
            $deviations{$metric} = abs( $model_perf->{$metric} - $curr_perf->{$metric} ) * 100 / $curr_perf->{$metric}; 
            $weight += $weights{$metric};
        }
    }
    
    # Here MOKA process a sqrt(pow(dev,2)). Seems useless.
    
    my $dev = 0;
    for my $metric ('latency', 'abort_rate', 'throughput') {
        $dev += $deviations{$metric} * $weights{$metric}; 
    }
    $dev /= $weight if ($weight > 0);
    
    #$log->debug("* Deviation * " . (Dumper \%deviations));
    #$log->debug("==> $dev");
    
    return $dev;
}

sub computeSolutionScore {
    my $self = shift;
    my %args = @_;

    my $learning_data = $args{learning_data};
    my $S = $args{S};
    my $D = $args{D};
    my @monitored_latencies   = map {$_->{curr_perf}->{latency}} @$learning_data;
    my @monitored_throughputs = map {$_->{curr_perf}->{throughput}} @$learning_data;    
   my $cumulated_best_results = {
        latencies  => [],
        throughputs => [],
        abort_rates => [],
    };

    my $num_benchs = scalar(@$learning_data);
    
    for my $i (0..$num_benchs-1) { 
        my $infra_conf = @$learning_data[$i] -> {infra_conf};
        my $workload   = @$learning_data[$i] ->{workload};
        my $curr_perf  = @$learning_data[$i] ->{curr_perf};
        
        my %model_params = (
                configuration => $infra_conf,
                workload_amount => $workload->{workload_amount},
                workload_class => {
                                    visit_ratio => $workload->{workload_class}{visit_ratio},
                                    think_time  => $workload->{workload_class}{think_time},
                                    service_time => $S,
                                    delay => $D,
                                   }
        );
        my %best_out = $self->{_model}->calculate( %model_params );
        $cumulated_best_results->{latencies}[$i]   = $best_out{latency};
        $cumulated_best_results->{throughputs}[$i] = $best_out{throughput};
        $cumulated_best_results->{abort_rates}[$i] = $best_out{abort_rate};
    }
    
    my $latency_best_diff =_array_square_sum (
       \@monitored_latencies, 
       $cumulated_best_results->{latencies}
    );
    

    
    my $throughput_best_diff =_array_square_sum (
        \@monitored_throughputs,
        $cumulated_best_results->{throughputs}
    );
    
    return ($latency_best_diff, $throughput_best_diff);
}

sub _computeDiffMulti {
    my $self = shift;
    my %args = @_;
    
    my $curr_perf = $args{monitored_perf};
    my $model_perf = $args{model_output};
    
    # weight of each parameters
    my %weights = ( latency => 1, abort_rate => 1, throughput => 1);

    my %deviations  = ( latency => 0, abort_rate => 0, throughput => 0);
    
    my $weight = 0;
    for my $metric ('latency', 'abort_rate', 'throughput') {
#        if ($curr_perf->{$metric} > 0) {
#            $deviations{$metric} = abs( $model_perf->{$metric} - $curr_perf->{$metric} ) * 100 / $curr_perf->{$metric}; 
#            $weight += $weights{$metric};
#        }
        $deviations{$metric} = abs( $model_perf->{$metric} - $curr_perf->{$metric})**2;
    }
    
    return \%deviations;
    # Here MOKA process a sqrt(pow(dev,2)). Seems useless.
    
    my $dev = 0;
    for my $metric ('latency', 'abort_rate', 'throughput') {
        $dev += $deviations{$metric} * $weights{$metric}; 
    }
    $dev /= $weight if ($weight > 0);
    
    #$log->debug("* Deviation * " . (Dumper \%deviations));
    #$log->debug("==> $dev");
    
    return $dev;
}


sub evaluate_parameters{
    my $self = shift;
    my %args = @_;
    
    my $num_benchs          = $args{num_benchs};
    my $workload            = $args{workload};
    my $infra_conf          = $args{infra_conf};
    my $S                   = $args{S};
    my $D                   = $args{D};
    my $perf_to_match       = $args{perf_to_match};
    
    
    #Evaluate final solution
    my $cumulated_evo_results;
    for my $i (0..$num_benchs-1) { 
                    
                    my %model_params = (
                            configuration => $infra_conf,
                            workload_amount => $workload->{v_workload_amount}[$i],
                            workload_class => {
                                                visit_ratio => $workload->{workload_class}{visit_ratio},
                                                think_time  => $workload->{workload_class}{v_think_time}[$i],
                                                service_time => $S,
                                                delay => $D,
                                               }
                    );
                    #print "Model_params \n";
                    #print Dumper \%model_params;
                    
                    my %new_out = $self->{_model}->calculate( %model_params );
                    
                    $cumulated_evo_results->{latencies}[$i]   = $new_out{latency};
                    $cumulated_evo_results->{throughputs}[$i] = $new_out{throughput};
                    $cumulated_evo_results->{abort_rates}[$i] = $new_out{abort_rate};
    }  
                   
                    my $latency_evo_diff =_array_square_sum (
                    $perf_to_match->{latency}, 
                    $cumulated_evo_results->{latencies}
                );
                
                my $throughput_evo_diff =_array_square_sum (
                    $perf_to_match->{throughput}, 
                    $cumulated_evo_results->{throughputs}
                );
                
    my $scores;
    $scores->{latency} = $latency_evo_diff;
    $scores->{throughput} = $throughput_evo_diff;
    return $scores;
}

sub _array_square_sum {
    
    my ($tab1,$tab2)= @_ ;    
    my $n = scalar(@$tab1);
        
    my $sum = 0; 
    for my $i (0..$n-1) {
        #$sum += (($tab1->[$i] - $tab2->[$i])/$tab1->[$i])**2;
        $sum += (($tab1->[$i] - $tab2->[$i]))**2;
    }
    return $sum;
}
1;