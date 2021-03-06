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

Base class to becomme a message queuing sender.
Provide methods to send message on queues or topics.

@since    2013-Avr-19
@instance hash
@self     $self

=end classdoc

=cut

package MessageQueuing::RabbitMQ::Sender;
use base MessageQueuing::RabbitMQ;

use strict;
use warnings;

use Hash::Merge;
use Data::Dumper;
use vars qw($AUTOLOAD);

use Log::Log4perl "get_logger";
my $log = get_logger("amqp");

sub methods {
    return {
        send => {
            description     => 'Produce a message to the specified queue',
            message_queuing => {}
        },
    };
}

my $merge = Hash::Merge->new('LEFT_PRECEDENT');

# Define the event loop mode. If a process want to send messages within an event loop
# (i.e. within a callback executed in a thread at message receipt), it cannot use
# routine like connect/disconnect/declare_queue, this should be done out of the event loop.
my $incallback;


=pod
=begin classdoc

Connect to the message queuing server, and declare the queues and exchanges.

=end classdoc
=cut

sub connect {
    my ($self, %args) = @_;

    $self->SUPER::connect(%args);

    # For each method declare the predefined queues and exchanges.
    for my $method (values %{ $self->methods }) {
        if (defined $method->{message_queuing}->{queue}) {
            $self->declareQueue(queue => $method->{message_queuing}->{queue});
            $self->declareExchange(exchange => $method->{message_queuing}->{queue},
                                   type     => 'fanout');
        }
    }
}


=pod
=begin classdoc

We define an AUTOLOAD to handle the same way method that implicitly send a message.

=end classdoc
=cut

sub AUTOLOAD {
    my ($self, %args) = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $accessor = $autoload[-1];

    my $method;
    if ($self->can("_methodsDefinition")) {
        $method = $self->_methodsDefinition()->{$accessor};
    }
    else {
        $method = $self->methods()->{$accessor};
    }

    if ((not defined $method) or not defined ($method->{message_queuing})) {
        # The called method is not a defined message queuing method.
        $method = 'SUPER::' . $accessor;
        return $self->$method(%args);
    }

    # Merge the arguments with possibly prefined for this method.
    %args = %{ $merge->merge(\%args, $method->{message_queuing}) };

    General::checkParams(args => \%args, required => [ 'queue' ], optional => { 'notify' => 1 });

    my $queue  = delete $args{queue};
    my $notify = delete $args{notify};

    # Remove possibly defined connection options form args
    my $auth = {};

    if (defined $args{user}) {
        $auth->{user} = delete $args{user};
    }

    if (defined $args{password}) {
        $auth->{password} = delete $args{password};
    }

    # Connect the sender if not done
    if (not $self->connected) {
        $self->connect(%$auth);
    }

    # Declare the queue if not done at connect
    $self->declareQueue(queue => $queue);
    if ($args{notify}) {
        # Declare the exchange if not done at connect
        $self->declareExchange(exchange => $queue, type => 'fanout');
    }

    # Serialize arguments
    my $data = JSON->new->utf8->encode(\%args);

    my $on_inactive = sub {
        $log->error("Channel <" . $self->_channel . "> is inactive... \n");
    };

    my $err;
    my $send  = 0;
    my $retry = 5;
    while ($retry > 0 && ! $send) {
        $err = undef;
        eval {
            # Send message for the workers
            $log->debug("Publishing on queue <$queue>, body: $data");
            # TODO: Move the publish job in the parent package
            $self->_connection->publish($self->_channel, $queue, $data, { mandatory => 1 }, {
                content_type     => 'text/plain',
                content_encoding => 'none',
                delivery_mode    => 2,
            });
            $send = 1;
        };
        if ($@) {
            $err = $@;
            $log->warn("Failed to publish on queue <$queue>, $retry left: $err");
            $retry--;
            sleep 1;
        }
    }

    if ($notify) {
        $send  = 0;
        $retry = 10;
        while ($retry > 0 && ! $send) {
            $err = undef;
            eval {
                # Send message for the subscribers
                $log->debug("Publishing on exchange <$queue>, body: $data");
                $self->_connection->publish($self->_channel, $queue, $data,
                    { mandatory => 1, exchange => $queue },
                    { content_type     => 'text/plain',
                      content_encoding => 'none',
                      delivery_mode    => 2 }
                );
                $send = 1;
            };
            if ($@) {
                my $err = $@;
                $log->warn("Failed to publish on exchange <$queue>, $retry left: $err");
                $retry--;
                sleep 1;
            }
        }
    }

    if (not $incallback) {
        $self->disconnect();
    }

    if (defined $err) {
        throw Kanopya::Exception::MessageQueuing::PublishFailed(
                  error => $err,
                  queue => $queue,
                  body  => \%args,
              );
    }
}


=pod
=begin classdoc

Method called at the object deletion. Disconnect from the broker.

=end classdoc
=cut

sub DESTROY {
    my ($self, %args) = @_;

    eval {
        $self->disconnect();
    };
    if ($@) {
        my $err = $@;
        $log->warn("Unable to disconnect at DESTROY: $err");
    }
}


=pod
=begin classdoc

The callback mode indicate to the sender that it will be used
within a callback executed by a daemon at message receipt.
Then it won't try to connect or disconnect as the connection
management is done by the daemon.

=end classdoc
=cut

sub setCallBackMode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'in_eventloop' => 1 });

    $log->debug("Sender now in eventloop mode to $args{in_eventloop}");
    $incallback = $args{in_eventloop};
}

1;
