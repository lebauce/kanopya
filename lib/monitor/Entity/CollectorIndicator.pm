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

=pod

=begin classdoc

Link indicators with collector managers.
Represents base monitoring object manipulated by services.
A service can only use indicators linked with its collector manager.

@see <package>Entity::Indicator</package>

=end classdoc

=cut

package Entity::CollectorIndicator;

use base 'Entity';

use strict;
use warnings;
use Data::Dumper;

use Alert;
use DataCache;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    collector_indicator_id => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    indicator_id => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    collector_manager_id => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub lastValue {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['nodes']);

    my %id_values;
    my @missing_nodes = ();

    $log->debug("Retrieving the last value for " . scalar(@{ $args{nodes} }) . " nodes");
    for my $node (@{$args{nodes}}) {
        if (exists $args{memoization}->{$self->id}->{$node->id}) {
            $log->debug("Use memoization value for indicator <" . $self->label .
                        "> for node <" . $node->label . ">");
            $id_values{$node->id} = $args{memoization}->{$self->id}->{$node->id};
        }
        else {
            $log->debug("No memoization value for indicator <" . $self->label .
                        "> for node <" . $node->label . ">, retrieve from the node metric.");
            push @missing_nodes, $node;
        }
    }

    if (scalar @missing_nodes == 0) {
        $log->debug("All last values retrieved from memoization.");
        return \%id_values;
    }

    # Get all node metric related to nodes
    my @nodeids = map { $_->id } @missing_nodes;
    my @nodemetrics = Entity::Metric::Nodemetric->search(hash => {
                          nodemetric_indicator_id => $self->id,
                          nodemetric_node_id      => \@nodeids
                      });

    my %hostname_values;
    $log->debug("Retrieving last value from " . scalar(@nodemetrics) . " node metric(s)");
    for my $nodemetric (@nodemetrics) {
       my $node = $nodemetric->nodemetric_node;
       $hostname_values{$node->node_hostname} = $id_values{$node->id} = $nodemetric->lastValue;

       if (defined $args{memoization}) {
           $args{memoization}->{$self->id}->{$node->id} = $id_values{$node->id};
       }
    }

    $self->throwUndefAlert(hostname_values  => \%hostname_values,
                           service_provider => $missing_nodes[0]->service_provider);

    $log->debug("Returning last value for " . scalar(keys(%id_values)) . " node metric(s)");
    return \%id_values;
}

=pod
=begin classdoc

Return values between start_time and stop_time for several nodes

@param nodes Array ref of nodes for which we want fetch values
@param start_time Start time in epoch
@param end_time Stop time in epoch

@return hashref { node_id => {timestamp => value} }

=end classdoc
=cut

sub fetch {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['nodes', 'start_time', 'end_time']);

    # Get all node metric related to nodes
    my @node_hostnames = map {$_->node_hostname} @{$args{nodes}};
    my @nodemetrics = Entity::Metric::Nodemetric->search(
                          hash => { 'nodemetric_node.node_hostname' => \@node_hostnames }
                      );

    my %id_values;
    for my $nodemetric (@nodemetrics) {
        $id_values{$nodemetric->nodemetric_node->id} = $nodemetric->fetch(start_time => $args{start_time},
                                                                          stop_time  => $args{end_time});
    }

    return \%id_values;
}

sub throwUndefAlert {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['hostname_values', 'service_provider']);

    my $indicator = $self->indicator;

    while (my ($node_hostname, $value) = each(%{$args{hostname_values}})) {
        my $msg = "Indicator " . $indicator->indicator_name . ' (' .
                   $indicator->indicator_oid . ')' .' was not retrieved from DataCache for node '.
                   $node_hostname;

        if (! defined $value) {
            Alert->throw(trigger_entity => $self,
                         alert_message  => $msg,
                         entity_id      => $args{service_provider}->id);
        }
        else {
            Alert->resolve(trigger_entity => $self,
                           alert_message  => $msg,
                           entity_id      => $args{service_provider}->id);
        }
    }
}
1;
