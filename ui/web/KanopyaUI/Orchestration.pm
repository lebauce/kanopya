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
package KanopyaUI::Orchestration;
use base 'KanopyaUI::CGI';

use Data::Dumper;
use Log::Log4perl "get_logger";
use XML::Simple;
use JSON;
        
my $log = get_logger("administrator");

sub getOrchestratorConf () {
    my $self = shift;
    
    my $conf = XMLin("/opt/kanopya/conf/orchestrator.conf");

    return $conf;
}

=head2 save_orchestrator_settings
    
    Class : Public
    
    Desc :     Called by client to save monitoring settings.
            Transform: query params (json) -> perl type (according to xml conf struct) -> xml (conf) 
    
=cut

sub save_orchestrator_settings : Runmode {
    my $self = shift;
    my $errors = shift;
    my $query = $self->query();
    
    my $cluster_id = $query->param('cluster_id') || 0;
    my $rules_str = $query->param('rules'); # stringified array of hash
    my $rules = decode_json $rules_str;
    
    my $optim_str = $query->param('optim_conditions'); # stringified array of hash
    my $optim_cond = decode_json $optim_str;
#    $log->error("param from rules json " . Dumper $rules);
#    $log->error("param from optim cond json " . Dumper $optim_cond);
    #return Dumper $rules;
    
    my $rules_manager = $self->{'adm'}->{manager}->{rules};
    eval {
        $rules_manager->deleteClusterRules( cluster_id => $cluster_id );
        foreach my $rule (@$rules) {
            $rules_manager->addClusterRule( cluster_id => $cluster_id,
                                            condition_tree => (ref $rule->{condition} eq 'ARRAY') ? $rule->{condition} : [$rule->{condition}],
                                            action => $self->actionTranslate( action => $rule->{action} )
                                            );
        }
        
        $rules_manager->deleteClusterOptimConditions( cluster_id => $cluster_id );
        $rules_manager->addClusterOptimConditions( cluster_id => $cluster_id, condition_tree => $optim_cond );
    };
    if ($@) {
        my $error = $@;
        return "Error while recording rule for cluster $cluster_id\n$error";
    }
    
    return "Rules saved for cluster $cluster_id ";
}

sub actionTranslate {
    my $self = shift;
    my %args = @_;
    
    my %map = ("add_node" => "Add node", "remove_node" => "Remove node");
    while ( my ($k, $v) = each ( %map ) ) {
        return $v if $k eq $args{action};
        return $k if $v eq $args{action};
    }
    return "none";
}

sub view_orchestrator_settings : StartRunmode {
    my $self = shift;
    my $errors = shift;
    my $query = $self->query();
    my $tmpl = $self->load_tmpl('Orchestrator/view_orchestrator_settings.tmpl');
    
    my $cluster_id = $query->param('cluster_id') || 0;

    # Build var choice list of all collected set
    my $sets = $self->{adm}->{manager}{monitor}->getCollectedSets( cluster_id => $cluster_id );
    my @choices = ();
    foreach my $set (@$sets) {
        push( @choices, map { "$set->{label}:" . $_->{label} } @{ $set->{ds} } );
    }
    my $var_choices = join ",", @choices;
    
    my @rules = ();
    my $rules_manager = $self->{'adm'}->{manager}->{rules};
    my $cluster_rules = $rules_manager->getClusterRules( cluster_id => $cluster_id );
    my $op_id = 0;
    foreach my $rule (@$cluster_rules) {
        my $condition_tree = $rule->{condition_tree};

        my @conditions = ();
        $op_id++;
        my $bin_op;
        foreach my $cond (@$condition_tree) {
            if ( ref $cond eq 'HASH' ) {
                push @conditions, { var => $cond->{var},
                                    time_laps => $cond->{time_laps},
                                    inf => $cond->{operator} eq 'inf',
                                    value => $cond->{value},
                                    var_choices => $var_choices,                    
                                    op_id => $op_id,
                                };
            } else {
                $bin_op = {'|' => 'or', '&' => 'and'}->{$cond};
            }
        }
        
        $conditions[0]{master_row} = 1;
        $conditions[0]{bin_op} = $bin_op if (defined $bin_op);
        $conditions[0]{action} = $self->actionTranslate( action => $rule->{action} );
        $conditions[0]{span} = scalar @conditions;
        
        push @rules, { conditions => \@conditions };
    }
    $tmpl->param('RULES' => \@rules);        
    
    my @optim_conditions = ();
    my $optim_condition_tree = $rules_manager->getClusterOptimConditions( cluster_id => $cluster_id );
    foreach my $cond (@$optim_condition_tree) {
            if ( ref $cond eq 'HASH' ) {
                push @optim_conditions, { var => $cond->{var},
                                    time_laps => $cond->{time_laps},
                                    inf => $cond->{operator} eq 'inf',
                                    value => $cond->{value},
                                    var_choices => $var_choices,                    
                                    op_id => 0,
                                };
            } else {
                #$bin_op = {'|' => 'or', '&' => 'and'}->{$cond};
            }
        }
    $tmpl->param('OPTIM_CONDITIONS' => \@optim_conditions);
    
    # SLA
    my $qos_constraints = $rules_manager->getClusterQoSConstraints( cluster_id => $cluster_id );
    $tmpl->param('QOS_CONSTRAINTS_LATENCY' => $qos_constraints->{max_latency});
    $tmpl->param('QOS_CONSTRAINTS_ABORT_RATE' => $qos_constraints->{max_abort_rate} * 100);

    # Model parameters
    my $workload_characteristic = $rules_manager->getClusterModelParameters( cluster_id => $cluster_id );
    $tmpl->param('WORKLOAD_VISIT_RATIO' => $workload_characteristic->{visit_ratio});
    $tmpl->param('WORKLOAD_SERVICE_TIME' => $workload_characteristic->{service_time} * 1000);
    $tmpl->param('WORKLOAD_DELAY' => $workload_characteristic->{delay} * 1000);
    $tmpl->param('WORKLOAD_THINK_TIME' => $workload_characteristic->{think_time} * 1000);
    
    
    
    $tmpl->param('VAR_CHOICES' => $var_choices);
    $tmpl->param('TITLEPAGE' => "Orchestrator settings");
    $tmpl->param('MCLUSTERS' => 1);
    $tmpl->param('SUBMCLUSTERS' => 1);
    
    return $tmpl->output();
}

sub view_controller_settings : Runmode {
    my $self = shift;
    my $errors = shift;
    my $query = $self->query();
    my $tmpl = $self->load_tmpl('Orchestrator/view_controller_settings.tmpl');
    
    my $cluster_id = $query->param('cluster_id') || 0;

    my $rules_manager = $self->{'adm'}->{manager}->{rules};
    
    # SLA
    my $qos_constraints = $rules_manager->getClusterQoSConstraints( cluster_id => $cluster_id );
    $tmpl->param('QOS_CONSTRAINTS_LATENCY' => $qos_constraints->{max_latency});
    $tmpl->param('QOS_CONSTRAINTS_ABORT_RATE' => $qos_constraints->{max_abort_rate} * 100);

    # Model parameters
    my $workload_characteristic = $rules_manager->getClusterModelParameters( cluster_id => $cluster_id );
    $tmpl->param('WORKLOAD_VISIT_RATIO' => $workload_characteristic->{visit_ratio});
    $tmpl->param('WORKLOAD_SERVICE_TIME' => $workload_characteristic->{service_time});
    $tmpl->param('WORKLOAD_DELAY' => $workload_characteristic->{delay});
    $tmpl->param('WORKLOAD_THINK_TIME' => $workload_characteristic->{think_time});

    $tmpl->param('TITLEPAGE' => "Controller settings");
    $tmpl->param('MCLUSTERS' => 1);
    $tmpl->param('SUBMCLUSTERS' => 1);
    
    return $tmpl->output();
}

sub view_controller : Runmode {
    my $self = shift;
    my $errors = shift;
    my $query = $self->query();
    my $tmpl = $self->load_tmpl('Orchestrator/view_controller.tmpl');
    $tmpl->param('titlepage' => "Cluster - Controller's activity");
    $tmpl->param('mClusters' => 1);
    $tmpl->param('submClusters' => 1);
    $tmpl->param('username' => $self->session->param('username'));
    $tmpl->param('CLUSTER_ID' => $query->param('cluster_id'));

    my $cluster_id = $query->param('cluster_id');
    my $graph_name_prefix = "cluster$cluster_id" .  "_controller_server_";

    $tmpl->param('GRAPHS' => [  { graph => "/graph/" . $graph_name_prefix . "load.png"},
                                { graph => "/graph/" . $graph_name_prefix . "latency.png"},
                                { graph => "/graph/" . $graph_name_prefix . "abortrate.png"},
                                { graph => "/graph/" . $graph_name_prefix . "throughput.png"},
                            ] );
                            
    return $tmpl->output();
}

sub save_controller_settings : Runmode {
    my $self = shift;
    my $errors = shift;
    my $query = $self->query();
    
    my $cluster_id = $query->param('cluster_id') || 0;
    
    
    my %parameters = (
    	visit_ratio => $query->param('visit_ratio'),		
		service_time => $query->param('service_time'),
		delay => $query->param('delay'),
		think_time => $query->param('think_time'), 
    );
        
    
    my $rules_manager = $self->{'adm'}->{manager}->{rules};
    eval {
        $rules_manager->setClusterModelParameters( cluster_id => $cluster_id, %parameters );
    };
    if ($@) {
        my $error = $@;
        return "Error while recording parameters for cluster $cluster_id\n$error";
    }
    
    return "parameters saved for cluster $cluster_id ";
}

1;
