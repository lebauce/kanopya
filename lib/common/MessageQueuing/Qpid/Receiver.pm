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

package MessageQueuing::Qpid::Receiver;
use base MessageQueuing::Qpid;

use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant DURATION => {
    FOREVER   => $cqpid_perl::Duration::FOREVER,
    SECOND    => $cqpid_perl::Duration::SECOND,
    MINUTE    => $cqpid_perl::Duration::MINUTE,
    IMMEDIATE => $cqpid_perl::Duration::IMMEDIATE
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

    # Build the addresse string from channel and type
    my $address = $args{channel} . '; { create: always, node: { type: ' . $args{type} . ' } }';

    if (not defined $self->_receivers) {
        $self->{_receivers} = {};
    }

    # Register the method to call back at message recepetion
    $self->_receivers->{$args{type}}->{$args{channel}} = {
        receiver => $self->connected ? $self->_session->createReceiver($address) : undef,
        address  => $address,
        callback => $args{callback},
        duration => DURATION->{$args{duration}}
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

    # Check the connection status
    if (not $self->connected) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "You must to connect to the message queuing server before receiving."
              );
    }

    my $receiver = $self->_receivers->{$args{type}}->{$args{channel}};
    if (not defined $receiver->{receiver}) {
        $receiver->{receiver} = $self->_session->createReceiver($receiver->{address});
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
    $self->_session->acknowledge();

    return $result;
}


=pod
=begin classdoc

Receive messages from all channels, spawn a child for each channel,
then wait on the $$running pointer to kill childs when the service is stopped.

=end classdoc
=cut

sub receiveAll {
    my ($self, $running) = @_;

    my $pid;
    for my $type ('queue', 'topic') {
        for my $channel (keys %{ $self->_receivers->{$type} }) {
            $log->info("Run child process for waiting on <$type>, channel <$channel>");

            $pid = fork();
            if ($pid == 0) {
                # Connect to the broker within the child
                if (not $self->connected) {
                    $self->connect();
                }

                # Infinite loop on receive
                while (1) {
                    eval {
                        $self->receive(channel => $channel, type => $type);
                    };
                    if ($@) {
                        my $err = $@;
                        $log->warn("Receive on <$channel> of type <$type> failled:\n$@");
                    }
                }
                die;
            }
        }
    }
    if ($pid != 0) {
        # Wait on the running pointer, and kill childs when the daemon is stopping
        while ($$running) {
            sleep(5);
        }
        kill -1, getpgrp($pid);
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
