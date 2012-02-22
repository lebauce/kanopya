use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use Data::Dumper;
use Clustermetric;
use AggregateCombination;
use AggregateCondition;
use AggregateRule;


Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

my $ok = 1;

#Delete all the existing rules
for my $aggregate_rule (AggregateRule->search(hash=>{})){
    $aggregate_rule->delete();
}

if ((scalar AggregateRule->search(hash=>{})) eq 0){
    print "All the Rules have been removed \n";
} else {
    print "Error in removing rules please check the DB";
    $ok = 0;
}

#Delete all the existing conditions
for my $aggregate_condition (AggregateCondition->search(hash=>{})){
    $aggregate_condition->delete();
}

if ((scalar AggregateCondition->search(hash=>{})) eq 0){
    print "All the Conditions have been removed \n";
} else {
    print "Error in removing Conditions please check the DB";
    $ok = 0;
}

#Delete all the existing combinations
for my $aggregate_combination (AggregateCombination->search(hash=>{})){
    $aggregate_combination->delete();
}

if ((scalar AggregateCombination->search(hash=>{})) eq 0){
    print "All the Combinations have been removed \n";
} else {
    print "Error in removing the combinations  please check the DB";
    $ok = 0;
}

#Delete all the existing aggregates
for my $clustermetric (Clustermetric->search(hash=>{})){
    $clustermetric->delete();
}

if ((scalar Clustermetric->search(hash=>{})) eq 0){
    print "All the Clustermetrics have been removed \n";
} else {
    print "Error in removing the clustermetrics  please check the DB";
    $ok = 0;
}

if($ok eq 1){

    my $scom_indicatorset = $adm->{'manager'}{'monitor'}->getSetDesc( set_name => 'scom' ); 
    my @indicators;
    my @funcs = qw(mean max min standard_deviation);
    foreach my $indicator (@{$scom_indicatorset->{ds}}){
        push @indicators, $indicator->{id};
    }

    # Create one clustermetric for each indicator scom
    # Create 4 aggregates for each cluster metric
    # Create the corresponding combination 'identity function' for each aggregate 
    foreach my $indicator (@indicators) {   
        foreach my $func (@funcs) {
            my $cm_params = {
                clustermetric_cluster_id               => '54',
                clustermetric_indicator_id             => $indicator,
                clustermetric_statistics_function_name => $func,
                clustermetric_window_time              => '1200',
            };
            my $cm = Clustermetric->new(%$cm_params);
           
            my $acf_params = {
                aggregate_combination_formula   => 'id'.($cm->getAttr(name => 'clustermetric_id'))
            };
            my $aggregate_combination = AggregateCombination->new(%$acf_params);

        }
    }
    
    #Create example combination
    # max - min for each metric
    
    foreach my $indicator (@indicators) {
        #For each indicator id get the max aggregate and the min aggregate to compute max - min
        
        
        my @cm_max = Clustermetric->search(hash => { 
            clustermetric_indicator_id => $indicator,
            clustermetric_statistics_function_name => 'max',
        });
        
        my @cm_min = Clustermetric->search(hash => { 
            clustermetric_indicator_id => $indicator,
            clustermetric_statistics_function_name => 'min',
        });
        
        my $id_min = $cm_min[0]->getAttr(name=>'clustermetric_id');
        my $id_max = $cm_max[0]->getAttr(name=>'clustermetric_id'); 

        my $acf_params = {
          aggregate_combination_formula   => 'id'.($id_max).'- id'.($id_min)
        };
        
        my $aggregate_combination = AggregateCombination->new(%$acf_params);
        
        
        
        
        #For each indicator id get the mean aggregate and the standartdev aggregate to compute mean / standard_dev
        
        my @cm_mean = Clustermetric->search(hash => { 
            clustermetric_indicator_id => $indicator,
            clustermetric_statistics_function_name => 'mean',
        });
        
        my @cm_std = Clustermetric->search(hash => { 
            clustermetric_indicator_id => $indicator,
            clustermetric_statistics_function_name => 'standard_deviation',
        });
        
        my $id_mean = $cm_mean[0]->getAttr(name=>'clustermetric_id');
        my $id_std  = $cm_std[0]->getAttr(name=>'clustermetric_id'); 

        $acf_params = {
          aggregate_combination_formula   => 'id'.($id_std).'/ id'.($id_mean)
        };
        
        my $aggregate_combination = AggregateCombination->new(%$acf_params);
       
       #Creating a condition on coefficient of variation std/mean and a rule
       my $condition_params = {
            aggregate_combination_id => $aggregate_combination->getAttr(name=>'aggregate_combination_id'),
            comparator            => '>',
            threshold             => 0.5,
            state                 => 'enabled',
            time_limit            => NULL,
        };
       my $aggregate_condition = AggregateCondition->new(%$condition_params);
       
       
       my $params_rule = {
            aggregate_rule_formula   => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
            aggregate_rule_state     => 'enabled',
            aggregate_rule_action_id => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
        };


        my $aggregate_rule = AggregateRule->new(%$params_rule);
       
       
    }
    
    

};
