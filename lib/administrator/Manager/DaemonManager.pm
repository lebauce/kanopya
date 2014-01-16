# Copyright © 2013 Hedera Technology SAS
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

package Manager::DaemonManager;
use base Manager;
use base MessageQueuing::RabbitMQ::Sender;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");

sub methods {
    return {
        controlDaemon => {
            description => 'control the corresponding running daemon.',
            message_queuing => {}
        },
    };
}

# Usefull when using Manager::DaemonManager stand alone
my $control_queue = undef;


=pod
=begin classdoc

Publish on the control queue of a daemon, allow to spawn/kill child instances
awaiting messages for a callback definition.

For more information about message queuing daemons,
@see <package>Daemon::MessageQueuing</package>

@param cbname the callback definition name to control
@param control the control code (spawn|kill)

@optional instances the instance number to spawn/kill

=end classdoc
=cut

sub controlDaemon {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cbname', 'control' ],
                         optional => { 'instances' => 1 });

    my $queue = $self->getConf()->{control_queue};
    if (! defined $queue) {
        throw Kanopya::Exception::InvalidConfiguration(
                  error => "Can not control daemon as the control queue name is " .
                           "not defined in configuration."
              );
    }

    MessageQueuing::RabbitMQ::Sender::controlDaemon($self,
        queue  => $queue,
        notify => 0,
        %args,
        %{ Kanopya::Database::_adm->{config}->{amqp} }
    );
}

sub getConf {
    my ($self, %args) = @_;

    return { control_queue => $control_queue };
}

sub setConf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'conf' ]);

    if (defined $args{conf}->{control_queue}) {
        $control_queue = $args{conf}->{control_queue};
    }
}

1;
