# EternalCluster.pm - This object allows to manipulate external cluster configuration
#    Copyright 2011 Hedera Technology SAS
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
# Created 3 july 2010
package Entity::ServiceProvider::Outside::Externalcluster;
use base 'Entity::ServiceProvider::Outside';

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use General;

use Clustermetric;
use AggregateCombination;
use AggregateCondition;
use AggregateRule;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;
use constant ATTR_DEF => {
    externalcluster_name    =>  {pattern        => '^\w*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    externalcluster_desc    =>  {pattern        => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    externalcluster_state   => {pattern         => '^up:\d*|down:\d*|starting:\d*|stopping:\d*$',
                                is_mandatory    => 0,
                                is_extended     => 0,
                                is_editable        => 0},
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'create'    => {'description' => 'create a new cluster',
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this cluster',
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this cluster',
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this cluster',
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this cluster',
                        'perm_holder' => 'entity',
        },
    };
}



=head2 getState

=cut

sub getState {
    my $self = shift;
    my $state = $self->{_dbix}->get_column('cluster_state');
    return wantarray ? split(/:/, $state) : $state;
}

=head2 setState

=cut

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['state']);
    my $new_state = $args{state};
    my $current_state = $self->getState();
    $self->{_dbix}->update({'cluster_prev_state' => $current_state,
                            'cluster_state' => $new_state.":".time})->discard_changes();
}


sub addNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hostname']);

    $self->{_dbix}->parent->externalnodes->create({
        externalnode_hostname   => $args{hostname},
        externalnode_state      => 'up',
    });
}

sub getNodes {
    my $self = shift;
    my %args = @_;

    my $node_rs = $self->{_dbix}->parent->externalnodes;

    my @nodes;
    while (my $set = $node_rs->next) {
        push @nodes, {
            hostname    => $set->get_column('externalnode_hostname'),
            state       => $set->get_column('externalnode_state'),
        };
    }
    
    return \@nodes;
}

=head2 updateNodes

    Update external nodes list using the linked DirectoryService connector

=cut

sub updateNodes {
     my $self = shift;
     
     my $ds_connector = $self->getConnector( category => 'DirectoryService' );
     my $nodes = $ds_connector->getNodes();
     
     for my $node (@$nodes) {
         if (defined $node->{hostname}) {
            $self->{_dbix}->parent->externalnodes->update_or_create({externalnode_hostname => $node->{hostname}});
         }
     }
     # TODO remove dead nodes from db
}

=head2 getNodesMetrics

    Retrieve cluster nodes metrics values using the linked MonitoringService connector
    
    Params:
        indicators : array ref of indicator name (eg 'ObjectName/CounterName')
        time_span  : number of last seconds to consider when compute average on metric values
=cut

sub getNodesMetrics {
     my $self = shift;
     my %args = @_;

     General::checkParams(args => \%args, required => ['indicators', 'time_span']);
     
     my $ms_connector = $self->getConnector( category => 'MonitoringService' );
     my $nodes = $self->getNodes();
     
     my @hostnames = map { $_->{hostname} } @$nodes;
     
     my $data = $ms_connector->retrieveData(
        nodes => \@hostnames,
        %args,
     );
     
    return $data;
}

=head2 monitoringDefaultInit

    Insert some basic clustermetrics, combinations and rules for this cluster

    Use SCOM indicators by default
    TODO : more generic (unhardcode SCOM, metrics depend on monitoring service)

=cut

sub monitoringDefaultInit {
    my $self = shift;

    my $adm = Administrator->new();
    
    my $scom_indicatorset = $adm->{'manager'}{'monitor'}->getSetDesc( set_name => 'scom' ); 
    my @indicators;
    my @funcs = qw(mean max min standard_deviation);
    foreach my $indicator (@{$scom_indicatorset->{ds}}){
        push @indicators, $indicator->{id};
    }

   # Create one clustermetric for each indicator scom
    # Create 4 aggregates for each cluster metric
    # Create the corresponding combination 'identity function' for each aggregate 
    foreach my $indicator (@{$scom_indicatorset->{ds}}) {   
        foreach my $func (@funcs) {
            my $cm_params = {
                clustermetric_cluster_id               => $self->getAttr( name => 'outside_id' ),
                clustermetric_indicator_id             => $indicator->{id},
                clustermetric_statistics_function_name => $func,
                clustermetric_window_time              => '1200',
            };
            my $cm = Clustermetric->new(%$cm_params);
           
            my $acf_params = {
                aggregate_combination_formula   => 'id'.($cm->getAttr(name => 'clustermetric_id'))
            };
            my $aggregate_combination = AggregateCombination->new(%$acf_params);
               
               my $condition_params = {
                    aggregate_combination_id => $aggregate_combination->getAttr(name=>'aggregate_combination_id'),
                    comparator            => '>',
                    threshold             => '0',
                    state                 => 'enabled',
                    time_limit            =>  undef,
                };
               my $aggregate_condition = AggregateCondition->new(%$condition_params);
            
               my $params_rule = {
                    aggregate_rule_formula   => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
                    aggregate_rule_state     => 'enabled',
                    aggregate_rule_action_id => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
                };
                my $aggregate_rule = AggregateRule->new(%$params_rule);
            #}
        }
    }
    
    
    
    #Create example combination
    
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
        
        my $acf_params;
        
        $acf_params = {
          aggregate_combination_formula   => '(id'.($id_max).'- id'.($id_min).') / id'.($id_mean)
        };
        
        my $aggregate_combination_range_over_mean = AggregateCombination->new(%$acf_params);

        $acf_params = {
          aggregate_combination_formula   => '(id'.($id_max).'- id'.($id_min).') / id'.($id_std)
        };
        
        my $aggregate_combination_range_over_std = AggregateCombination->new(%$acf_params);


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
            time_limit            => undef,
        };
       my $aggregate_condition = AggregateCondition->new(%$condition_params);

       my $params_rule = {
            aggregate_rule_formula   => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
            aggregate_rule_state     => 'enabled',
            aggregate_rule_action_id => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
        };
        my $aggregate_rule = AggregateRule->new(%$params_rule);
       
       
    }
}

1;
