#    Copyright © 2013 Hedera Technology SAS
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

=pod

=begin classdoc

Base class to becomme a message queuing receiver.
Provide methods to register callback on queues or topics.

@since    2013-Avr-19
@instance hash
@self     $self

=end classdoc

=cut

package MessageQueuing::Receiver;

use strict;
use warnings;

use cqpid_perl;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

my $session;
my $connection;

use constant DURATION => {
    FOREVER   => $cqpid_perl::Duration::FOREVER,
    SECOND    => $cqpid_perl::Duration::SECOND,
    MINUTE    => $cqpid_perl::Duration::MINUTE,
    IMMEDIATE => $cqpid_perl::Duration::IMMEDIATE
};


=pod
=begin classdoc

Connect to the message queuing server.

@param ip the message queuing server ip
@param port the message queuing server port

=end classdoc
=cut

sub connect {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'ip' => '127.0.0.1', 'port' => '5672' });

    # Connect to the broker
    $connection = new cqpid_perl::Connection("amqp:tcp:" . $args{ip} . ":" . $args{port}, "");

    # Open the seesion
    $connection->open();
    $session = $connection->createSession();
}


=pod
=begin classdoc

Disconnect from the message queuing server.

=end classdoc
=cut

sub disconnect {
    my ($self, %args) = @_;

    for my $type ('queue', 'topic') {
        for my $receiver (values %{ $self->{_receivers}->{$type} }) {
            if (defined $receiver->{receiver}) {
                eval {
                    $receiver->{receiver}->close();
                };
                if ($@) {
                    $log->warn("Unable to close receiver <$type>:\n$@");
                }
                delete $receiver->{receiver};
            }
        }
    }
    if (defined $session) {
        $session->close();
        $session = undef;
    }
    if (defined $connection) {
        $connection->close();
        $connection = undef;
    }
}


=pod
=begin classdoc

Register a callback on a specific channel.

@param channel the channel on which the callback is resistred
@param channel the type of the queue (queue or topic)
@param callback the classback method to call when data is produced on the channel

=end classdoc
=cut

sub register {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'type', 'channel', 'callback' ],
                         optional => { 'duration' => 'FOREVER' });

    if ($args{type} !~ m/^(queue|topic)$/) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "Wrong value <$args{type}> for argument <type>, must be <queue|topic>"
              );
    }

    if ($args{duration} !~ m/^(FOREVER|SECOND|MINUTE|IMMEDIATE)$/) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "Wrong value <$args{duration}> for argument <duration>, " .
                           "must be <FOREVER|SECOND|MINUTE|IMMEDIATE>"
              );
    }

    # Build the addresse string from channel and type
    my $address = $args{channel} . '; { create: always, node: { type: ' . $args{type} . ' } }';

    if (not defined $self->{_receivers}) {
        $self->{_receivers} = {};
    }

    # Register the method to call back at message recepetion
    $self->{_receivers}->{$args{type}}->{$args{channel}} = {
        receiver => $self->connected ? $session->createReceiver($address) : undef,
        address  => $address,
        callback => $args{callback},
        duration => DURATION->{$args{duration}}
    };
}


=pod
=begin classdoc

Receive messages from the specific channel, and call the corresponding callbacks.

=end classdoc
=cut

sub receive {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'type', 'channel' ]);

    # Check the connection status
    if (not $self->connected) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "You must to connect to the message queuing server before receiving."
              );
    }

    my $receiver = $self->{_receivers}->{$args{type}}->{$args{channel}};
    if (not defined $receiver->{receiver}) {
        $receiver->{receiver} = $session->createReceiver($receiver->{address});
    }

    # Wait on the queue
    my $content;
    eval {
        $content = cqpid_perl::decodeMap($receiver->{receiver}->fetch($receiver->{duration}));
    };
    if ($@) {
        throw Kanopya::Exception::MessageQueuing::NoMessage(error => $@);
    }

    # Call back the corrsponding method with the message content as arguments
    my $result = $receiver->{callback}->(%$content);

    # Acknowledge the message, as the corrsponding job is finish
    $session->acknowledge();

    return $result;
}


=pod
=begin classdoc

Return the connection status.

=end classdoc
=cut

sub connected {
    my ($self, %args) = @_;

    return (defined $session and defined $session->getConnection());
}


=pod
=begin classdoc

Return the receivers instancies.

=end classdoc
=cut

sub receivers {
    my ($self, %args) = @_;

    return $self->{_receivers};
}

1;
