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
my $log = get_logger("");

sub methods {
    return {
        send => {
            description     => 'Produce a message to the specified channel',
            message_queuing => {}
        },
    };
}

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod
=begin classdoc

Connect to the message queuing server, and declare the channels.

=end classdoc
=cut

sub connect {
    my ($self, %args) = @_;

    $self->SUPER::connect(%args);

    # For each method declare the predefined channel
    for my $method (values %{ $self->methods }) {
        if (defined $method->{message_queuing}->{channel}) {
            $self->declareQueue(channel => $method->{message_queuing}->{channel});
            $self->declareExchange(channel => $method->{message_queuing}->{channel});
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

    my $method = $self->methods()->{$accessor};
    if ((not defined $method) or not defined ($method->{message_queuing})) {
        # The called method is not a defined message queuing method.
        $method = 'SUPER::' . $accessor;
        return $self->$method();
    }

    # Merge the arguments with possibly prefined for this method.
    %args = %{ $merge->merge(\%args, $method->{message_queuing}) };

    General::checkParams(args => \%args, required => [ 'channel' ]);

    my $channel = delete $args{channel};

    # Remove possibly defined connection options form args
    my $auth = {
        user     => delete $args{user},
        password => delete $args{password},
    };

    # If we are in an event loop, cannot connect or declare,
    # this should be done out of the event loop.
    if (not $self->{_incallback}) {
        # Connect the sender if not done
        if (not $self->connected) {
            $self->connect(%$auth);
        }
        # Declare the queue if not done at connect
        $self->declareQueue(channel => $channel);
        # Declare the exchange if not done at connect
        $self->declareExchange(channel => $channel);
    }

    # Serialize arguments
    my $data = JSON->new->utf8->encode(\%args);

    my $on_inactive = sub {
        $log->error("Channel <" . $self->_channel . "> is inactive... \n");
    };

    my $err;
    my $send  = 0;
    my $retry = 5;
    while ($retry > 0 and not $send) {
        $err = undef;
        eval {
            # Send message for the workers
            $log->debug("Publishing on queue <$channel>, body: $data");
            # TODO: Move the publish job in the parent package
            $self->_connection->publish($self->_channel, $channel, $data, { mandatory => 1 }, {
                content_type     => 'text/plain',
                content_encoding => 'none',
                delivery_mode    => 2,
            });
            $send = 1;
        };
        if ($@) {
            $err = $@;
            $log->warn("Failed to publish on queue <$channel>, $retry left: $err");
            $retry--;
            sleep 1;
        }
    }

#    $send  = 0;
#    $retry = 10;
#    while ($retry > 0 and not $send) {
#        $err = undef;
#        eval {
#            # Send message for the workers
#            $log->debug("Publishing on queue <$channel>, body: $data");
#            $self->_connection->publish($self->_channel, $channel, $data,
#                { mandatory => 1, exchange => $channel }, {
#                content_type     => 'text/plain',
#                content_encoding => 'none',
#                delivery_mode    => 2,
#            });
#            $send = 1;
#        };
#        if ($@) {
#            my $err = $@;
#            $log->warn("Failed to publish on exchange <$channel>, $retry left: $err");
#            $retry--;
#            sleep 1;
#        }
#    }
#    if (defined $err) {
#        throw Kanopya::Exception::MessageQueuing::PublishFailed(error => $err);
#    }

    if (not $self->{_incallback}) {
        $self->disconnect();
    }

    if (defined $err) {
        throw Kanopya::Exception::MessageQueuing::PublishFailed(
                  error   => $err,
                  channel => $channel,
                  body    => $data,
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
    $self->{_incallback} = $args{in_eventloop};
}

1;
