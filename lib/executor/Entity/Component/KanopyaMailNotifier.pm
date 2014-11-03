# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Component::KanopyaMailNotifier;
use base Entity::Component;
use base Manager::NotificationManager;
use base Manager::DaemonManager;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    smtp_server => {
        label        => 'SMTP server',
        type         => 'string',
        pattern      => '^[a-z0-9-]+(\.[a-z0-9-]+)*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    smtp_login => {
        label        => 'Account login',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    smtp_passwd => {
        label        => 'Account password',
        type         => 'password',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    use_ssl => {
        label        => 'Use SSL',
        type         => 'checkbox',
        pattern      => '^[01]$',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        notify => {
            description => 'produce on th email notification queue.',
            message_queuing => {
                queue => 'kanopya.mailnotifier.notification'
            }
        },
    };
}

sub notify {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'user', 'message' ],
                         optional => { 'subject' => "" });

    # Publish on the 'operation_result' queue
    MessageQueuing::RabbitMQ::Sender::notify($self,
                                             user_id => $args{user}->id,
                                             message => $args{message},
                                             subject => $args{subject},
                                             %{ Kanopya::Database::_adm->{config}->{amqp} });
}

sub getBaseConfiguration {
    return {
        smtp_server => '',
        smtp_login  => '',
        smtp_passwd => '',
        use_ssl     => 0
    };
}

1;
