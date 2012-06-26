# Snmpd5.pm - Kanopya-collector component (Adminstrator side)
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
# Created 20 april 2012

=head1 NAME

<Entity::Component::Kanopya-collector> <Kanopya collector component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Kanopya-collector> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Kanopya-collector>;

my $component_instance_id = 2; # component instance id

Entity::Component::Kanopya-collector->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Kanopya-collector->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Kanopya-collector is class allowing to instantiate an Snmpd component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Kanopyacollector1;
use base "Entity::Component";
use base "Manager::CollectorManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Monitor::Retriever;
use Indicator;
use Indicatorset;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

#Collect every hour, stock data during 24 hours

use constant ATTR_DEF => {
    kanopyacollector1_collect_frequency => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    kanopyacollector1_storage_time => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 retrieveData

    Desc: Call kanopya native monitoring API to retrieve indicators data 
    return \%monitored_values;

=cut

sub retrieveData {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'nodelist', 'time_span', 'indicators' ]);

    my $nodelist       = $args{'nodelist'};
    my $indicators     = $args{'indicators'};
    my @sets_to_fetch;
   
    foreach my $indicator (values %$indicators) {
        # We fetch the indicator set related to the indicator
        my $set       = $indicator->indicatorset->indicatorset_name;
        
        # Then we check if it was already inserted into the array of sets to fetch
        my %sets = map { $_ => 1 } @sets_to_fetch;
        if (! exists($sets{$set})) {
            push @sets_to_fetch, $set;
        }
    }

    # Now we fetch the requested RRD
    my $retriever = Monitor::Retriever->new();
    my %monitored_values;   

    foreach my $set (@sets_to_fetch) {
        foreach my $node (@$nodelist) {
            my $rrd = $set . '_' . $node;
            eval {
                my %data = $retriever->getData(rrd_name  => $rrd,
                                               time_laps => $args{time_span});
                $monitored_values{$node} = \%data;
            };
            if ($@) {
                $log->warn("Error while retrieving data for RRD '$rrd'");
            }
        }
    }

    # my $monitored_values = {
    #     'tge1' => {
    #         '.1.3.6.1.4.1.2021.4.5.0' => '12.34',
    #         '.1.3.6.1.4.1.2021.4.6.0'   => '43.21', 
    #     },
    #     'tge2' => {
    #         '.1.3.6.1.4.1.2021.4.5.0' => '111111',
    #         '.1.3.6.1.4.1.2021.4.6.0'   => '222222', 
    #     },
    # };

    return \%monitored_values;
}


=head2 getIndicators

    Desc: call collector manager to retrieve indicators available for the service provider 
    return \@indicators;

=cut

sub getIndicators {
    my ($self, %args) = @_;

    return Indicator->search(hash => {});
}

=head2 getCollectorType

    Desc: Usefull to give information about this component 
    return 'Native Kanopya collector tool';

=cut

sub getCollectorType {
    return 'Native Kanopya collector tool';
}

1;
