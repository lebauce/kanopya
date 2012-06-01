# MockMonitor.pm - Mock Monitoring Service connector
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
package Entity::Connector::MockMonitor;
use base 'Entity::Connector';

use strict;
use warnings;
use General;
use Kanopya::Exceptions;

use constant ATTR_DEF => {

};

sub getAttrDef { return ATTR_DEF; }

# Retriever interface method implementation
# args: nodes => [<node_id>], indicators => [<indicator_id>], time_span => <seconds>
# with:
#     <node_id> : node id
#     <indicator_id> : indicator id
# return: { <node_id> => { <counter_id> => rand } }
sub retrieveData {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['nodes', 'indicators', 'time_span']);
    
    my $res;
    
    foreach my $node (@{$args{nodes}}) {
        my %counters_value = map { $_ => rand(100) } @{$args{indicators}};
        $res->{$node} = \%counters_value;
    } 
    
    return $res;
}

1;
