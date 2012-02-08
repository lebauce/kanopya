# Scom.pm - This object allows to manipulate SCOM equipment
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
package Entity::ServiceProvider::Outside::Scom;
use base 'Entity::ServiceProvider::Outside';

use strict;
use warnings;
use General;
use Kanopya::Exceptions;
use SCOM::Query;
use DateTime::Format::Strptime;
use List::Util 'sum';

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

# Retriever interface method implementation
# args: nodes => [<node_id>], indicators => [<indicator_id>], time_span => <seconds>
# with:
#     <node_id> : scom MonitoringObjectPath
#     <indicator_id> : ObjectName/CounterName
# return: { <node_id> => { <counter_id> => <mean value for last <time_span> seconds> } }
sub retrieveData {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['nodes', 'indicators', 'time_span']);
    
    # TODO retrieve server name from scom conf in db
    my $management_server_name = "WIN-09DSUKS61DT.hedera.forest";

    # Transform array of ObjectName/CounterName into hash {ObjectName => [CounterName]}
    my %counters;
    foreach my $indic (@{$args{indicators}}) {
        # TODO check indic format
        my ($object_name, $counter_name) = split '/', $indic;
        push @{$counters{$object_name}}, $counter_name;
    }
    
    #use Data::Dumper;
    #print Dumper \%counters;
    
    my $global_time_laps = 7200;
    my $time_zone = 'local';
    my $end_dt   = DateTime->now->set_time_zone($time_zone);
    my $start_dt = DateTime->now->subtract( seconds => $global_time_laps )->set_time_zone($time_zone);
    
    my $scom = SCOM::Query->new( server_name => $management_server_name );

    my $all_perfs = $scom->getPerformance(
        counters            => \%counters,
        monitoring_object   => $args{nodes},
        start_time          => _format_dt(dt => $start_dt),
        end_time            => _format_dt(dt => $end_dt),
    );
    
    my $res = _format_data(
        data        => $all_perfs,
        end_dt      => $end_dt,
        time_span   => $args{time_span},
        time_zone   => $time_zone,
    );
    
    return $res;
}

# Computes mean value for each metric from scom query res
# Mean on last <time_span> seconds, if no value during this laps, then take the last value (handle scom db optimization)
# Builds retriever resulting hash
sub _format_data {
    my %args = @_;
    my $data = $args{data};
    my $end_dt = $args{end_dt};
    my $time_span = $args{time_span};
    my $time_zone = $args{time_zone};
    
    my $date_parser = DateTime::Format::Strptime->new( pattern => '%d/%m/%Y %H:%M:%S' );
    
    # Compute mean value for each metrics 
    my %res;
    while (my ($monit_object_path, $metrics) = each %$data) {
        while (my ($object_name, $counters) = each %$metrics) {
            while (my ($counter_name, $values) = each %$counters) {
                my ($last_time, $last_value);
                my @values;
                while (my ($timestamp, $value) = each %$values) {
                    my $dt = $date_parser->parse_datetime( $timestamp )->set_time_zone( $time_zone );
                    
                    # Keep values in time span
                    if ($end_dt->epoch - $dt->epoch <= $time_span) {
                        push @values, $value;
                    }
                    
                    # Keep last value
                    if ((not defined $last_time) || ($last_time < $dt)) {($last_time, $last_value) = ($dt, $value)};
                }
                
                my $value;
                if (0 != @values) {
                    # WARNING !!! summed values are truncated because number format is "1,0" instead of "1.0"
                    # TODO manage this! 
                    $value = sum(@values) / @values;
                } else {
                    $value = $last_value;
                    print "Info: take last counter value\n";
                }
                
                $res{$monit_object_path}{"$object_name/$counter_name"} = $value;
            }
        }
    }
    
    return \%res;
}

sub _format_dt {
    my %args = @_;
    my $dt = $args{dt};
    
    return $dt->dmy('/') . ' ' . $dt->hms(':');
}

1;
