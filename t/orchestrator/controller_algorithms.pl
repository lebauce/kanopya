use Model::MVAModel;
use CapacityPlanning::IncrementalSearch;
use Controller;
use Data::Dumper;

use warnings;
use strict;

my $workload_amount    = 1000;


# We fake monitored metrics on a "virtual" system 
my $monitored_metrics = {
      latency    => 0.01,
      abort_rate => 0.80,
      throughput => 40000,
};    
    
my $max_latency     = 0.1; #in s 
my $max_abort_rate  = 0.3;

my $mpl                = 200;
my $max_node_per_tiers = 100;
my $nb_tiers           = 1;

my $think_time         = 5;

my $delay        = [];
my $service_time = [];
my $visit_ratio  = [];

for (0..$nb_tiers-1)
{
    push(@$delay, 0.01);
    push(@$visit_ratio,1);
    push(@$service_time,0.02);
}

$delay->[0]  = 0;


#my @delay = (1) x $nb_tiers;


#my @visit_ratio  = (1) x $nb_tiers;
#my @service_time = (1) x $nb_tiers;

my $workload_class = { 
               visit_ratio  => $visit_ratio,
               service_time => undef, #Will be given by autotune algorithm
               delay        => undef, #Will be given by autotune algorithm
               think_time   => $think_time,
};

my $workload = {
     workload_class  => $workload_class,
     workload_amount => $workload_amount, 
};



my @search_spaces = ();

for (0..$nb_tiers){
   push @search_spaces, 
    {
        min_node => 1, 
        max_node => $max_node_per_tiers,
        min_mpl  => $mpl,
        max_mpl  => $mpl,
    };
}




my $constraints = {
      max_latency    => $max_latency,
      max_abort_rate => $max_abort_rate,
};

my $AC = [];      
my $LC = [];
my $init_AC_value = 1;
my $init_LC_value =$mpl;

for (0..$nb_tiers -1)
{
    push(@$AC,$init_AC_value);
    push(@$LC,$init_LC_value);
}    

my $infra_conf  = {
      M        => $nb_tiers,
      AC       => $AC,
      LC       => $LC,
};

    my $algo_conf   = {
        nb_steps            => 100,
        init_step_size      => 5,
        init_point_position => 1,
        
    };
    
my $cap_plan   = CapacityPlanning::IncrementalSearch->new();
my $model      = Model::MVAModel->new();
my $controller = Controller->new();

$cap_plan->setConstraints(constraints => $constraints);
$cap_plan->setNbTiers(tiers => $nb_tiers);
$cap_plan->setModel(model =>$model);
$cap_plan->setSearchSpaceForTiers(search_spaces => \@search_spaces);

#print Dumper $algo_conf;
#print Dumper $infra_conf;
#print Dumper $monitored_metrics;
#print Dumper $workload;

# Configure the model (Di/Si) using monitored metrics 
# return { D => \@best_D, S => \@best_S };

my $best_params = $controller -> modelTuning( 
                        algo_conf  => $algo_conf, 
                        workload   => $workload, 
                        infra_conf => $infra_conf, 
                        curr_perf  => $monitored_metrics,
                    );

# Configure the model w.r.t. the autotune algorithm
$workload_class->{service_time} = $best_params->{S};
$workload_class->{delay}        = $best_params->{D};

#Just in order to verify that the autotune algorithm learn good parameters
# OUTPUT format : (latency => abort_rate => throughput =>);
my %verif = $model->calculate(
    configuration   => $infra_conf,
    workload_class  => $workload_class,
    workload_amount => $workload_amount
); 

print "does it has learn well ? latency = $verif{latency}, abort_rate = $verif{abort_rate} \n";
 # 

# Compute the optimal infra in order to respect the SLA

#print Dumper $best_params;

# Calculate BEST CONF using computed Si and Di
 
               


#print Dumper $workload_class;
my $res = $cap_plan->calculate( 
                        workload_amount => $workload_amount, 
                        workload_class =>  $workload_class );

$infra_conf->{AC} = $res->{AC};


my %theoretical_perf = $model->calculate(  
    configuration   => $infra_conf,
    workload_class  => $workload_class,
    workload_amount => $workload_amount); 

print "current infrastructure = @{$res->{AC}}\n";
print "SLA          : max_latency = $constraints->{max_latency}, max_abort_rate = $constraints->{max_abort_rate}\n";
print "theoretical perf : latency = $theoretical_perf{latency}, abort_rate = $theoretical_perf{abort_rate}\n";

my $increase = 1000;
print "******************************************************************************\n";
print "INCREASING THE WORKLOADAMOUNT FROM $workload_amount to $workload_amount + $increase\n";
print "******************************************************************************\n";


$workload_amount+=$increase;



    %theoretical_perf = $model->calculate(  
        configuration   => $infra_conf,
        workload_class  => $workload_class,
        workload_amount => $workload_amount); 
        
    print "theoretical perf : latency = $theoretical_perf{latency}, abort_rate = $theoretical_perf{abort_rate}\n";
    
    $res = $cap_plan->calculate( 
                            workload_amount => $workload_amount, 
                            workload_class =>  $workload_class );
    
    $infra_conf->{AC} = $res->{AC};
    
    %theoretical_perf = $model->calculate(  
        configuration   => $infra_conf,
        workload_class  => $workload_class,
        workload_amount => $workload_amount); 


print "current infrastructure = @{$res->{AC}}\n";
print "SLA          : max_latency = $constraints->{max_latency}, max_abort_rate = $constraints->{max_abort_rate}\n";
print "theoretical perf : latency = $theoretical_perf{latency}, abort_rate = $theoretical_perf{abort_rate}\n";

print "******************************************************************************\n";
print "INCREASING THE MONITORED LATENCY AND ABORT RATE\n";
print "******************************************************************************\n";


#print Dumper $model->calculate(  
#    configuration => { M => 1, AC => [1], LC => [200]},
#    workload_class => {
#               visit_ratio => [1],
#               service_time => [0.01],
#               delay => [0],
#               think_time => 5 },
#    workload_amount => 1000 )   ;

#update_model((monitored_latency=>3.14,monitored_abort_rate=>7.12));

# We fake monitored metrics on a "virtual" system 


#sub update_model
#{
#    
#    #my $self = shift;
#    my %args = @_;
#    
#    General::checkParams(args => \%args, required => [m''onitored_latency, ]);
#    my $monitored_latency    = $args{monitored_latency};
#    my $monitored_abort_rate = $args{monitored_abort_rate}; 
#    
#    print "$monitored_latency $monitored_abort_rate ";
#}







