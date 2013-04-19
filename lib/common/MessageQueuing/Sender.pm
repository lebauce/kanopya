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

package MessageQueuing::Sender;

use strict;
use warnings;

use cqpid_perl;

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

my $session;
my $connection;
my $senders = {};

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod
=begin classdoc

Connect to the message queuing server.

@param ip the message queuing server ip
@param port the message queuing server port

=end classdoc
=cut

sub connect {
    my ($class, %args) = @_;

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
        for my $receiver (values %{ $self->{receivers}->{$type} }) {
            $receiver->{receiver}->close();
        }
    }
    $connection->close();
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
    if (not defined $senders->{$channel}) {
        if (not defined $session) {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "You must to connect to the message queuing server before sending."
                  );
        }

        # Send message on both queue and type for the specified channel
        $senders->{$channel} = [];
        for my $type ('queue', 'topic') {
            my $address = $channel . '; { create: always, node: { type: ' . $type . ' } }';
            push @{ $senders->{$channel} },  $session->createSender($address);
        }
    }

    # Serialize arguments
    my $message = new cqpid_perl::Message();
    cqpid_perl::encode(\%args, $message);

    for my $sender (@{ $senders->{$channel} }) {
        $sender->send($message);
    }
}


=pod
=begin classdoc

Method called at the object deletion.

=end classdoc
=cut

sub DESTROY {}

1;
