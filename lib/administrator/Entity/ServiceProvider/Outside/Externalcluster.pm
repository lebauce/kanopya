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

    $self->{_dbix}->parent->externalnodes->create({externalnode_hostname => $args{hostname}});
}

sub getNodes {
    my $self = shift;
    my %args = @_;

    my $node_rs = $self->{_dbix}->parent->externalnodes;

    my @nodes;
    while (my $set = $node_rs->next) {
        push @nodes, {
            hostname => $set->get_column('externalnode_hostname'),
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

1;
