# MonitorManager.pm - Object class of Monitor Manager included in Administrator

#    Copyright © 2011-2012 Hedera Technology SAS
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
# Created 2 december 2010
package MonitorManager;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use General;

my $log = get_logger("administrator");
my $errmsg;

=head2 MonitorManager::new (%args)
    
    Class : Public
    
    Desc : Instanciate Monitor Manager object
    
    args: 
        shemas : DBIx:Schema : Database schemas

    return: MonitorManager instance
    
=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    
    General::checkParams(args => \%args, required => ['schemas']);
    
    $self->{db} = $args{schemas};
    
    bless $self, $class;
    $log->info("New Monitor Manager Loaded");
    return $self;
}


=head2 getIndicatorSets

    Class : Public
    
    Desc : Retrieve detailed sets description (including indicators desc for each set)
    
    Args :
        (optional) search: array ref: dbix search parameters to select a subset of indicatos sets. If undef then retrieve all 
    
    Return : array ref of set description
    
=cut
    

sub getIndicatorSets {
    my $self = shift;
    my %args = @_;
    
    my $search = $args{search};

    my $indicatorset_rs = $self->{db}->resultset('Indicatorset')->search( @$search );
    my @sets = ();
    while (my $set = $indicatorset_rs->next) {
        
        my $indicator_rs = $self->{db}->resultset('Indicator')->search( { 'indicatorset_id' => $set->get_column('indicatorset_id') });
        my @indicators = ();
        while (my $indicator = $indicator_rs->next) {
            push @indicators, {
                'id' => $indicator->get_column( 'indicator_id' ),
                'label' => $indicator->get_column( 'indicator_name' ),
                'oid' => $indicator->get_column( 'indicator_oid' ),
                'min' => $indicator->get_column( 'indicator_min' ),
                'max' => $indicator->get_column( 'indicator_max' ),
                'color' => $indicator->get_column( 'indicator_color' ),
                'unit' => $indicator->get_column( 'indicator_unit' ),
            };
        }
        
        push @sets, {   'label' => $set->get_column( 'indicatorset_name' ),
                        'ds_type' => $set->get_column( 'indicatorset_type' ),
                        'data_provider' => $set->get_column( 'indicatorset_provider' ),
                        'component' => $set->get_column( 'indicatorset_component' ),
                        'max' => $set->get_column( 'indicatorset_max' ),
                        'table_oid' => $set->get_column( 'indicatorset_tableoid' ),
                        'ds' => \@indicators
                    };    
    }
    
    return \@sets;
}

=head2 getCollectedSets
    
    Class : Public
    
    Desc : Retrieve sets description (including indicators desc for each set) to collect for a cluster
    
    Args :    cluster_id
    
    Return : array ref of set description
    
=cut

sub getCollectedSets {
    my $self = shift;
    my %args = @_;
    
    
    
    return $self->getIndicatorSets( search => [{ 'collects.cluster_id' => $args{cluster_id} },  { join => ['collects'] }] );
}

sub getSetDesc {
    my $self = shift;
    my %args = @_;
    
    
    my $set = $self->getIndicatorSets( search => [{ 'indicatorset_name' => $args{set_name} }] );
     
    die "getSetDesc: Undefined set name : '$args{set_name}'" if ( 0 == @$set );
    
    return shift @$set;
}


=head2 collectSet
    
    Class : Public
    
    Desc : add a indicator set to collect for a cluster
    
    Args :
        cluster_id
        set_name
    
    Return :
    
=cut

sub collectSet {
    my $self = shift;
    my %args = @_;    
    
    my $set = $self->{db}->resultset('Indicatorset')->search( { indicatorset_name => $args{set_name} } )->first;
    if (defined $set) {
        $set->create_related( 'collects', { cluster_id => $args{cluster_id} } );
    }
}

=head2 collectSets
    
    Class : Public
    
    Desc : collect sets for a cluster
    
    Args : 
        cluster_id
        sets_name: array ref of set name
    
=cut

sub collectSets {
    my $self = shift;
    my %args = @_;    
    
#    $log->error("collected Sets : " . Dumper $args{sets_name});
    
    $self->deleteCollect( cluster_id => $args{cluster_id} );
    for my $set_name (@{ $args{sets_name} }) {
        $self->collectSet( cluster_id => $args{cluster_id}, set_name => $set_name );
    }
}

sub setAllCollectSets {
    my $self = shift;
    my %args = @_;
    
    $self->collectSets(cluster_id => $args{cluster_id},
                       sets_name => ["mem","cpu","apache_stats"]);
}

=head2 deleteCollect
    
    Class : Public
    
    Desc : delete collect conf for a cluster 
    
    Args : cluster_id
    
=cut

sub deleteCollect {
    my $self = shift;
    my %args = @_;    
    
    my $collect = $self->{db}->resultset('Collect')->search( { cluster_id => $args{cluster_id} } );
    $collect->delete;
}


=head2 graphSettings
    
    Class : Public
    
    Desc : graph settings for a cluster
    
    Args : 
        cluster_id
        graphs: array ref of hash ref representing graph options

=cut

sub graphSettings {
    my $self = shift;
    my %args = @_;    
    
    # delete old settings
    my $graph_rs = $self->{db}->resultset('Graph')->search( { cluster_id => $args{cluster_id} } );
    $graph_rs->delete;
    
    
    # store new settings
    for my $graph (@{ $args{graphs} }) {
        my $set = $self->{db}->resultset('Indicatorset')->search( { indicatorset_name => $graph->{set_label} } )->first;
        $set->create_related( 'graphs', {     cluster_id => $args{cluster_id},
                                            graph_type => $graph->{graph_type},
                                            graph_indicators => $graph->{ds_label},
                                            graph_percent => ($graph->{percent} eq 'yes') ? 1 : 0,
                                            graph_sum => ($graph->{with_total} eq 'yes') ? 1 : 0,
                                        } 
                            );
    }
}

=head2 getGraphSettings
    
    Class : Public
    
    Desc : Retrieve graph settings for one set of a cluster
    
    Args :
        cluster_id
        set_name
            
    Return : hash ref of graph settings
    
=cut

sub getGraphSettings {
    my $self = shift;
    my %args = @_;
    
    my $graph_row = $self->{db}->resultset('Indicatorset')->search( { indicatorset_name => $args{set_name} }
                                                     )->search_related('graphs'
                                                     )->search( { cluster_id => $args{cluster_id} } 
                                                     )->first;
    
    return (defined $graph_row) ? $self->_graphHash( row => $graph_row ) : undef;

}

sub getClusterGraphSettings {
    my $self = shift;
    my %args = @_;
    
    my $graph_rs = $self->{db}->resultset('Graph')->search( { cluster_id => $args{cluster_id} } );
    
    my @graphs = ();
    while (my $graph_row = $graph_rs->next) {
        push @graphs, $self->_graphHash( row => $graph_row );
    }
    
    return \@graphs;
}

sub getSetIdFromName{
    my $self = shift;
    my %args = @_;
    
    my $resultSet = $self->{db}->resultset('Indicatorset')->search( { indicatorset_name => $args{set_name}} );
    my $indicatorset_id = $resultSet->first->get_column('indicatorset_id'); #UNIQUE
    return $indicatorset_id;
}
sub _graphHash {
    my $self = shift;
    my %args = @_;
    
    my $graph_row = $args{row};
    
    return     { 
                set_label => $graph_row->indicatorset->get_column('indicatorset_name'),
                graph_type => $graph_row->get_column('graph_type'),
                ds_label => $graph_row->get_column('graph_indicators'),
                percent => ($graph_row->get_column('graph_percent') == 1) ? 'yes' : 'no',
                with_total => ($graph_row->get_column('graph_sum') == 1) ? 'yes' : 'no',
            }
}

1;