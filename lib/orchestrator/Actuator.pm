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
use Log::Log4perl "get_logger";

my $log = get_logger("orchestrator");

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {};
    bless $self, $class;
    
#    $self->_authenticate();
#    $self->init();
    
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

1;