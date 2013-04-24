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

package MessageQueuing::RabbitMQ::Receiver;
use base MessageQueuing::RabbitMQ;

use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant DURATION => {
    FOREVER   => undef,
    SECOND    => 1,
    MINUTE    => 60,
    IMMEDIATE => 0.5
};


=pod
=begin classdoc

Disconnect from the message queuing server.

=end classdoc
=cut

sub disconnect {
    my ($self, %args) = @_;

    for my $type ('queue', 'topic') {
        for my $receiver (values %{ $self->_receivers->{$type} }) {
            delete $receiver->{receiver};
        }
    }
    return $self->SUPER::disconnect(%args);
}


=pod
=begin classdoc

Register a callback on a specific channel.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)
@param callback the classback method to call when data is produced on the channel

@optional the maximum duration of awaiting messages

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

    if (not defined $self->_receivers) {
        $self->{_receivers} = {};
    }

    # Register the method to call back at message recepetion
    $self->_receivers->{$args{type}}->{$args{channel}} = {
        callback => $args{callback},
        duration => DURATION->{$args{duration}},
        receiver => $self->connected ? $self->createReceiver(channel => $args{channel}, type => $args{type}) : undef,
    };
}


=pod
=begin classdoc

Receive messages from the specific channel, and call the corresponding callbacks.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)

=end classdoc
=cut

sub receive {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'type', 'channel' ]);

    # Share the AnyEvent condvar with the callback
    my $condvar = AnyEvent->condvar;

    # Register ad consumer on the channel
    $self->consume(channel => $args{channel}, type => $args{type}, condvar => $condvar);

    # Blocking call
    $self->fetch(condvar  => $condvar,
                 duration => $self->_receivers->{$args{type}}->{$args{channel}}->{duration});
}


=pod
=begin classdoc

Receive messages from all channels, spawn a child for each channel,
then wait on the $$running pointer to kill childs when the service is stopped.

=end classdoc
=cut

sub receiveAll {
    my ($self, $running) = @_;

    if (not $self->connected) {
        $self->connect();
    }

    # Register as consumer for all channel and types
    for my $type ('queue', 'topic') {
        for my $channel (keys %{ $self->_receivers->{$type} }) {
            $self->consume(channel => $channel, type => $type);
        }
    }
    # Wait on the running pointer,
    while ($$running) {
        my $condvar = AnyEvent->condvar;
        eval {
            $self->fetch(condvar => $condvar, duration => 5);
        };
        if ($@) {
            # No message receiver for duration
        }
    }
}


=pod
=begin classdoc

register the current process as consumer on the specified channel.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)
@param condvar the AnyEvent condvar variable

=end classdoc
=cut

sub consume {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'type', 'channel' ],
                         optional => { 'condvar' => undef });

    # Check the connection status
    if (not $self->connected) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "You must to connect to the message queuing server before receiving."
              );
    }

    my $receiver = $self->_receivers->{$args{type}}->{$args{channel}};
    if (not defined $receiver->{receiver}) {
        $receiver->{receiver} = $self->createReceiver(channel => $args{channel}, type => $args{type});
    }

    # Define the callback called at message consumption, it simply call
    # the callback method given at registration on the queue.
    my $callback = sub {
        my $var = shift;

        my ($type, $channel);
        if ($var->{deliver}->{method_frame}->{exchange} ne '') {
            # Seems to be a topic message
            $type = 'topic';
            $channel = $var->{deliver}->{method_frame}->{exchange};
        }
        elsif ($var->{deliver}->{method_frame}->{routing_key} ne '') {
            # Seems to be a queue message
            $type = 'queue';
            $channel = $var->{deliver}->{method_frame}->{routing_key};
        }
        else {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "Unreconized message type:\n" . Dumper($var)
                  );
        }

        # Decode the message content in way to use it as callback params
        my $args;
        eval {
            $args = JSON->new->utf8->decode($var->{body}->{payload});
        };
        if ($@) {
            my $err = $@;
            if ($err =~ m/malformed JSON string/) {
                $args = { data => $var->{body}->{payload} };
            }
            else { $err->rethrow(); }
        }

        # Call the corresponding method
        $receiver->{callback}->(%$args);

        # Interupt the infinite loop
        if (defined $args{condvar}) {
            $args{condvar}->send;
        }
    };

    # Register the method to call back at message consumption
    $self->_session->consume(
        on_consume => \&$callback,
        queue      => $receiver->{receiver}->{method_frame}->{queue},
        no_ack     => 1,
    );
}

=pod
=begin classdoc

Wait for message in an event loop, interupt the bloking call
if the duration exceed.

@optional duration the maximum time to wait messages.

=end classdoc
=cut

sub fetch {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'condvar' ],
                         optional => { 'duration' => undef });

    # Set a timer to wait messages for the specified duration only
    my $timerref;
    my $timeouted = 0;
    if (defined $args{duration}) {
        $timerref = AnyEvent->timer(after => $args{duration}, cb => sub {
            $timeouted = 1;
            # Interupt the infinite loop
            $args{condvar}->send;
        });
    }

    # Wait on the queue
    $args{condvar}->recv;

    if ($timeouted) {
        throw Kanopya::Exception::MessageQueuing::NoMessage(
                  error => "No message recevied for $args{duration} second(s)"
              );
    }

    # Acknowledge the message, as the corresponding job is finish
    $self->_session->ack();
}


=pod
=begin classdoc

Declare queues and exchanges.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)

=end classdoc
=cut

sub createReceiver {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'type', 'channel' ]);

    if ($args{type} eq 'queue') {
        return $self->_session->declare_queue(queue => $args{channel}, durable => 1);
    }
    elsif ($args{type} eq 'topic') {
        $self->_session->declare_exchange(
            exchange => $args{channel},
            type     => 'fanout',
        );

        my $queue = $self->_session->declare_queue(exclusive => 1);
        $self->_session->bind_queue(
            exchange => $args{channel},
            queue    => $queue->{method_frame}->{queue},
        );
        return $queue;
    }
}


=pod
=begin classdoc

Return the receivers instancies.

=end classdoc
=cut

sub _receivers {
    my ($self, %args) = @_;

    return $self->{_receivers};
}

1;
