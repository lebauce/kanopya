# Actuator.pm - Manage action plan to reach a target infrastructure configuration (local and architectural)

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

package Actuator;

use strict;
use warnings;
use Kanopya::Exceptions;
use General;
use Monitor::Retriever;
use Log::Log4perl "get_logger";


my $log = get_logger("orchestrator");

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {};
    bless $self, $class;
    
#    $self->_authenticate();
#    $self->init();
        
    $self->{_monitor} = Monitor::Retriever->new( );
        
    return $self;
}

=head2 changeClusterConf
    
    Class : Public
    
    Desc :  Build action plan to reach target configuration for a cluster
            A configuration is defined by a conf struct : { nb_nodes => int, mpl => int }
     
    Args :  current_conf : conf struct representing current cluster configuration
            target_conf  : conf struct representing target configuration for the cluster
            cluster      : kanoya cluster object

=cut

sub changeClusterConf {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['current_conf', 'target_conf', 'cluster']);
    
    # Manage scale out
    my $node_count_diff = $args{target_conf}{nb_nodes} - $args{current_conf}{nb_nodes};

    
    $log->debug("===> " . ($node_count_diff < 0 ? "" : "+") . "$node_count_diff node in cluster");
    
    if ($node_count_diff > 0) {
        $self->requireAddNode( cluster => $args{cluster} );
    } elsif ($node_count_diff < 0) {
        $self->requireRemoveNode( cluster => $args{cluster} );
    }
    
    # we return the diff for unit test purpose
    return $node_count_diff;
}

=head2 changeInfraConf
    
    Class : Public
    
    Desc :  Build action plan to reach target configuration for a infrastructure
            A configuration is defined by a conf struct : { nb_nodes => int, mpl => int }
     
    Args :  infra : array ref of cluster and their current configuration: 
                    [   {   cluster => Cluster ref,
                            conf => { nb_nodes => xxx, mpl => xxx }
                        },
                        {...},
                    ]
            target_conf  : conf struct representing target configuration for the infra:
                    { 
                        AC => array ref of nb nodes for each tiers,
                        LC => array ref of mpl for each tiers
                    }
=cut

# TODO This method signature should be changed to handle infra in a better way
# TODO Maybe this method must be a method of Infrastructure package
sub changeInfraConf {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['infra', 'target_conf']);
    
    # Currently assuming 1 tier = 1 cluster
    die "## ASSERT difference between number of cluster for current infra and target conf" if (scalar @{$args{infra}} != scalar @{ $args{target_conf}{AC} });
    
    my $infra = $args{infra};
    for my $tier_idx (0..(@$infra - 1)) {
        $self->changeClusterConf(   
                                    cluster => $infra->[$tier_idx]{cluster},
                                    current_conf => $infra->[$tier_idx]{conf},
                                    target_conf =>  { 
                                                        nb_nodes => $args{target_conf}{AC}[$tier_idx],
                                                        mpl => $args{target_conf}{LC}[$tier_idx],
                                                    }
                                );
    }
}

sub requireAddNode { 
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    $log->info("Node required in cluster '$cluster'");
    
    eval {
        if ( $self->_canAddNode( cluster => $cluster ) ) {
            $log->info("====> add node in $args{cluster}");
            $cluster->addNode( );
            #$self->addNode( cluster_name => $cluster );
#            $self->_storeTime( time => time(), cluster => $cluster, op_type => "add", op_info => "ok" );
        } else {
#            $self->_storeTime( time => time(), cluster => $cluster, op_type => "add", op_info => "req" );
        }
    };
    if ($@) {
        my $error = $@;
        $log->error("=> Error while adding node in cluster '$cluster' : $error");
    }
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
    
    my $cluster = $args{cluster};
    
    # Check if no node of the cluster is migrating  
    if ( $self->_isNodeMigrating( cluster => $cluster ) ) {
        $log->info(" => A node in this cluster is currently migrating");
        return 0;
    } 
   
    return 1;
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
    
    my $cluster = $args{cluster};
    
    # Check if no node of the cluster is migrating  
    if ( $self->_isNodeMigrating( cluster => $cluster ) ) {
        $log->info(" => A node in this cluster is currently migrating");
        return 0;
    }
    
    return 1;
}

sub requireRemoveNode { 
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    $log->info("Want remove node in cluster '$cluster'");
    
    eval {
           if ( $self->_canRemoveNode( cluster => $cluster ) ) {
            $self->removeNode( cluster => $cluster );
#            $self->_storeTime( time => time(), cluster => $cluster, op_type => "remove", op_info => "ok");
           } else {
#               $self->_storeTime( time => time(), cluster => $cluster, op_type => "remove", op_info => "req");
           }
    };
       if ($@) {
        my $error = $@;
        $log->error("=> Error while removing node in cluster '$cluster' : $error");
    }
    
}

sub removeNode {
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    my $cluster_name = $cluster->getAttr(name => 'cluster_name');
    
    $log->info("====> remove node from $cluster_name");
    
    #TODO Find the best node to remove (notation system)
    my $monitor = $self->{_monitor};
    my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster_name );
    my @up_nodes = grep { $_->{state} =~ 'up' } values %$cluster_info;
  
    my $master_node_ip = $cluster->getMasterNodeIp();
    
    my $node_to_remove = shift @up_nodes;
    ($node_to_remove = shift @up_nodes) if ($node_to_remove->{ip} eq $master_node_ip);
    die "No up node to remove in cluster '$cluster_name'." if ( not defined $node_to_remove );
    
    # TODO keep the motherboard ID and get it with this id! (ip can be not unique)
    my @mb_res = Entity::Motherboard->getMotherboardFromIP( ipv4_internal_ip => $node_to_remove->{ip} );
    die "Several motherboards with ip '$node_to_remove->{ip}', can not determine the wanted one" if (1 < @mb_res); # this die must desappear when we'll get mb by id
    my $mb_to_remove = shift @mb_res;
    die "motherboard '$node_to_remove->{ip}' no more in DB" if (not defined $mb_to_remove);
    
    ############################################
    # Enqueue the remove motherboard operation
    ############################################
    $cluster->removeNode( motherboard_id => $mb_to_remove->getAttr(name => 'motherboard_id') );
}

# TODO cluster method
sub _isNodeMigrating {
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    my $motherboards = $cluster->getMotherboards();
    for my $mb (values %$motherboards) {
        my ($state, $timestamp) = $mb->getNodeState();
        if ($state ne "in" and $state ne "broken") {
            return 1;
        }
    }    
    
    return 0;
}

1;