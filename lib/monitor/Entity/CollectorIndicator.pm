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

use Alert;

use strict;
use warnings;
use base 'Entity';
use Data::Dumper;
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
    General::checkParams(args => \%args, required => ['nodes', 'service_provider']);

    my $cmg = $self->collector_manager;

    my $mparams = $args{service_provider}->getManagerParameters(manager_type => 'CollectorManager');

    my @node_hostnames = map {$_->node_hostname} @{$args{nodes}};

    my $data = $cmg->retrieveData(
                   nodelist   => \@node_hostnames,
                   indicators => {$self->indicator->indicator_oid => undef},
                   time_span  =>  1200,
                   %$mparams
               );

    my %id_values;
    my %hostname_values;

    for my $node (@{$args{nodes}}) {
       $id_values{$node->id} = $data->{$node->node_hostname}->{$self->indicator->indicator_oid};
       $hostname_values{$node->node_hostname} = $data->{$node->node_hostname}->{$self->indicator->indicator_oid};
    }

    $self->throwUndefAlert(hostname_values => \%hostname_values, service_provider => $args{service_provider});
    return \%id_values;
}

sub throwUndefAlert {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['hostname_values', 'service_provider']);

    while (my ($node_hostname, $value) = each(%{$args{hostname_values}})) {
        my $msg = "Indicator " . $self->indicator->indicator_name . ' (' .
                   $self->indicator->indicator_oid . ')' .' was not retrieved by collector for node '.
                   $node_hostname;

        my $alert = eval { Alert->find(hash => {alert_message => $msg,
                                                entity_id => $args{service_provider}->id });
                    };

        if (! defined $value) {
            if ((! defined $alert) || ($alert->alert_active == 0)) {
                Alert->new(entity_id       => $args{service_provider}->id,
                           alert_message   => $msg,
                           alert_signature => $msg.' '.time(),);
            }
        }
        elsif (defined $alert && $alert->alert_active == 1) {
            $alert->mark_resolved;
        }
    }
}
1;
