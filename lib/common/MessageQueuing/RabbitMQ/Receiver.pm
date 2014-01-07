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
my $log = get_logger("amqp");


=pod
=begin classdoc

Declare queues and exchanges.

@param queue the queue on which create the consumer
@param callback the callaback method to execute at message receipt

=end classdoc
=cut

sub createConsumer {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'queue', 'callback' ]);

    # Create the consumer on the queue
    my $consumer_tag = $self->consume(queue => $args{queue});

    # Associate the callback to the consumer tag for retreive the callback to call
    # at message receipt.
    $self->_consumers->{$consumer_tag} = $args{callback};
    return $consumer_tag;
}


=pod
=begin classdoc

Wait for message in an event loop, interupt the bloking call
if the duration exceed.

@optional timeout the maximum time to wait messages, 0 is infinity

=end classdoc
=cut

sub fetch {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'timeout' => 30 });

    $log->debug("Fetch message for <$args{timeout}> second(s).");

    # Wait for messages
    my $rv;
    eval {
        local $SIG{ALRM} = sub {
            throw Kanopya::Exception::MessageQueuing::NoMessage(
                      error => "No message received for $args{timeout} (s)"
                  );
        };

        alarm $args{timeout};

        # Receive the message
        $rv = $self->recv();

        # Reset the alarm
        # TODO: The alarm should occurs between the previous line
        #       and the following one, need semaphore stuff.
        alarm 0;

        if (! defined $rv) {
            throw Kanopya::Exception::MessageQueuing::NoMessage(error => "No message received");
        }

        # Retrieve the callback to call from the message consumer tag
        my $callback = $self->_consumers->{$rv->{consumer_tag}};
        if (! defined $callback) {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "No registred callback found for consumer tag <$rv->{consumer_tag}>"
                  );
        }
        if (! (ref($callback) eq 'CODE')) {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "Defined callback <$callback> is not valid."
                  );
        }

        # Decode the message content in way to use it as callback params
        my $args;
        eval {
            $args = JSON->new->utf8->decode($rv->{body});
        };
        if ($@) {
            my $err = $@;
            if ($err =~ m/malformed JSON string/) {
                $args = { data => $rv->{body} };
            }
            else { $err->rethrow(); }
        }

        # Build a callback method to ack the message
        my $ack_cb = sub {
            $self->acknowledge(tag => $rv->{delivery_tag});
        };

        # Call the corresponding method
        $args->{ack_cb} = $ack_cb;
        if ($callback->(%$args)) {
            # Acknowledge the message if specified by the callback
            $args->{ack_cb}->();
        }
    };
    if ($@) {
        my $err = $@;
        # Acknowledge the message, and rethrow the error
        if (defined $rv) {
            $self->acknowledge(tag => $rv->{delivery_tag});
        }

        if (ref($err)) {
            $err->rethrow();
        }
        else {
            throw Kanopya::Exception::Execution(error => "$err");
        }
    }
}


=pod
=begin classdoc

Return the consumers infos.

=end classdoc
=cut

sub _consumers {
    my ($self, %args) = @_;

    if (not defined $self->{_consumers}) {
        $self->{_consumers} = {}
    }
    return $self->{_consumers};
}

1;
