#    Copyright © 2011-2013 Hedera Technology SAS
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

package Alert;
use parent 'BaseDB';

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    service_provider_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    trigger_entity_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    alert_message => {
        pattern      => '^.+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    alert_signature => {
        pattern      => '^.+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'entity_id', 'alert_message', 'alert_signature' ]);

    return $class->SUPER::new(alert_date => \"CURRENT_DATE()",
                              alert_time => \"CURRENT_TIME()",
                              %args);
}

sub mark_resolved {
    my ($self) = @_;

    $self->setAttr(name => 'alert_active', value => 0, save => 1);
}

sub resolve {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['trigger_entity', 'entity_id', 'alert_message']);

    $log->debug('Try to resolve alert from entity <'.($args{trigger_entity}->id).'> with message: '.$args{alert_message});
    eval {
        my $alert = $args{trigger_entity}->findRelated(filters => ['alert_trigger_entities'],
                                                       hash    => {
                                                           alert_message => $args{alert_message},
                                                           alert_active  => 1
                                                       });
        $alert->mark_resolved();
    };
}

sub throw {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['trigger_entity', 'entity_id', 'alert_message']);

    $log->debug('Try to throw alert from entity <'.($args{trigger_entity}->id).'> with message: '.$args{alert_message});

    eval {
        my $alert = $args{trigger_entity}->findRelated(filters => ['alert_trigger_entities'],
                                                       hash    => {
                                                           alert_message => $args{alert_message},
                                                           alert_active  => 1
                                                       });
    };
    if ($@) {
        Alert->new(entity_id         => $args{entity_id},
                   alert_message     => $args{alert_message},
                   alert_signature   => $args{alert_message}.' '.time(),
                   trigger_entity_id => $args{trigger_entity}->id);
    }
}
1;
