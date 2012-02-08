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

use General;
use Kanopya::Exceptions;
use SCOM::Query;
use DateTime;

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
    
    my $end_dt   = DateTime->now->set_time_zone('local');
    my $start_dt = DateTime->now->subtract( seconds => $args{time_span} )->set_time_zone('local');
    
    my $scom = SCOM::Query->new( server_name => $management_server_name );

    my $res = $scom->getPerformance(
        counters            => \%counters,
        monitoring_object   => $args{nodes},
        start_time          => _format_dt(dt => $start_dt),
        end_time            => _format_dt(dt => $end_dt),
    );
    
    #TODO moyenne des valeurs pour chaque métrique
    
    return $res;
}

sub _format_dt {
    my %args = @_;
    my $dt = $args{dt};
    
    return $dt->dmy('/') . ' ' . $dt->hms(':');
}

1;
