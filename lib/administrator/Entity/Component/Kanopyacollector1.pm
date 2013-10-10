#    Copyright © 2013 Hedera Technology SAS
#
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


=pod
=begin classdoc

Use Kanopya to collect monitoring data

=end classdoc
=cut

package Entity::Component::Kanopyacollector1;
use base "Entity::Component";
use base "Manager::CollectorManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Indicator;
use Entity::CollectorIndicator;
use Indicatorset;
use Collect;
use Retriever;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use TryCatch;
my $err;

use constant ATTR_DEF => {
    time_step => {
        label        => 'Monitoring data retrieval frequency',
        type         => 'time',
        pattern      => '^\d+$',
        default      => 300,
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    storage_duration => {
        label        => 'Data storage duration',
        type         => 'time',
        pattern      => '^\d+$',
        default      => 86400,
        is_mandatory => 1,
        is_extended  => 0
    },
    rrd_base_directory => {
        label        => 'RRD base directory',
        type         => 'string',
        pattern      => '^.*$',
        default      => '/var/cache/kanopya/monitor/base',
        is_mandatory => 1,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    my @indicator_sets = (
        Indicatorset->search(
            hash => {
                indicatorset_name => [
                    'mem', 'cpu', 'apache_stats', 'apache_workers', 'billing',
                    'diskIOTable', 'interfaces', 'vsphere_vm', 'vsphere_host',
                    'state', 'virtualization',
                ]
            }
        )
    );

    $self->createCollectorIndicators(
        indicator_sets => \@indicator_sets,
    );

    return $self;
}

=pod
=begin classdoc

Call kanopya native monitoring API to retrieve indicators data

@param indicators
@param nodelist
@param time_span OR start, end
@optional time_span OR start and end Target time interval

@return hash ref { hostname => {oid => value,...}, ... }

=end classdoc
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
    my $time_span = 600;

    my $nodelist   = $args{'nodelist'};
    my $indicators = $args{'indicators'};
    my %sets_to_fetch;

    # Arrange indicators name by set_name
    foreach my $indicator (values %$indicators) {
        # We fetch the indicator set related to the indicator
        # my $set_name = $indicator->indicatorset->indicatorset_name;
        my $set_id = $indicator->indicatorset->id;
        push @{$sets_to_fetch{$set_id}}, $indicator->indicator_name;
    }

    # Now we fetch the requested data
    my %monitored_values;

    while (my ($set_id, $indic_names) = each %sets_to_fetch) {
        foreach my $node (@$nodelist) {
            try {
                #TODO avoir this useless reinstanciation with a hashtable
                my $indicator_set = Indicatorset->get(id => $set_id);
                #TODO Improve lastValue / average management
                my $last_value = $indicator_set->indicatorset_provider eq 'KanopyaDatabaseProvider'
                                     ? 1 : undef;

                my $data = Retriever->getHostData(
                               set          => $indicator_set->indicatorset_name,
                               host         => $node,
                               required_ds  => $indic_names,
                               time_laps    => $time_span,
                               start        => $args{start},
                               end          => $args{end},
                               historical   => $args{historical},
                               raw          => $args{raw},
                               last_value   => $args{last_value} || $last_value,
                               rrd_base_dir => $self->rrd_base_directory
                           );

                $monitored_values{$node} = $monitored_values{$node}
                                               ? { %{$monitored_values{$node}}, %{$data} } : $data;
            }
            catch ($err) {
                $log->warn("Error while retrieving data from kanopya collector : $err");
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


=pod
=begin classdoc

Call collector manager to retrieve indicators available for the service provider

@return Array ref of Indicator instances

=end classdoc
=cut

sub getIndicators {
    my ($self, %args) = @_;

    return Entity::Indicator->search(
        hash => { "indicatorset.indicatorset_provider" => 'SnmpProvider' }
    );
}


=pod
=begin classdoc

Return the indicator with the specified id

@param id Indicator id

@return Indicator instance

=end classdoc
=cut

sub getIndicator {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['id']);

    return Entity::Indicator->get(id => $args{id});
}


=pod
=begin classdoc

Start collecting the specified indicator

=end classdoc
=cut

sub collectIndicator {
    my ($self, %args) = @_;

    my $collector_indicator = Entity::CollectorIndicator->get(id => $args{indicator_id});
    my $indicator = $collector_indicator->indicator;

    try {
        Collect->new(
            service_provider_id => $args{service_provider_id},
            indicatorset_id     => $indicator->indicatorset_id
        );
    }
    catch (Kanopya::Exception::DB $err) {
        $log->warn("Collect <$args{service_provider_id}-" . $indicator->indicatorset_id .  "> already exists.");
    }
}


=pod
=begin classdoc

Start collecting indicators of the specified sets
Do not check if wanted set to collect contains available indicators for the service provider
(i.e CollectorIndicators)

@param sets_name array ref of set name
@param service_provider_id

=end classdoc
=cut

sub collectSets {
    my ($self, %args) = @_;

    my @indicator_sets = Indicatorset->search(
        hash => {
            indicatorset_name => $args{sets_name}
        }
    );

    for my $indicator_set (@indicator_sets) {
        try {
            Collect->new(
                service_provider_id => $args{service_provider_id},
                indicatorset_id     => $indicator_set->id
            );
        }
        catch ($err) {
            $log->info($err);
        }
    }
}


=pod
=begin classdoc

Usefull to give information about this component
@return Native Kanopya collector tool

=end classdoc
=cut

sub getCollectorType {
    return 'Native Kanopya collector tool';
}

1;
