use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Test::More 'no_plan';
use Test::Deep;
use Model::MVAModel;
use MultiTuning;
use Data::Dumper;
use List::Util qw(reduce);
use warnings;
use strict;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init();
use Log::Log4perl "get_logger";
Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');
my $log = get_logger("orchestrator");


my $model = Model::MVAModel->new();
my $multituning = MultiTuning->new(model => $model);
my $thinkTime_mean;
my @monitored_workload_1_nodes;
my @monitored_workload_2_nodes ;
my @monitored_latency_1_nodes;
my @monitored_latency_2_nodes;
my @monitored_throughput_1_nodes;
my @monitored_throughput_2_nodes;
#use Controller;
#my $controller = Controller->new();
 
 { # 1 connection per users
    
    my @monitored_workload_1_nodes = qw(
    100 200 300 400 500 500 400 300 200 100 200 300 400 500 100
    );
    
    my @monitored_latency_1_nodes = qw(
    0.0044  0.0100  0.0413  0.2352  0.4229  0.4074  0.2256  0.0421  0.0139  0.0053  0.0223  0.0393  0.2105  0.4109  0.0047
    );
    
    my @monitored_throughput_1_nodes = qw(
    178.71  352.73  514.97  543 540.28  542.11  543.05  513.35  355.79  177.74  294.25  433.5   469.94  540.18  178.41
    );
    
    my @monitored_workload_2_nodes = qw(
    100 200 300 400 500 600 700 800 800 700 600 500 400 300 200 100 100 200 300 400 500 600 700 800 800 700 600 500 400 300 200 100 900 900 900 900 900 900 900 900
    
    );
    
    my @monitored_latency_2_nodes = qw(
    0.0041  0.0047  0.0061  0.0083  0.0496  0.0541  0.1829  0.2442  0.2457  0.1439  0.0764  0.0153  0.0086  0.0066  0.0146  0.0037  0.0041  0.0045  0.0058  0.0084  0.0186  0.0484  0.1890  0.2264  0.2456  0.1471  0.1157  0.0162  0.0082  0.0061  0.0045  0.0040  0.2578  0.2435  0.3074  0.2362  0.3000  0.2355  0.2600  0.2371                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    
    );
    
    my @monitored_throughput_2_nodes =qw( 
    177.8   355.51  529.51  704.95  873.12  1016    992.59  1043.09 983.21  1043.41 975.69  877.39  587.28  440.96  355.62  175.94  175.72  355.26  531.55  709.17  872.7   1015.45 982.98  1042.89 982.28  1041.34 965.5   878.2   707.89  533.45  354.01  175.4   994.18  1048.25 974.42  1046.35 981.22  1042.28 972.06  1040.53
    );  
}
 
 
# 2 connexions per users
{
    my @monitored_workload_1_nodes = qw(
    200 400 600 700 800 800 700 500 400 200 600 800
    
    );
    
    my @monitored_latency_1_nodes = qw(
    0.0049  0.0109  0.0540  0.1787  0.3525  0.3757  0.1923  0.0166  0.0086  0.0194  0.0760  0.4084
    );
    
    my @monitored_throughput_1_nodes = qw(
    170.51  355.55  512.28  539.15  541.29  541.55  535.34  440.73  351.87  174.11  513.97  536.51
    );    
    
    
    my @monitored_workload_2_nodes = qw(
    200 400 1000    1000    800 600 400 200 400 600 800 1200    1200    800 600 400 800 1000    1200    1400    1200
    );
    #
    
    my @monitored_latency_2_nodes = qw(
    0.0044  0.0048 0.0418  0.0250  0.0182  0.0063  0.0051  0.0044  0.0045  0.0072  0.0298  0.1706  0.1729  0.0094  0.0124  0.0053  0.0167  0.0283  0.1391  0.2618  0.1639
    );
    #
    my @monitored_throughput_2_nodes =qw( 
    173.88  347.65 863.17  863.8   702.43  526.81  349.13  174.54  354.26  437.06  584.53  965.93  971.93  695.59  529.28  350.11  704.03  867.9   959.09  981.33  943.57
    );
    
    my @monitored_workload_3_nodes = qw(
    100 200 600 1200 1500 1700 1900 2100
    );
    
    my @monitored_latency_3_nodes = qw(
    0.00374 0.00427 0.00478 0.01255 0.08133 0.15448 0.22692 0.32958
    );
    
    my @monitored_throughput_3_nodes = qw(
    89.74 175.07 526.33 1050.32 1260.44 1333.98 1310.32 1326.07
    );    
}

{
   my @monitored_workload_1_nodes = qw(
        53.8378330996
        31.9310559006
        25.6893939394
        58.0910353535
        90.9928703704
        122.4766226366
        154.1946596947
        187.9405735174
        220.5049276061
        253.9512468491
        287.7005378816
        319.0178015001
        352.5582792598
        386.6928985692
        419.0311038268
        449.9454153328
        483.5356377608
    );
    @monitored_workload_1_nodes = map {$_ * 2} @monitored_workload_1_nodes;
    
    my @monitored_latency_1_nodes = qw(
     0.0066700327 0.0033950311
0.0380757576
0.0330886364
0.0276912963
0.0320734473
0.0298305151
0.029702495
0.0412081806
0.0409899577
0.0447959553
0.0800862734
0.121724428
0.2285090445
0.2516844126
0.3001396514
0.4741022602
        
    );
    
    my @monitored_throughput_1_nodes = qw(
9.5569052033
40.9658781362
96.5952927121
150.0695019157
206.8013315206
262.6973831006
327.395272525
394.4214188605
457.0451736497
499.8444065422
537.5234195402
570.6320634921
592.7001033041
606.8731819305
603.1053065134
596.6667095126
    
    );    
    
    
    my @monitored_workload_2_nodes = qw(
    
    );
    #
    
    my @monitored_latency_2_nodes = qw(
    
    );
    #
    my @monitored_throughput_2_nodes =qw( 
    
    );
    
    my @monitored_workload_3_nodes = qw(
    
    );
    
    my @monitored_latency_3_nodes = qw(
    
    );
    
    my @monitored_throughput_3_nodes = qw(
    
    );    
}

#@monitored_workload_2_nodes   = ();
#@monitored_latency_2_nodes    = ();
#@monitored_throughput_2_nodes = ();
#@monitored_workload_1_nodes   = ();
#@monitored_latency_1_nodes    = ();
#@monitored_throughput_1_nodes = ();

{# Bench model
        my @monitored_workload_1_nodes   = map {$_ * 50} (1..20);
        
        my @monitored_latency_1_nodes    = (1)x20;
        
        my @monitored_throughput_1_nodes = (1)x20;
            
        my @monitored_workload_2_nodes   = map {$_ * 50} (1..52);
        
        my @monitored_latency_2_nodes    = (1)x52;
        #
        my @monitored_throughput_2_nodes = (1)x52;
        
        my @monitored_workload_3_nodes   = map {$_ * 50} (1..52);
        
        my @monitored_latency_3_nodes    = (1)x52;
        #
        my @monitored_throughput_3_nodes = (1)x52;
        
        my $thinkTime_mean = 1.13255395909864; 
        
        
        print ""
        .scalar(@monitored_latency_1_nodes)." " 
        .scalar(@monitored_latency_2_nodes)." " 
        .scalar(@monitored_throughput_1_nodes)." " 
        .scalar(@monitored_throughput_2_nodes)." "
        .scalar(@monitored_workload_1_nodes)." "
        .scalar(@monitored_workload_2_nodes)." "
        ."\n" 
        ;
        #@monitored_latency = map {$_ * 1000} @monitored_latency;
        
        my @monitored_workload   = (@monitored_workload_1_nodes  , @monitored_workload_2_nodes, @monitored_workload_3_nodes);
        my @monitored_latency    = (@monitored_latency_1_nodes   , @monitored_latency_2_nodes, @monitored_latency_3_nodes);
        my @monitored_throughput = (@monitored_throughput_1_nodes, @monitored_throughput_2_nodes, @monitored_throughput_3_nodes);
        
        my @monitored_abort_rate = (0)x(scalar(@monitored_workload));
        
        
        my @estimated_thinkTime = 
            map {$monitored_workload[$_] / $monitored_throughput[$_] - $monitored_latency[$_] } 
            (0..@monitored_workload-1);
        
        
        my $thinkTime_mean    = (reduce {$a + $b} @estimated_thinkTime)/scalar(@estimated_thinkTime);
        
        print "monitored_latency    = @monitored_latency \n";
        print "monitored throughput = @monitored_throughput \n";
        print "monitored abort rate = @monitored_abort_rate \n";
        print "monitored  estimated thk time = @estimated_thinkTime \n";
        print "think_time mean = $thinkTime_mean \n";
        
        
        #              'S' => [
        #               '0.00187110578711802',
        #               '0.00581358266058338'
        #             ],
        #      'D' => [
        #               '0',
        #               '0.0452030008900458'
        #             ] 




my @learning_data = ();
    for my $i (0..@monitored_workload-1){
        
        my $workload = {
           workload_class => {
                  visit_ratio => [1,0.13],
                  think_time => $estimated_thinkTime[$i]
                  #think_time => $thinkTime_mean
           },
           workload_amount => $monitored_workload[$i]
        };
        
        
        my $infra_conf_1_nodes = {       
            M        => 2,
            AC       => [1,1],
            LC       => [10000,10000], 
        };
        
        my $infra_conf_2_nodes = {       
            M        => 2,
            AC       => [2,1],
            LC       => [10000,10000], 
        };
    
        my $infra_conf_3_nodes = {       
            M        => 2,
            AC       => [3,1],
            LC       => [10000,10000], 
        };
        
        my $curr_perf = {
            latency    => $monitored_latency[$i],
            abort_rate => $monitored_abort_rate[$i],
            throughput => $monitored_throughput[$i],
        };
        
        my $data = {
            workload    => $workload, 
            infra_conf  => undef,
            curr_perf   => $curr_perf
        };
         
        if($i < scalar(@monitored_latency_1_nodes)) {
            $data->{infra_conf} = $infra_conf_1_nodes;
        }
        elsif ($i < scalar(@monitored_latency_1_nodes + @monitored_latency_2_nodes)) {
            $data->{infra_conf} = $infra_conf_2_nodes;
        }
        else {
            $data->{infra_conf} = $infra_conf_3_nodes;
            
        }
    
            push(@learning_data, $data);
        
    }
}

my $intern_params;
$intern_params->{S} = [0.0017,0.002];
$intern_params->{D} = [0,0.002];

my @learning_data = [
{'curr_perf' => {'throughput' => '609.15600534802','latency' => '0.581456645541085'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '858.183844134431','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '0.99'}}},
{'curr_perf' => {'throughput' => '400.81749474725','latency' => '0.038301179278452'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '426.698626146808','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '0.99'}}},
{'curr_perf' => {'throughput' => '526.18805504058','latency' => '0.0697980344630344'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '570.157263005863','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '0.99'}}},
{'curr_perf' => {'throughput' => '240.652126230791','latency' => '0.0338097945501013'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '284.534252713332','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '0.99'}}},
{'curr_perf' => {'throughput' => '609.6242289787','latency' => '0.226449882511956'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '715.421431773758','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '0.99'}}}
];

#print Dumper $intern_params;


if(1){
    
    my $algo_conf = {
        nb_steps            => 1000000,
        init_step_size      => 0.01,
        precision           => 10**(-6),
        S_init              => [0.05, 0.001],
        D_init              => [0, 0.001],
        service_time_mask   => [1,0],
        delay_mask          => [0,0],
    };
    
    $intern_params = $multituning->modelTuning( 
        algo_conf => $algo_conf,
        learning_data    => \@learning_data
    );  
    
    print Dumper $intern_params;
    

}
else {
            
#    $intern_params = {
#          'S' => [
#                   '0.00173458372126333',
#                   '0.0550878609367646'
#                 ],
#          'D' => [
#                   '0',
#                   '0.0294072333126313'
#                 ]
#        };
        
        

# only latency, no normalisation        
#              'S' => [
#               '0.00187110578711802',
#               '0.00581358266058338'
#             ],
#      'D' => [
#               '0',
#               '0.0452030008900458'
#             ] 
#score 0.0159229644875758 21659.8395607222


#$intern_params = {
#          'S' => [
#                   '0.00172477946376677',
#                   '0.0463052703092561'
#                 ],
#          'D' => [
#                   '0',
#                   '0.221421115344904'
#                 ]
#};
# 0.0319862930200289 42375.7784767992

# Apprentissage 1 noeud et 2 noeuds
#$intern_params = {
#          'S' => [
#                   '0.00185838898643851',
#                   '0.0600992360524833'
#                 ],
#          'D' => [
#                   '0',
#                   '9.31321750621827e-12'
#                 ]
#        };


 # test 1 2 3
#S = 0.00185274720191955 0.038986212015152 ; D = 0 0.227188832759858
#$intern_params = {
#          'S' => [
#            0.00185274720191955, 
#            0.038986212015152
#                 ],
#          'D' => [
#                   '0',
#                   0.227188832759858
#                 ]
#        };
#       latency * 100000+ th
#        $intern_params = {
#          'S' => [
#            0.00185442864894867, 
#            0.0411245721578598
#                 ],
#          'D' => [
#                   '0',
#                   0.157958753108978
#                 ]
#        };

 # 1 2 3 learn all
        $intern_params = {
          'S' => [
                   '0.00192292630672455',
                   '0.0398474917411804'
                 ],
          'D' => [
                   '0',
                   '0.0988064227104188'
                 ]
        };

# 1 2 3 leanr latenxy block S2
# 0.00186010956764221
# 0.00207356512546539
# 0.00227927684783935
#        $intern_params = {
#          'S' => [
#            0.00227927684783935,
#            0.001
#                 ],
#          'D' => [
#                   '0',
#                   0.001
#                 ]
#        };
}

        my @score_ref = $multituning->computeSolutionScore(
        learning_data => \@learning_data,
        S => $intern_params->{S},
        D => $intern_params->{D},
    );
    

    print "*** @score_ref\n";

#if(1){
#        my $test = $multituning -> evaluate_parameters(
#        num_benchs    => scalar(@monitored_workload),
#        workload      => $v_workload,
#        infra_conf    => $infra_conf,
#        S             => $v_workload->{workload_class}->{service_time},
#        D             => $v_workload->{workload_class}->{delay},
#        perf_to_match => $v_curr_perf,
#    );
#    
#    print "$test->{latency} / $test->{throughput}\n";
#}

if(0){

    
    #print Dumper \%verify;
    #my %QoS = $model->calculate(%verify);
    #print Dumper \%QoS;

    for my $i (0..@learning_data-1)
    {
        my %verify = (
              workload_class  => $learning_data[$i]->{workload}->{workload_class},
              configuration   => $learning_data[$i]->{infra_conf},
              workload_amount => $learning_data[$i]->{workload}->{workload_amount},
        );

        $verify{workload_class} -> {service_time} = $intern_params->{S};
        $verify{workload_class} -> {delay}        = $intern_params->{D};
        #$verify{workload_class} -> {think_time} = $thinkTime_mean;
#        $verify{workload_amount} = $v_workload->{v_workload_amount}[$i];
        #$verify{workload_class}->{think_time} =  @learning_data[$i];
        
        
        my %QoS = $model->calculate(%verify);
        if($i == 0){print "1 nodes :\n"}
        if($i == scalar(@monitored_throughput_1_nodes)){print "2 nodes :\n"}
         
        print "$verify{workload_amount} $QoS{latency} $learning_data[$i]->{curr_perf}->{latency} $QoS{throughput} $learning_data[$i]->{curr_perf}->{throughput}  @{$QoS{Ql}} @{$QoS{La}} $learning_data[$i]->{workload}->{workload_class}->{think_time}\n"
    }
    
     print "\n\n\n With think time mean \n\n\n";
     
        for my $i (0..@learning_data-1)
    {
        
        $learning_data[$i]->{workload}->{workload_class}->{think_time} = $thinkTime_mean;
        
        my %verify = (
            
              workload_class  => $learning_data[$i]->{workload}->{workload_class},
              configuration   => $learning_data[$i]->{infra_conf},
              workload_amount => $learning_data[$i]->{workload}->{workload_amount},
        );

        $verify{workload_class} -> {service_time} = $intern_params->{S};
        $verify{workload_class} -> {delay}        = $intern_params->{D};
        #$verify{workload_class} -> {think_time} = $thinkTime_mean;
#        $verify{workload_amount} = $v_workload->{v_workload_amount}[$i];
        #$verify{workload_class}->{think_time} =  @learning_data[$i];
        
        #print Dumper \%verify;
        my %QoS = $model->calculate(%verify);
        if($i == 0){print "1 nodes :\n"}
        if($i == scalar(@monitored_throughput_1_nodes)){print "2 nodes :\n"}
        if($i == scalar(@monitored_throughput_1_nodes+@monitored_throughput_2_nodes)){print "3 nodes :\n"}
        #print Dumper \%verify;
        print "$verify{workload_amount}  $QoS{latency} $learning_data[$i]->{curr_perf}->{latency} $QoS{throughput} $learning_data[$i]->{curr_perf}->{throughput}  @{$QoS{Ql}} @{$QoS{La}} $learning_data[$i]->{workload}->{workload_class}->{think_time}\n"
    }
    
     print "\n\n\n";
    my @score_ref = $multituning->computeSolutionScore(
        learning_data => \@learning_data,
        S => $intern_params->{S},
        D => $intern_params->{D},
    );
    
    print "@{$intern_params->{S}},@{$intern_params->{D}} : @score_ref\n";
    
    my @score;
    print "S evolution : \n";
    
    
    
    
    for my $i (1..5){
        my $e = 10**(-$i);
        print "+- $e\n";
        for my $k1 (-1..1){
            for my $k2 (-1..1){
                for my $k3 (-1..1){
            
            
                    
                    my @S_temp = @{$intern_params->{S}};
                    my @D_temp = @{$intern_params->{D}};
                    
                    $S_temp[0] += $e * $k1 ;
                    $S_temp[1] += $e * $k2 ;
                    $D_temp[1] += $e * $k3 ;
                    
                    if($S_temp[0] > 0 and  $S_temp[1] > 0 and  $D_temp[1] > 0 and ($k1 != 0 or $k2 != 0 or $k3 != 0)){
                    
                        my @score = $multituning->computeSolutionScore(
                        learning_data => \@learning_data,
                        S => \@S_temp,
                        D => \@D_temp,
                        );
                        
                        #print "($k1,$k2,$k3) @S_temp,@D_temp : @score ";
                        
                        #($score[0] > $score_ref[0]) ? print "+" : print "-";
                        
                        #($score[1] > $score_ref[1]) ? print "+" : print "-";
                    
                        
                      
                        if ( ($score[0] <= $score_ref[0]) and ($score[1] <= $score_ref[1]))
                        {
                            print "($k1,$k2,$k3) @S_temp,@D_temp : @score \n";
                        }
                    }
                }
            }       
        }
    }
}    

