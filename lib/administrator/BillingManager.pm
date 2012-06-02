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

use Log::Log4perl "get_logger";
use Data::Dumper;
use Monitor::Retriever;
use Set::IntervalTree;
use Text::CSV;

use Kanopya::Exceptions;
use General;
use List::Util qw[min max];
use Entity::User;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Billinglimit;
use Monitor::Retriever;

my $log = get_logger("administrator");

my $retriever = Monitor::Retriever->new;

sub userBilling {
    my ($user, $from, $to) = @_;

    my @clusters = Entity::ServiceProvider::Inside::Cluster->search(
                       hash => { user_id => $user->getId }
                   );

    for my $cluster (@clusters) {
        clusterBilling($user, $cluster, $from, $to);
    }
};

sub clusterBilling {
    my ($user, $cluster, $from, $to) = @_;

    my %metrics;
    my %data;
    my $interval = 5 * 60;
    my $cluster_name = $cluster->getAttr(name => "cluster_name");
    my $adm = Administrator->new();
    my $timestamp = $from->epoch();

    # Get all the limit types for this cluster
    my @limit_types = $adm->{db}->resultset("Billinglimit")->search(
                          { service_provider_id => $cluster->getId },
                          { columns => [ qw/type/ ],
                            distinct => 1, }
                      );

    for my $limit_type (@limit_types) {
        my $metric = $limit_type->get_column("type");

        my $data = $retriever->getClusterData(
                       cluster     => $cluster_name,
                       set         => $metric,
                       time_laps   => [ $from, $to ],
                       aggregation => "raw",
                       required_ds => [ $metric ],
                   )->{'Nice'};

        $metrics{$metric} = {
            data   => $data,
            tree   => Set::IntervalTree->new,
            limits => {}
        };
    }

    # Get all the billing limits for a service provider
    # and add them to the interval set
    my %limits;
    my @cluster_limits = Entity::Billinglimit->search(hash => {
                             service_provider_id => $cluster->getId
                         });

    for my $limit (@cluster_limits) {
        my $type = $limit->getAttr(name => "type");
        my $tree = $metrics{$type}->{tree};

        $tree->insert($limit->getId,
                      $limit->getAttr(name => "start"),
                      $limit->getAttr(name => "end"));

        $metrics{$type}->{limits}->{$limit->getId} = $limit;
    }

    my $csv = Text::CSV->new ( { binary => 0, eol => "\n", sep_char => ";" } );
    my $filename = "user-" . $user->getId .
                   "-" . $cluster_name . ".csv";

    my $fh;
    open $fh, ">:encoding(utf8)", $filename or die "$filename: $!";

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
            my $min = $limits->{shift @$results};
            for my $id (@$results) {
                my $limit = $limits{$id};
                if ($limit->getAttr(name => "value") < $min->getAttr(name => "value")) {
                    $min = $limit;
                }
            }

            # Get the limit value
            my $contract = $min->getAttr(name => "value");
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
}

1;