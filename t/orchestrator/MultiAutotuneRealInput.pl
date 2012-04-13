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


my @learning_data = (

{'curr_perf' => {'throughput' => '600.402965352449','latency' => '0.427079001923229'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '896.656686004113','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '530.512375066947','latency' => '0.0770162260588077'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '584.768663992272','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '410.430298850575','latency' => '0.023785835681893'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '454.342114705083','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '583.06093404194','latency' => '0.165428596887797'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '705.629962692874','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '601.163999093643','latency' => '0.295837346941536'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '833.019548698116','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '480.721278869526','latency' => '0.0500276976229671'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '519.691515617955','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '596.241425122564','latency' => '0.264811631262176'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '769.602658972076','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '566.598957854406','latency' => '0.0895600484848485'},'infra_conf' => {'AC' => ['1',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '644.261727718475','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '580.418964610884','latency' => '0.58234048941799'},'infra_conf' => {'AC' => ['2',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '1023.04815661376','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '1156.62049553001','latency' => '0.187705165031311'},'infra_conf' => {'AC' => ['2',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '1529.82332894579','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '797.661706257982','latency' => '0.0387862671633071'},'infra_conf' => {'AC' => ['2',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '1090.27061244522','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '1004.27404062126','latency' => '0.104632110315945'},'infra_conf' => {'AC' => ['2',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '1275.5579772391','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}},{'curr_perf' => {'throughput' => '1092.2413467639','latency' => '0.129604421330658'},'infra_conf' => {'AC' => ['2',1],'LC' => [10000,10000],'M' => 2},'workload' => {'workload_amount' => '1404.00887922114','workload_class' => {'visit_ratio' => [1,'0.13'],'think_time' => '1.1'}}}
);


    
    my $algo_conf = {
        nb_steps            => 1000000,
        init_step_size      => 0.1,
        precision           => 10**(-8),
        authorized_deviation => 10, 
        S_init              => [0.0.00170133283734321, 0.00],
        D_init              => [0, 1],
        service_time_mask   => [1,0],
        delay_mask          => [0,1],
    };
    
    my $intern_params = $multituning->modelTuning( 
        algo_conf => $algo_conf,
        learning_data    => \@learning_data
    );  
    
    print Dumper $intern_params;
  