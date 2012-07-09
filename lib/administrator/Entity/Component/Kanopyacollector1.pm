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
use Collect;
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

sub methods {
    return {
        'getIndicators' => { 'description' => 'create a new cluster',
                             'perm_holder' => 'entity',}
    },
}

=head2 retrieveData

    Desc: Call kanopya native monitoring API to retrieve indicators data

    Args:   (required) \%indicators, \@nodelist
            (required) $time_span OR $start, $end
            (optional) historical

    return \%monitored_values

=cut

sub retrieveData {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'nodelist', 'indicators' ]);

    if ((not defined $args{time_span}) && ((not defined $args{start}) || (not defined $args{end}))) {
        throw Kanopya::Exception::Internal::MissingParam(error => "Need param 'time_span' OR 'start', 'end'");
    }

    ####################################
    # WARNING time span hardcoded here!!
    ####################################
    my $time_span = 300;

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
            eval {
                my $data = $retriever->getHostData(
                                                set         => $set,
                                                host        => $node,
                                                time_laps   => $time_span,
                                                start       => $args{start},
                                                end         => $args{end},
                                                historical  => $args{historical},
                                                );
                $monitored_values{$node} = $monitored_values{$node} ? { %{$monitored_values{$node}}, %{$data} } :  $data;
            };
            if ($@) {
                $log->warn("Error while retrieving data from kanopya collector : $@");
            }
        }
    }

    my %res;
    while (my ($node_name, $set) = each %monitored_values) {
        foreach my $indicator_name (keys %$set) {
            my $indicator = (grep { $_->getAttr(name => "indicator_name") eq $indicator_name } values %$indicators)[0];
            next if not defined $indicator;
            $res{$node_name}{$indicator->getAttr(name => 'indicator_oid')} = $set->{$indicator_name};
        }
    }

    # Return values of the form :
    # {
    #     {hostname} => {
    #         {oid} => {value},
    #         ...
    #     }
    # }

    return \%res;
}


=head2 getIndicators

    Desc: call collector manager to retrieve indicators available for the service provider
    return \@indicators;

=cut

sub getIndicators {
    my ($self, %args) = @_;

    return Indicator->search(
        hash => { "indicatorset.indicatorset_provider" => 'SnmpProvider' }
    );
}

=head2 getIndicator

    Desc: Return the indicator with the specified id
    Args: indicator id
    Return an indicator instance

=cut

sub getIndicator {
    my ($self, %args) = @_; 

    General::checkParams(args => \%args, required => ['id']);

    return Indicator->get(id => $args{id});
}

=head2 collectIndicator

    Desc: Start collecting the specified indicator

=cut

sub collectIndicator {
    my ($self, %args) = @_;

    my $indicator = Indicator->get(id => $args{indicator_id});

    eval {
        my $adm = Administrator->new();
        $adm->{db}->resultset('Collect')->create({
            cluster_id      => $args{service_provider_id},
            indicatorset_id => $indicator->indicatorset_id
        });
    };
}

=head2 getCollectorType

    Desc: Usefull to give information about this component
    return 'Native Kanopya collector tool';

=cut

sub getCollectorType {
    return 'Native Kanopya collector tool';
}

1;
