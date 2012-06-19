# Orchestrator.pm - Object class of Orchestrator

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 1 september 2010

=head1 NAME

Orchestrator - Orchestrator object

=head1 SYNOPSIS

    use Orchestrator;
    
    # Creates orchestrator
    my $orchestrator = Orchestrator->new();

=head1 DESCRIPTION

Orchestrator is the main object for mc management politic. 

=head1 METHODS

=cut

package Orchestrator;

###############################################################################################################
#WARN l'orchestrator considère actuellement que les noeuds sont homogènes et ne prend pas en compte les spécificités de chaque carte
#TODO Prendre en compte les spécificités des cartes dans les algos, faire un système de notation pour le choix des cartes à ajouter/supprimer
#TODO Percent option. WARN: avg % != % avg
#TODO use Kanopya Exception
###############################################################################################################

use strict;
use warnings;
#use Monitor::Retriever;
use XML::Simple;
use General;
use Administrator;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::ServiceProvider::Outside::Externalcluster;
use Data::Dumper;
use Parse::BooleanLogic;
use AggregateRule;
use NodemetricRule;
use NodemetricCondition;
use NodemetricCombination;
use Log::Log4perl "get_logger";

my $log = get_logger("orchestrator");

                
=head2 new
    
    Class : Publiu
    
    Desc : Instanciate Orchestrator object
    
    Return : Orchestrator instance
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    # Load conf
    my $conf = XMLin("/opt/kanopya/conf/orchestrator.conf");
   # Get Administrator
    my ($login, $password) = ($conf->{user}{name}, $conf->{user}{password});
    Administrator::authenticate( login => $login, password => $password );
    $self->{_admin} = Administrator->new();
    #$self->{_monitor} = Monitor::Retriever->new( );
    
    return $self;
}


=head2 manage_aggregate
    
    Class : Public
    
    Desc :     New manager for aggregates
    
=cut

sub manage_aggregates_old {
    my $self = shift;
    
    print "## UPDATE ALL $self->{_time_step} SECONDS##\n";
    eval{
        # FOR EACH EXT CLUSTERS
        my @externalClusters = Entity::ServiceProvider::Outside::Externalcluster->search(hash => {});
        
       
        CLUSTER:
        for my $externalCluster (@externalClusters){
            my $cluster_id = $externalCluster->getAttr(name => 'externalcluster_id');
            eval{   
                print "<CM $cluster_id>\n";
                $self->clustermetricManagement(externalCluster => $externalCluster);
                print "</CM $cluster_id>\n";
                1;
            }or do {
                print "Error in clustermetricManagement of cluster $cluster_id : $@\n";
                $log->error($@);
            };
            
            eval{
                print "<CN $cluster_id>\n";
                $self->nodemetricManagement(externalCluster => $externalCluster);
                print "</CN $cluster_id>\n";
                1;
            }or do{
                print "Error in nodemetricManagement of cluster $cluster_id  $@\n";
                $log->error($@);
            };
            
            my $cluster_eval = Orchestrator::evalExtCluster(extcluster_id => $cluster_id, extcluster => $externalCluster);
        }
    1;
    }or do {
        print "Skip all orchestration service due to error $@\n";
        $log->error($@);
    }
}

=head2 manage_aggregate
    
    Class : Public
    
    Desc :     New manager for aggregates
    
=cut

sub manage_aggregates {
    my $self = shift;
    
    $log->info("## UPDATE ALL $self->{_time_step} SECONDS##");

    my @service_providers = Entity::ServiceProvider->search(hash => {});

    CLUSTER:
    for my $service_provider (@service_providers){
        eval{
            my $service_provider_id = $service_provider->getAttr(name => 'service_provider_id');

            #FILTER CLUSTERS WITH MONITORING PROVIDER
            eval{
                if ($^O eq 'MSWin32') {
                    $service_provider->getConnector(category => 'MonitoringService');
                } elsif ($^O eq 'linux') {
                    $service_provider->getCollectorManager();
                }
            };
            if($@){
                
                
                $log->info('*** Orchestrator skip service provider '.$service_provider_id.' because it has no MonitoringService Connector ***');
            }
            else{
                $log->info('*** Orchestrator running for service provider '.$service_provider_id.' ***');
                eval{
                    $log->info( '<CM '.$service_provider_id.'>');
                    $self->clustermetricManagement(service_provider => $service_provider);
                    $log->info( '</CM '.$service_provider_id.'>');
                    1;
                }or do {
                    print "Error in clustermetricManagement of cluster $service_provider : $@\n";
                    $log->error($@);
                };
                
                eval{
                    $log->info( '<CN '.$service_provider.'>');
                    $self->nodemetricManagement(service_provider => $service_provider);
                    $log->info( '</CN '.$service_provider.'>');
                    1;
                }or do{
                    print "Error in nodemetricManagement of cluster $service_provider  $@\n";
                    $log->error($@);
                };
                
                #my $cluster_eval = Orchestrator::evalExtCluster(extcluster_id => $cluster_id, extcluster => $externalCluster);#
            }
        1;
        }or do {
            print "Skip all orchestration service due to error $@\n";
            $log->error($@);
        }
    }

}

sub evalExtCluster{
    my %args = @_;
    
    my $cr_eval = Orchestrator::evalExtClusterClusterRuleState(extcluster_id => $args{extcluster_id});
    my $nr_eval = Orchestrator::evalExtClusterNodeRuleState(extcluster => $args{extcluster}, extcluster_id => $args{extcluster_id});
    
    my $cluster_eval = {%$cr_eval,%$nr_eval};
    
    #print Dumper $cluster_eval;
    
    if((scalar $cluster_eval->{nm_rule_nodes}) == 0) { # no nodes
         $args{extcluster}->setAttr(
            name => 'externalcluster_state',
            value => 'down',
        );
    }
    elsif ($cluster_eval->{nm_rule_enabled} == 0 && $cluster_eval->{cm_rule_enabled} == 0) { # no rules 
         $args{extcluster}->setAttr(
            name => 'externalcluster_state',
            value => 'up',
        );
    }
#    elsif ($cluster_eval->{nm_rule_enabled} == 0) { # cm_rule_enabled > 0 
#        if($cluster_eval->{cm_rule_undef} == 0 && $cluster_eval->{cm_rule_nok} == 0){
#            $args{extcluster}->setAttr(
#                name => 'externalcluster_state',
#                value => 'up',
#            );
#        }elsif($cluster_eval->{cm_rule_nok} > 0){
#            $args{extcluster}->setAttr(
#                name => 'externalcluster_state',
#                value => 'warning',
#            );
#        }else{
#            $args{extcluster}->setAttr(
#                name => 'externalcluster_state',
#                value => 'down',
#            );
#        }
#    }
#    elsif ($cluster_eval->{cm_rule_enabled} == 0) { # nm_rule_enabled > 0
#        if($cluster_eval->{nm_rule_nodes_nok} == 0 && $cluster_eval->{nm_rule_nodes_down} == 0){
#            $args{extcluster}->setAttr(
#                name => 'externalcluster_state',
#                value => 'up',
#            );
#        }
#        elsif($cluster_eval->{nm_rule_nodes_nok} > 0) {
#            $args{extcluster}->setAttr(
#                name => 'externalcluster_state',
#                value => 'warning',
#            );
#        }else{
#            $args{extcluster}->setAttr(
#                name => 'externalcluster_state',
#                value => 'down',
#            );
#        }
#    }
    else { # nm_rule_enabled > 0 AND cm_rule_enabled > 0 
        if($cluster_eval->{nm_rule_nodes_nok} == 0 && $cluster_eval->{nm_rule_nodes_down} == 0
        && $cluster_eval->{cm_rule_undef} == 0 && $cluster_eval->{cm_rule_nok} == 0)
        {
            $args{extcluster}->setAttr(
                name => 'externalcluster_state',
                value => 'up',
            );
        }elsif(
            $cluster_eval->{cm_rule_undef} == $cluster_eval->{cm_rule_enabled} &&
            $cluster_eval->{nm_rule_nodes_down} == (scalar $cluster_eval->{nm_rule_nodes}) 
        ){
            $args{extcluster}->setAttr(
                name => 'externalcluster_state',
                value => 'down',
            );
        } else {
            $args{extcluster}->setAttr(
                name => 'externalcluster_state',
                value => 'warning',
            );
        }
    }

#
#    ){
#    }
#    if($cluster_eval->{} + $cluster_eval->{}  >0){
#         $externalCluster->setAttr(
#                name => 'externalcluster_state',
#                value => 'warning',
#            );
#    }else{
#        $externalCluster->setAttr(
#            name => 'externalcluster_state',
#            value => 'up',
#        );
#    }
    $args{extcluster}->save();
    return $cluster_eval;
}

sub evalExtClusterNodeRuleState {
    my %args = @_;
    my $extcluster     = $args{extcluster};
    my $extcluster_id  = $args{extcluster_id};
    
    my $externalClusterState = {};
    
    my $nodes = $extcluster->getNodes();
    
    $externalClusterState->{nm_rule_nodes}   = scalar (@$nodes);    
    $externalClusterState->{nm_rule_enabled} = my $num_node_rule_total = scalar NodemetricRule->searchLight(
                                    hash=>{
                                        'nodemetric_rule_service_provider_id' => $extcluster_id,
                                        'nodemetric_rule_state' => 'enabled',
                                    }
                                 );
    
    $externalClusterState->{nm_rule_nodes_ok}    = 0;
    $externalClusterState->{nm_rule_nodes_nok}   = 0;
    $externalClusterState->{nm_rule_nodes_down}  = 0;
    $externalClusterState->{nm_rule_nok}         = 0;
    $externalClusterState->{nm_rule_ok}          = 0;
    $externalClusterState->{nm_rule_undef}       = 0;
    

    
    foreach my $node (@$nodes) {
        $externalClusterState->{nm_rule_nok}   += $node->{num_verified_rules};
        $externalClusterState->{nm_rule_undef} += $node->{num_undef_rules};

        if($externalClusterState->{nm_rule_enabled} > 0){ # TEST IF THERE ARE ENABLED RULES 
            if($node->{num_undef_rules} == $externalClusterState->{nm_rule_enabled}){ # TEST IF THERE ARE DATA
                $node->{state} = 'down';
                $extcluster->updateNodeState(hostname => $node->{hostname}, state => 'down');
                $externalClusterState->{nm_rule_nodes_down}++;
            } else {
                if($node->{num_verified_rules} > 0 || $node->{num_undef_rules} > 0){
                    $externalClusterState->{nm_rule_nodes_nok}++;
                    $node->{state} = 'warning';
                    $extcluster->updateNodeState(hostname => $node->{hostname}, state => 'warning');
                }else{
                    $externalClusterState->{nm_rule_nodes_ok}++;
                    $extcluster->updateNodeState(hostname => $node->{hostname}, state => 'up');
                    $node->{state} = 'up';
                }
            }
        }else{ #NO RULES ENABLED, NODE OK!
            $node->{state} = 'up';
            $extcluster->updateNodeState(hostname => $node->{hostname}, state => 'up');
        } 
        
    }
    $externalClusterState->{nm_rule_nodes} = $nodes;
    return $externalClusterState;
}


sub evalExtClusterClusterRuleState {
    my %args = @_;
    my $extcluster_id = $args{extcluster_id};
    my $externalClusterState = {};
    
    
    my @rules = AggregateRule->search(
        hash => {
                    aggregate_rule_service_provider_id => $extcluster_id,
                }
        );
        
    my @enabled_rules = AggregateRule->search(
        hash => {
                    aggregate_rule_service_provider_id => $extcluster_id,
                    aggregate_rule_state               => 'enabled',
                }
        );
        
    my @verif_rules = AggregateRule->search(
        hash => {
                    aggregate_rule_service_provider_id => $extcluster_id,
                    aggregate_rule_state               => 'enabled',
                    aggregate_rule_last_eval           => 1,
                }
        );

    my @ok_rules = AggregateRule->search(
        hash => {
                    aggregate_rule_service_provider_id => $extcluster_id,
                    aggregate_rule_state               => 'enabled',
                    aggregate_rule_last_eval           => 0,
                }
        );

    my @undef_rules = AggregateRule->search(
        hash => {
                    aggregate_rule_service_provider_id => $extcluster_id,
                    aggregate_rule_state               => 'enabled',
                    aggregate_rule_last_eval           => undef,
                }
        );
    $externalClusterState->{cm_rule_total}   = scalar @rules;
    $externalClusterState->{cm_rule_enabled} = scalar @enabled_rules;
    $externalClusterState->{cm_rule_nok}     = scalar @verif_rules;
    $externalClusterState->{cm_rule_ok}      = scalar @ok_rules;
    $externalClusterState->{cm_rule_undef}   = scalar @undef_rules;

    return $externalClusterState;
}
sub nodemetricManagement{
    my ($self, %args) = @_;
    my $service_provider = $args{service_provider};

    # Merge all needed indicators to consctruc only one SCOM request

    my $service_provider_id = $service_provider->getId();

    $log->info('Cluster NM management'.$service_provider_id);
        
    my @rules = NodemetricRule->search(
                    hash => {
                        nodemetric_rule_service_provider_id => $service_provider_id,
                        nodemetric_rule_state               => 'enabled',
                    }
                );
        
    my $host_indicator_for_retriever = $self->_contructRetrieverOutput('rules' => \@rules, service_provider_id => $service_provider_id);


        # Call the retriever to get SCOM data
        my $monitored_values = $service_provider->getNodesMetrics(indicators => $host_indicator_for_retriever->{indicators}, time_span => $host_indicator_for_retriever->{time_span});
        $log->info(Dumper $monitored_values);
        
    # Eval the rules
    my $rep = $self->_evalAllRules(
        'monitored_values'  => $monitored_values,
        'rules'             => \@rules,
        'service_provider'  => $service_provider,
    );
        
#            if(0 < $rep){
#                
#                $externalCluster->setAttr(
#                    name => 'externalcluster_state',
#                    value => 'warning',
#                );
#            }else{
#                $externalCluster->setAttr(
#                    name => 'externalcluster_state',
#                    value => 'up',
#                );
#            }
#            $externalCluster->save();
}

sub _evalAllRules {
   my ($self,%args) = @_;
   
   my $monitored_values = $args{monitored_values};
   my $rules            = $args{rules};
   my $service_provider = $args{service_provider};
   my $rep = 0;
   
   RULE:
   foreach my $rule (@$rules){
       $log->info('Eval NM rule '.$rule->getAttr(name=>'nodemetric_rule_id'));
       eval{
           $rep += $self->_evalRule(
               'rule'             =>$rule,
               'monitored_values' => $monitored_values,
               'service_provider' => $service_provider,
           );
           1;
       } or do {
            print 'Error in evaluation of rule'.($rule->getAttr(name=>'nodemetric_rule_id')).' of cluster '.($rule->getAttr(name=>'nodemetric_rule_service_provider_id')).": $@\n";
            $log->error($@);
       }
   }
   return $rep;
}

sub _evalRule {
    my ($self,%args) = @_;

    my $monitored_values = $args{monitored_values};
    my $rule             = $args{rule};
    my $service_provider = $args{service_provider};

    my $service_provider_id = $service_provider->getId();

    my $workflow_manager = $service_provider->getManager(manager_type => 'workflow_manager');
    my $workflow_def_id  = $rule->getAttr(name => 'workflow_def_id');
    my $rep = 0;
    #Eval the rule for each node

    NODE:
    while(my ($host_name,$monitored_values_for_one_node) = each %$monitored_values){
        # Warning, not all the monitored values are required but we transmit 
        # all of them
        
        #        if (0 ==  keys %$monitored_values_for_one_node) {
        #            $cluster->updateNodeState( hostname => $host_name, state => 'down' );
        #            next NODE;
        #        }
        #        $cluster->updateNodeState( hostname => $host_name, state => 'up' );

        my $node_state = $service_provider->getNodeState(hostname=> $host_name);

        my $nodeEval;
        if($node_state eq 'disabled'){
            print "Node $host_name has just been disabled, rule not evaluated\n"; 
            next NODE;
        }
        else {
            $nodeEval = $rule->evalOnOneNode(
                monitored_values_for_one_node => $monitored_values_for_one_node
            );
        }
        
        if(defined $nodeEval){
            #print 'RULE '.$rule->getAttr(name => 'nodemetric_rule_id').' ON HOST '.$host_name;
            
            if($nodeEval eq 0){
                #print ' WARNING'."\n";
                $rule->deleteVerifiedRule(
                    hostname   => $host_name,
                    cluster_id => $service_provider_id,
                );
            }else {
                #print ' OK'."\n";
                $rep++;
                $rule->setVerifiedRule(
                    hostname => $host_name,
                    cluster_id => $service_provider_id,
                    state      => 'verified'
                );
                $workflow_manager->runWorkflow(workflow_def_id => $workflow_def_id, host_name => $host_name);
            }
        }else{
            #print 'RULE '.$rule->getAttr(name => 'nodemetric_rule_id').' ON HOST '.$host_name.' UNDEF'."\n";
            $rule->setVerifiedRule(
                hostname => $host_name,
                cluster_id => $service_provider_id,
                state      => 'undef'
            );
        }
    }
    return $rep;
}
# Construct hash table for the service provider.
# Inspired by eponyme aggregator method 

sub _contructRetrieverOutput {
    my ($self,%args) = @_;

    my $service_provider_id = $args{service_provider_id};
    my $rules               = $args{rules};

    my $service_provider    = Entity::ServiceProvider->find( hash => { service_provider_id => $service_provider_id});
    my $indicators_name     = undef;

    #Get all the rules relative to the cluster_id 
    
    for my $rule (@$rules){
        my @conditions = $rule->getDependantConditionIds();
        #Check each conditions (i.e. each Combination
        for my $condition_id (@conditions) {

            my $condition = NodemetricCondition->get('id' => $condition_id);

            # Get the related combination id (in order to parse its formula)            
            my $combination_id = $condition->getAttr(name => 'nodemetric_condition_combination_id');

            my $combination = NodemetricCombination->get('id' => $combination_id);
            # get the indicator ids used in combination formula
            my @indicator_ids = $combination->getDependantIndicatorIds();

            for my $indicator_id (@indicator_ids){
                my $indicator_oid = $service_provider->getIndicatorOidFromId (indicator_id => $indicator_id);
                $indicators_name->{$indicator_oid} = undef;
            }
        }
    }
    my @indicators_array = keys(%$indicators_name);
    
    my $rep = {
        indicators => \@indicators_array,
        time_span  => 1200,
    };
    #print Dumper $rep;
    return $rep;
};

sub clustermetricManagement{
    my ($self, %args) = @_;
    my $service_provider = $args{service_provider};

    my $cluster_evaluation = {};
    my $service_provider_id = $service_provider->getId();

    my $workflow_manager = $service_provider->getManager(manager_type => 'workflow_manager');

    #GET RULES RELATIVE TO A CLUSTER
    my @rules = AggregateRule->search(hash=>{
        aggregate_rule_service_provider_id => $service_provider_id,
        aggregate_rule_state               => 'enabled'
    });

    for my $aggregate_rule (@rules){
        $log->info('CM Rule '.$aggregate_rule->getAttr(name => 'aggregate_rule_id').' '.$aggregate_rule->toString());

            $log->info('CM Rule '.$aggregate_rule->getAttr(name => 'aggregate_rule_id').' '.$aggregate_rule->toString());
            
            my $result = $aggregate_rule->eval();
            
             # LOOP USED TO TRIGGER ACTIONS

            if(defined $result){
                if($result == 1){
                    my $workflow_def_id  = $aggregate_rule->getAttr(name => 'workflow_def_id');
                    $workflow_manager->runWorkflow(workflow_def_id => $workflow_def_id);
                }
            }
        } # for my $aggregate_rule 

#return $clusters_state_cm;
}

=head2 manage
    
    Class : Public
    
    Desc :     Check mc state and manage clusters.
            For each cluster, detect traps (for adding node) and check conditions for removing node
    
=cut

sub manage {
    my $self = shift;
    
    my $monitor = $self->{_monitor};
    
    my @skip_clusters = (); #('adm');
    
    my @all_clusters_name = $monitor->getClustersName();
    
    CLUSTER:
    for my $cluster (@all_clusters_name) {
        if ( scalar grep { $_ eq $cluster } @skip_clusters ) {
            $log->info(" => skip cluster $cluster\n");
            next CLUSTER;
        }

        eval {
            #TODO keep cluster id from the beginning (get by name is not really good)
            my $cluster_id = Entity::ServiceProvider::Inside::Cluster->getCluster( hash => { cluster_name => $cluster } )->getAttr( name => "cluster_id");
        
            my $rules_manager = $self->{_admin}->{manager}{rules};
            
            # Solve rules
            my $rules = $rules_manager->getClusterRules( cluster_id => $cluster_id );
            $self->solve( rules => $rules, cluster_name => $cluster );
            
            # Try to optimize
            my $optim_conditions = $rules_manager->getClusterOptimConditions( cluster_id => $cluster_id );
            $self->optimize( condition_tree => $optim_conditions, cluster_name => $cluster );
            
            # Update graph for this cluster
            $self->updateGraph( cluster => $cluster );
        };
        if ($@) {
            my $error = $@;
            if ( $error =~ "rrdtool graph" ) {
                $log->info("=> Can't produce graph (no data)\n");
            } else {
                $log->error("error for cluster '$cluster' : $error\n");
            }
        }
    }

}

=head2
    
    Class : Public
    
    Desc : Retrieve the mean value of a monitored var on a defined time laps, for the cluster
    
    Args : same as Monitor::getClusterData()
        
    Return :
        undef is the required var is not found
        else the value
=cut

sub getValue {
    my $self = shift;
    my %args = @_;
    

    my $cluster_data_aggreg;
    eval {
        $cluster_data_aggreg = $self->{_monitor}->getClusterData(     cluster => $args{cluster},
                                                                    set => $args{set},
                                                                    time_laps => $args{time_laps},
                                                                    percent => $args{percent},
                                                                    aggregate => $args{aggregate});
    };
    if ($@) {
        my $error = $@;
        $log->error("=> Error getting data (set '$args{set}' for cluster '$args{cluster}') : $error");
        return;
    }

    my $value = $cluster_data_aggreg->{ $args{ds} };
    if (not defined $value) {
        $log->warn("No value of '$args{set}:$args{ds}' for cluster '$args{cluster}' (for last $args{time_laps}sec, maybe time step is too small).  considered as undef.");
        return;
    }
    
    return $value;
}

=head2 evaluate
    
    Class : Public
    
    Desc : evaluate a 
    
    Args :
        lval: scalar
        rval: scalar
        op: the comp operator string ( 'inf', 'sup' )
    
    Return :
        0 (false or one value undef) or 1 (true)
=cut

sub evaluate {
    my $self = shift;
    my %args = @_;
    
    return 0 if ( not defined $args{lval} || not defined $args{rval} );
    
    return 1 if (($args{op} eq 'inf' &&  ($args{lval} < $args{rval})) ||
                ($args{op} eq 'sup' &&  ($args{lval} > $args{rval})) ); 
    
    return 0;
}

=head2 checkCondition
    
    Class : Public
    
    Desc : retrieve value of condition var and evaluate condition
    
    Args :
        condition: hash ref representing a condition
    
    Return :
        0 if condition is false
        1 if condition is true
=cut

sub checkCondition {
    my $self = shift;
    my %args = @_;
    my $condition = $args{condition};
    
    #$log->debug( join ", ", map { "$_: $condition->{$_}" } keys %$condition );
    
    my ($set, $ds) = split ':', $condition->{var};
    my $var_value = $self->getValue(
                                        cluster => $args{cluster_name},
                                        set => $set,
                                        ds => $ds,
                                        time_laps => $condition->{time_laps},
                                        percent => $condition->{percent},
                                        aggregate => "mean");
    my $res = $self->evaluate( lval => $var_value, rval => $condition->{value}, op => $condition->{operator} );
     $log->debug("# eval " . $condition->{var} . "($condition->{time_laps})" . " = " . (defined $var_value ? $var_value : "undef") . " ". $condition->{operator} . " " . $condition->{value} .
                 " ==> " . ($res > 0 ? "ok" : "fail"));    
    
    return $res;
}

=head2 checkOptimCondition
    
    Class : Public
    
    Desc : retrieve value of condition var, compute prevision for this value if a node is removed, and evaluate condition
    
    Args :
        condition: hash ref representing a condition
    
    Return :
        0 if condition is false
        1 if condition is true
=cut

sub checkOptimCondition {
    my $self = shift;
    my %args = @_;
    my $condition = $args{condition};
    
    #$log->debug( join ", ", map { "$_: $condition->{$_}" } keys %$condition );
    
    my ($set, $ds) = split ':', $condition->{var};
    my $var_value = $self->getValue(
                                        cluster => $args{cluster_name},
                                        set => $set,
                                        ds => $ds,
                                        time_laps => $condition->{time_laps},
                                        percent => $condition->{percent},
                                        aggregate => "mean");
    
    my $prevision = (defined $var_value && $args{upnode_count} > 1) ? ($var_value + ( $var_value / ( $args{upnode_count} - 1 ))) : undef;
    my $res = $self->evaluate( lval => $prevision, rval => $condition->{value}, op => $condition->{operator} );
     $log->debug("# eval " . $condition->{var} . " = " . (defined $var_value ? $var_value : "undef") . " ".
                 "prevision after optim = " . $prevision . " " . $condition->{operator} . " " . $condition->{value} .
                 " ==> " . ($res > 0 ? "ok" : "fail"));    
    
    return $res;
}

=head2 solve
    
    Class : Public
    
    Desc : Solve each rules (by checking conditions of tree) and call the associated action if the rule is activated
    
    
    Args :
        cluster_name
        rules: array ref of rules. A rule is { condition_tree => [...], action => 'action_name' }
    
=cut

sub solve {
    my $self = shift;
    my %args = @_;

    my $parser = Parse::BooleanLogic->new( operators => [qw(& |)] );

    my $cluster_name = $args{cluster_name};

    my $solver = sub {
        my ($condition, $ctx) = @_;
        return $self->checkCondition( condition => $condition, cluster_name => $cluster_name );
    };

    my $ctx = undef;
    foreach my $rule (@{ $args{rules} }) {
        $log->info('# rule #');
        my $result = $parser->solve( $rule->{condition_tree}, $solver, $ctx);
        if ($result > 0) {
            $log->info("Rule activated => action : " . $rule->{action});
            $self->doAction( action => $rule->{action}, cluster_name => $cluster_name );
        }
    }

    
}

=head2 doAction
    
    Class : Public
    
    Desc : call the action function according to action name
    
    Args :
        action: string: name of a defined action
        cluster_name: the cluster targetted by the action
        
=cut

sub doAction {
    my $self = shift;
    my %args = @_;
    
    my %actions = ( "add_node" => \&requireAddNode, "remove_node" => \&requireRemoveNode );
    my $action_sub = $actions{$args{action}};
    
    if (not defined $action_sub) {
        $log->warn("Required action is undefined : '$args{action}'");
        return;
    }
    
    $action_sub->( $self, cluster => $args{cluster_name} );
}

=head2 optimize
    
    Class : Public
    
    Desc : Try to optimize cluster node count by removing node according to optimize conditions
    
    Args :
        cluster_name
        condition_tree : array ref representing a tree of conditions with separator '|' or '&'
    
=cut

sub optimize {
    my $self = shift;
    my %args = @_;

    my $cluster_name = $args{cluster_name};

    my $cluster_info = $self->{_monitor}->getClusterHostsInfo( cluster => $cluster_name );
    my $upnode_count = grep { $_->{state} =~ 'up' } values %$cluster_info;
    
    if ( $upnode_count <= 1 ) {
        $log->info("No node to eventually remove in '$cluster_name' => don't try to optimize node count");
        return;
    }
    
    my $parser = Parse::BooleanLogic->new( operators => [qw(& |)] );
    my $solver = sub {
        my ($condition, $ctx) = @_;
        return $self->checkOptimCondition( condition => $condition, cluster_name => $cluster_name, upnode_count => $upnode_count );
    };

    my $ctx = undef;
    my $result = $parser->solve( $args{condition_tree}, $solver, $ctx);
    if ($result > 0) {
        $log->info("Can optimize cluster '$cluster_name' => remove node");
        $self->doAction( action => "remove_node", cluster_name => $cluster_name );
    }
}

sub updateGraph {
    my $self = shift;
    my %args = @_;
    my $cluster = $args{cluster};
    $self->graph( cluster => $cluster, op => 'add' );
    $self->graph( cluster => $cluster, op => 'remove' );
}


=head2 _isNodeInState
    
    Class : Private
    
    Desc : Check if there is a least one node in the specificied state in the cluster
    
    Args :
        cluster: name of the cluster
        state: state name
    
    Return :
        0 : not found
        1 : there is a node with this state in the cluster  
    
=cut

sub _isNodeInState {
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};    
    my $state = $args{state};
    
    my $monitor = $self->{_monitor};
    my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster );
    foreach my $host (values %$cluster_info) {
        if ($host->{state} =~ $state) {
            return 1;
        }
    }
    return 0;
}

sub _isNodeMigrating {
    my $self = shift;
    my %args = @_;
    
    my $cluster_name = $args{cluster_name};
    
    my $cluster = $self->getClusterByName( cluster_name => $cluster_name );
    my $hosts = $cluster->getHosts();
    for my $mb (values %$hosts) {
        if (not $mb->getNodeState() eq "in") {
            return 1;
        }
    }    
    
    return 0;
}

=head2 _isOpInQueue
    
    Class : Private
    
    Desc : Check if there is an operation of the specified type associated to the cluster
    
    Args :
        cluster: name of the cluster
        type: operation type name (corresponding to operation class name)
    
    Return :
        0 : not found
        1 : there is a operation of this type for this cluster
    
=cut

sub _isOpInQueue {
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    my $type = $args{type};
    
    my $adm = $self->{_admin};

    #TODO keep cluster id from the beginning (get by name is not really good)
    my $cluster_id = Entity::ServiceProvider::Inside::Cluster->getCluster( hash => { cluster_name => $cluster } )->getAttr( name => "cluster_id");
    
    
    foreach my $op ( @{ $adm->getOperations() } ) {
        if ($op->{'TYPE'} eq $type) {
            foreach my $param ( @{ $op->{'PARAMETERS'} } ) {
                if ( ($param->{'PARAMNAME'} eq 'cluster_id') && ($param->{'VAL'} eq $cluster_id) ) {
                    return 1;
                }
            }    
        }
    }
    
    return 0;
}

=head2 _canAddNode
    
    Class : Private
    
    Desc : Check if all conditions to add a node in the cluster are met.
    
    Args :
        cluster : name of the cluster in which we want add a node
    
    Return :
        0 : one condition failed
        1 : ok 
    
=cut

sub _canAddNode {
    my $self = shift;
    my %args = @_;
    
    my $cluster_name = $args{cluster};
    
    # Check if no node of the cluster is migrating  
    if ( $self->_isNodeMigrating( cluster_name => $cluster_name ) ) {
        $log->info(" => A node in this cluster is currently migrating");
        return 0;
    } 
    
#    # Check if there is already a node starting in the cluster #
#    if (     $self->_isNodeInState( cluster => $cluster_name, state => 'starting' ) ||
#            $self->_isNodeInState( cluster => $cluster_name, state => 'locked' ) ) {
#        $log->info(" => A node is already starting or locked in cluster '$cluster_name'");
#        return 0;
#    }
#    
#    # Check if there is a corresponding add node operation in operation queue #
#    if ( $self->_isOpInQueue( cluster => $cluster_name, type => 'AddHostInCluster' ) ) {
#        $log->info(" => An operation to add node in cluster '$cluster_name' is already in queue");
#        return 0;
#    }
    
    return 1;
}

sub requireAddNode { 
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    $log->info("Node required in cluster '$cluster'");
    
    eval {
           if ( $self->_canAddNode( cluster => $cluster ) ) {
            $self->addNode( cluster_name => $cluster );
            $self->_storeTime( time => time(), cluster => $cluster, op_type => "add", op_info => "ok" );
           } else {
               $self->_storeTime( time => time(), cluster => $cluster, op_type => "add", op_info => "req" );
           }
    };
    if ($@) {
        my $error = $@;
        $log->error("=> Error while adding node in cluster '$cluster' : $error");
    }
}

=head2 _canRemoveNode
    
    Class : Private
    
    Desc : Check if all conditions to remove a node from the cluster are met.
    
    Args :
        cluster : name of the cluster in which we want remove a node
    
    Return :
        0 : one condition failed
        1 : ok 
    
=cut

sub _canRemoveNode {
    my $self = shift;
    my %args = @_;
    
    my $cluster_name = $args{cluster};
    
    # Check if no node of the cluster is migrating  
    if ( $self->_isNodeMigrating( cluster_name => $cluster_name ) ) {
        $log->info(" => A node in this cluster is currently migrating");
        return 0;
    }
    
#    # Check if there is a corresponding remove node operation in operation queue #
#    if (     $self->_isOpInQueue( cluster => $cluster, type => 'RemoveHostFromCluster' ) || 
#            $self->_isOpInQueue( cluster => $cluster, type => 'StopNode' ) )
#    {
#        $log->info(" => An operation to remove node from cluster '$cluster' is already in queue");
#        return 0;
#    }
    
    return 1;
}

sub requireRemoveNode { 
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    $log->info("Want remove node in cluster '$cluster'");
    
    eval {
           if ( $self->_canRemoveNode( cluster => $cluster ) ) {
            $self->removeNode( cluster_name => $cluster );
            $self->_storeTime( time => time(), cluster => $cluster, op_type => "remove", op_info => "ok");
           } else {
               $self->_storeTime( time => time(), cluster => $cluster, op_type => "remove", op_info => "req");
           }
    };
       if ($@) {
        my $error = $@;
        $log->error("=> Error while removing node in cluster '$cluster' : $error");
    }
    
}


sub getClusterByName {
    my $self = shift;
    my %args = @_;

       my @cluster = Entity::ServiceProvider::Inside::Cluster->getClusters( hash => { cluster_name => $args{cluster_name} } );
       die "More than one cluster with the name '$args{cluster_name}'" if ( 1 < @cluster);
       die "Cluster with name '$args{cluster_name}' no longer exists" if ( 0 == @cluster);
       return pop @cluster;
}

sub addNode {
    my $self = shift;
    my %args = @_;
    
    $log->info("====> add node in $args{cluster_name}");
    
#    #my @free_hosts = Entity::Host->getHosts( hash => { active => 1, host_state => 'down'} );
#    my @free_hosts = Entity::Host->getFreeHosts();
#    
#    die "No free host to add in cluster '$args{cluster_name}'" if ( scalar @free_hosts == 0 );
#    
#    #TODO  Select the best node ?
#    my $host = pop @free_hosts;
    
    my $cluster = $self->getClusterByName( cluster_name => $args{cluster_name} );
    
    ############################################
    # Enqueue the add host operation
    ############################################
    $cluster->addNode( );

}

sub removeNode {
    my $self = shift;
    my %args = @_;
    
    $log->info("====> remove node from $args{cluster_name}");
    
    my $cluster_name = $args{cluster_name};
    
    #TODO Find the best node to remove (notation system)
    my $monitor = $self->{_monitor};
    my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster_name );
    my @up_nodes = grep { $_->{state} =~ 'up' } values %$cluster_info;
  
    my $cluster = $self->getClusterByName( cluster_name => $cluster_name );
    my $master_node_ip = $cluster->getMasterNodeIp();
    
    my $node_to_remove = shift @up_nodes;
    ($node_to_remove = shift @up_nodes) if ($node_to_remove->{ip} eq $master_node_ip);
    die "No up node to remove in cluster '$cluster_name'." if ( not defined $node_to_remove );
    
    # TODO keep the host ID and get it with this id! (ip can be not unique)
    my @mb_res = Entity::Host->getHostFromIP( ipv4_internal_ip => $node_to_remove->{ip} );
    die "Several hosts with ip '$node_to_remove->{ip}', can not determine the wanted one" if (1 < @mb_res); # this die must desappear when we'll get mb by id
    my $mb_to_remove = shift @mb_res;
    die "host '$node_to_remove->{ip}' no more in DB" if (not defined $mb_to_remove);
    
    ############################################
    # Enqueue the remove host operation
    ############################################
    $cluster->removeNode( host_id => $mb_to_remove->getAttr(name => 'host_id') );
}

=head2 _storeTime
    
    Class : Private
    
    Desc :     Store in a file the date (in seconds) of an operation (add/remove node) on a cluster.
            Keep only the last $NUMBER_TO_KEEP values.
            Use _getTimes() to retrieve stored times.
    
    Args :
        time: time in second (since epoch) to store
        cluster: name of the cluster concerned by the operation
        op_type: operation type
    
=cut

sub _storeTime {
    my $self = shift;
    my %args = @_;
    
    my $NUMBER_TO_KEEP = 100;
    
    my $file = $self->_timeFile( cluster => $args{cluster} );  
    
    my $info = $args{op_info} || "";
    
    my $times = "";
    if ( open FILE, "<$file" ) {
        $times = <FILE>;
        close FILE;
    }
    my @times = $times ? split( /,/, $times ) : ();
    my @last_times = scalar @times > $NUMBER_TO_KEEP ? @times[$#times + 1 - $NUMBER_TO_KEEP .. $#times] : @times;
    push @last_times, "$args{op_type}:$info". '@' . "$args{time}";
    open FILE, ">$file";
    print FILE join(",", @last_times);
    close FILE;
}

=head2 _getTimes
    
    Class : Private
    
    Desc : Retrieve times corresponding to op_type for the cluster
    
    Args :
        cluster: name of the cluster concerned by the operation
        op_type: operation type
    
    Return : Array of times
    
=cut

sub _getTimes {
    my $self = shift;
    my %args = @_;

    my $file = $self->_timeFile( cluster => $args{cluster} );
    
    my %times = ();
       if ( open FILE, "<$file" ) {
        my $times = <FILE>;
        close FILE;
        my @alltimes = split( /,/, $times );
        my @optimes = grep { $_ =~ $args{op_type} } @alltimes;
        foreach my $op ( @optimes ) {
            if ( $op =~ /[a-zA-Z_]+:([a-zA-Z_]*)@([\d]+)/ ) {
                $times{ $2 } = $1;
            }
        }
       }
#       else
#       {
#           print "Can't open orchestrator time file for cluster '$args{cluster}'\n";
#       }
    
    return %times;
}

sub _timeFile  {
    my $self = shift;
    my %args = @_;

    return $self->{_rrd_base_dir} ."/" . "orchestrator" . "_" . "$args{cluster}" . ".time";
}

sub updateRRD {
    my $self = shift;
    my %args = @_;
    
    my $rrd = $self->getRRD( cluster => $args{cluster}, op => $args{op} );
    eval {
        $rrd->update( time => $args{time}, values => $args{values} );
    };
    if ($@) {
        my $error = $@;
        $log->Info("Info: conf changed ($error)");
        my $rrd = $self->getRRD( cluster => $args{cluster}, op => $args{op}, force_create => 1 );
        $rrd->update( time => $args{time}, values => $args{values} );
    }
}

sub getRRD {
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    my $rrd_file = "$self->{_rrd_base_dir}/orchestrator_$cluster" . "_$args{op}" . ".rrd";
    
    my $rrd;
    if ( -e $rrd_file && not defined $args{force_create} ) {
        $rrd = RRDTool::OO->new( file =>  $rrd_file );
    } else {
        $log->info("info: create orchestrator rrd for cluster '$cluster'");
        $rrd = $self->createRRD( file => $rrd_file, op => $args{op} );
    }
    return $rrd;
}

sub createRRD {
    my $self = shift;
    my %args = @_;

    # Build list of var to store (all traps or conditions var)
    my ($rules, $tag) = $args{op} eq "add" ? ($self->{_traps}, 'threshold') : ($self->{_conditions}, 'required');
    
    my @var_list = ();
    for my $rule ( @{ $rules } ) {
        foreach my $cond ( @{ General::getAsArrayRef( data => $rule, tag => $tag ) }) {
            push @var_list, $cond->{var} . "_" . $rule->{time_laps};
        }
    }

    my $rrd = RRDTool::OO->new( file =>  $args{file} );

    #my $raws = $self->{_period} / $self->{_time_step};
    my $raws = 3000;

    my @rrd_params = (     'step', $self->{_time_step},
                        'archive', { rows    => $raws }
                     );
                     
    for my $name ( @var_list ) {
        push @rrd_params,     (
                                'data_source' => {     name      => $name,
                                                      type      => 'GAUGE' },            
                            );
    }

    # Create a round-robin database
    $rrd->create( @rrd_params );
    
    return $rrd;
}


sub graph {
    my $self = shift;
    my %args = @_;

#    use Log::Log4perl qw(:easy);
#    Log::Log4perl->easy_init({
#        level    => $DEBUG
#    }); 
    
    my $cluster = $args{cluster};
    my $op = $args{op};
    
    my $time_laps = 3600;
    
    my $graph_dir = $self->{_graph_dir};
    my $graph_filename = "graph_orchestrator_$cluster" . "_$op" . ".png";

    #my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
    #my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');

    my $rrd_file = "$self->{_rrd_base_dir}/orchestrator_$cluster" . "_$op" . ".rrd";

    return if ( not -e $rrd_file );

    # get rrd     
    my $rrd = RRDTool::OO->new( file => $rrd_file );

    my @graph_params = (
                            'image' => "$graph_dir/$graph_filename",
                            #'vertical_label', 'ticks',
                            'start' => time() - $time_laps,
                            color => { back => "#69B033" },
                            
                            title => ($args{op} eq "add" ? "Add" : "Remove") . " rules analysis",
                            
                            lower_limit => 0,
                            #upper_limit => 100,
                            
                            #width => 500,
                            #height => 500,

                        );

    # Add vertical red lines corresponding to add times
    my %add_times = $self->_getTimes( cluster => $cluster, op_type => "add" );
    while ( my ($add_time, $add_info) = each %add_times ) {
        my $color = (defined $add_info && $add_info eq "ok") ? "#FF0000" : "#FFBBBB";
        push @graph_params, ( vrule => { time => $add_time, color => $color } );
    }

    # Add vertical green lines corresponding to remove times
    my %remove_times = $self->_getTimes( cluster => $cluster, op_type => "remove" );
    while ( my ($remove_time, $remove_info) = each %remove_times ) {
        my $color = (defined $remove_info && $remove_info eq "ok") ? "#00FF00" : "#BBFFBB";
        push @graph_params, ( vrule => { time => $remove_time, color => $color } );
    }
    
    # Graph data and add horizontal lines corresponding to thresholds for this op
    my ($rules, $tag) = $args{op} eq "add" ? ($self->{_traps}, 'threshold') : ($self->{_conditions}, 'required');
    my @var_list = ();
    for my $rule ( @{ $rules } ) {
        foreach my $cond ( @{ General::getAsArrayRef( data => $rule, tag => $tag ) }) {

            push @graph_params, (
                                    draw   => {
                                        type => 'line',
                                        dsname => $cond->{var} . "_" . $rule->{time_laps},
                                        color => $cond->{color},
                                        legend => sprintf( "%-25s", $cond->{var} . ($rule->{percent} ? " (%)" : "") .
                                                                    ( $args{op} eq "remove" ? " prevision" : "" ).
                                                                    " (mean on " . $rule->{time_laps} . "s)" ),
                                      },
          
                                      hrule => {
                                           value => $cond->{min} || $cond->{max},
                                         color => '#' . $cond->{color},
                                        #legend => $cond->{var}
                                       },
                                      
                                );
        }
    }

    # Draw the graph in a PNG image
    $rrd->graph( @graph_params );
    
    return "$graph_dir/$graph_filename";
}


=head2 run
    
    Class : Public
    
    Desc : Do the job (check mc state and manage clusters) every time_step (configuration)
    
=cut

sub run {
    my $self = shift;
    my $running = shift;
    # Load conf
    my $conf = XMLin("/opt/kanopya/conf/orchestrator.conf");
    $self->{_time_step} = $conf->{time_step};
        
    $self->{_admin}->addMessage(from => 'Orchestrator', level => 'info', content => "Kanopya Orchestrator started.");
    
    while ( $$running ) {

        my $start_time = time();

        $self->manage_aggregates();

        my $update_duration = time() - $start_time;
        $log->info( "Manage duration : $update_duration seconds" );
        if ( $update_duration > $self->{_time_step} ) {
            $log->warn("graphing duration > graphing time step (conf)");
        } else {
            sleep( $self->{_time_step} - $update_duration );
        }

    }
    
    $self->{_admin}->addMessage(from => 'Orchestrator', level => 'warning', content => "Kanopya Orchestrator stopped");
}

sub new_old {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    # Load conf
    my $conf = XMLin("/opt/kanopya/conf/orchestrator.conf");
    $self->{_time_step} = $conf->{time_step};
    $self->{_traps} = General::getAsArrayRef( data => $conf->{add_rules}, tag => 'traps' );
    $self->{_conditions} = General::getAsArrayRef( data => $conf->{delete_rules}, tag => 'conditions' );
    
    $self->{_rrd_base_dir} = $conf->{rrd_base_dir} || '/tmp/orchestrator';
    $self->{_graph_dir} = $conf->{graph_dir} || '/tmp/orchestrator';
    
    # Create orchestrator dirs if needed
    for my $dir_path ( ($self->{_graph_dir}, $self->{_rrd_base_dir}) ) { 
        my @dir_path = split '/', $dir_path;
        my $dir = substr($dir_path, 0, 1) eq '/' ? "/" : "";
        while (scalar @dir_path) {
            $dir .= (shift @dir_path) . "/";
            mkdir $dir;
        }
    }
    
    # Get Administrator
    my ($login, $password) = ($conf->{user}{name}, $conf->{user}{password});
    Administrator::authenticate( login => $login, password => $password );
    $self->{_admin} = Administrator->new();
    $self->{_monitor} = Monitor::Retriever->new( );
    
    return $self;
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
