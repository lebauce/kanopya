#    BillingManager.pm - Manage billing of users
#
#    Copyright © 2012 Hedera Technology SAS
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

package BillingManager;

use strict;
use warnings;

use Kanopya::Exceptions;
use General;
use Entity::User;
use Entity::ServiceProvider::Cluster;
use Entity::Billinglimit;
use Retriever;

use List::Util qw[min max];
use Set::IntervalTree;
use Text::CSV;

use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("");


my $EVERY_DAY = 1;
my $EVERY_MONTH = 2;


sub userBilling {
    my ($user, $from, $to) = @_;

    my @clusters = Entity::ServiceProvider::Cluster->search(
                       hash => { user_id => $user->id }
                   );

    for my $cluster (@clusters) {
        eval {
            clusterBilling($user, $cluster, $from, $to);
        };
        if ($@) {
            $log->warn("Failed to generate billing for " . $cluster->cluster_name . "\n" . $@);
        }
    }
};

sub clusterBilling {
    my ($user, $cluster, $from, $to, $nofile) = @_;
    my $return;

    my %metrics;
    my %data;
    my $interval = 5 * 60;
    my $duration = 60 * 60;
    my $cluster_name = $cluster->getAttr(name => "cluster_name");
    my $timestamp = $from->epoch();

    # Get all the limit types for this cluster
    my @cluster_limits = $cluster->searchRelated(filters => [ 'billinglimits' ]);

    # TODO: Support distinct in BaseDB
#    $adm->{db}->resultset("Billinglimit")->search(
#                          { service_provider_id => $cluster->id },
#                          { columns => [ qw/type/ ], distinct => 1 }
#                      );

    # TODO: Can we remove this ?
    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    my $collector = $kanopya->getComponent(name => 'Kanopyacollector');

    LIMIT_TYPE:
    for my $limit_type (@cluster_limits) {
        my $metric = $limit_type->type;
        if (defined $metrics{$metric}) {
            next LIMIT_TYPE;
        }

        my %data = Retriever->getData(rrd_name     => "billing_raw",
                                      start        => $from->epoch(),
                                      end          => $to->epoch(),
                                      raw          => 1,
                                      max_def      => undef,
                                      rrd_base_dir => $collector->rrd_base_directory);

        $metrics{$metric} = {
            data   => $data{$metric},
            tree   => Set::IntervalTree->new,
            limits => {}
        };
    }

    # Get all the billing limits for a service provider
    # and add them to the interval set
    my %limits;
    for my $limit (@cluster_limits) {
        my $start = $limit->getAttr(name => "start") / 1000;
        my $end = $limit->getAttr(name => "ending") / 1000;
        my $type = $limit->getAttr(name => "type");
        my $tree = $metrics{$type}->{tree};
        my $repeat = $limit->getAttr(name => "repeats");

        if ($repeat eq $EVERY_DAY) {
            my $repeat_start_time = $limit->getAttr(name => "repeat_start_time");
            $repeat_start_time = (split(' ', (localtime($repeat_start_time / 1000))))[3];
            my $repeat_end_time = $limit->getAttr(name => "repeat_end_time");
            $repeat_end_time = (split(' ', (localtime($repeat_end_time / 1000))))[3];
            my $day = int($from->epoch / (24 * 60 * 60)) * (24 * 60 * 60);

            my @repeat_start_time = split(':', "$repeat_start_time");
            my ($start_hour, $start_minute, $start_second) = @repeat_start_time;

            my @repeat_end_time = split(':', "$repeat_end_time");
            my ($end_hour, $end_minute, $end_second) = @repeat_end_time;

            while (($day < $to->epoch) && ($day < $end)) {
                my $start_offset = min($end, $day + ($start_hour * 3600) + ($start_minute * 60) + $start_second);
                my $end_offset = min($end, $day + ($end_hour * 3600) + ($end_minute * 60) + $end_second);

                $tree->insert($limit->id,
                              $start_offset,
                              $end_offset);

                $day += 24 * 60 * 60;
            }
        }
        else {
            $tree->insert($limit->id,
                          $start, $end);
        }

        $metrics{$type}->{limits}->{$limit->id} = $limit->toJSON();
    }

    my $csv = Text::CSV->new ( { binary => 0, eol => "\n", sep_char => ";" } );
    my $filename = "user-" . $user->id .
                   "-" . $cluster_name . ".csv";

    my $fh;
    if ($nofile) {
        open $fh, ">:encoding(utf8)", \$return or die;
    }
    else {
        open $fh, ">:encoding(utf8)", $filename or die "$filename: $!";
    }

    while ($timestamp < $to->epoch) {
        my $values = [];
        my $row = [ $timestamp ];

        for my $metric (keys %metrics) {
            my $data = $metrics{$metric}->{data};
            my $measure = shift @$data;
            my $tree = $metrics{$metric}->{tree};
            my $limits = $metrics{$metric}->{limits};

            push @$row, $measure;

            # Get all the limits that apply at this timestamp
            my $results = $tree->fetch($timestamp, $timestamp);

            if (! scalar @$results) {
                $log->warn("No billing information at $timestamp on cluster " .
                           $cluster->getAttr(name => "cluster_name"));

                next;
            }

            # We get the limit with the lowest value
            my @results = @$results;
            my $max = $limits->{shift @$results};
            for my $id (@$results) {
                my $limit = $limits->{$id};
                if ($limit->{value} > $max->{value}) {
                    $max = $limit;
                }
                push @$row, $limit->{value};
            }

            # Get the limit value
            my $contract = $max->{value};
            push @$row, $contract;

            # Compute the overcommit
            my $overcommit = max(0, $measure - $contract);
            push @$row, $overcommit;
        }

        # Output the row to the CSV file
        $csv->print ($fh, $row);

        $timestamp += $interval;
    }

    close $fh or die "$filename: $!";
    if ($return) {
        return $return;
    }
}

1;
