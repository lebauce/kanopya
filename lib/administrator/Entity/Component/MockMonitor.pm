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

=head1 NAME

Entity::Component::MockMonitor

=head1 SYNOPSIS

=head1 DESCRIPTION

Mock collector manager giving values for requested nodes and indicators according to configuration.

Configuration example (JSON format):
{
    'default' : {'const' : 200},
    'nodes' : {
        'node1' : {'const' : null},
        'node2' : {'const' : 100},
        'node3' : {'rand'  : [0,100]},
    },
    'indics' : {'indic1' : {'const':null}}
}

=cut

package Entity::Component::MockMonitor;
use base 'Entity::Component';
use base 'Manager::CollectorManager';

use strict;
use warnings;
use General;
use Kanopya::Exceptions;
use Indicatorset;
use JSON -support_by_pp;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
};

sub getAttrDef { return ATTR_DEF; }

sub getManagerParamsDef {
    return [
        'mockmonit_config'
      ];
}

# Retriever interface method implementation
# args: nodes => [<node_id>], indicators => [<indicator_id>], time_span => <seconds>
# with:
#     <node_id> : node id
#     <indicator_id> : indicator id
# return: { <node_id> => { <counter_id> => <generated value according to conf> } }
sub retrieveData {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['nodelist', 'indicators', 'time_span']);

    my $conf = {
        default => {
            'rand' => [0,100]
        }
    };
    my $config = $args{mockmonit_config};
    if ($config) {
        my $loaded_conf = from_json($config, {allow_singlequote => 1, relaxed => 1});
        if (not exists $loaded_conf->{default}) {$loaded_conf->{default} = $conf->{default}};
        $conf = $loaded_conf;
    }

    my $res;
    foreach my $node (@{$args{nodelist}}) {
        my %counters_value = map {
            $_ => $self->_computeValue( generator => ($conf->{nodes}->{$node} || $conf->{indics}->{$_} || $conf->{default}) )
        } keys %{$args{indicators}};
        $res->{$node} = \%counters_value;
    }

    return $res;
}

sub _computeValue {
    my ($self, %args) = @_;

    my $gen = $args{generator};
    my $value;
    if ($gen->{'rand'}) {
        my $range = $gen->{'rand'};
        $value = $range->[0] + rand($range->[1] - $range->[0]);
    } elsif (exists $gen->{'const'}) {
        $value = $gen->{'const'};
    }
    return $value;
}

=head2 new

    new is redefined to create the collector indicators

=cut

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::new( %args );

    my @indicator_sets = Indicatorset->search(hash =>{});
    $self->createCollectorIndicators(
        indicator_sets => \@indicator_sets,
    );

    return $self;
}

1;
