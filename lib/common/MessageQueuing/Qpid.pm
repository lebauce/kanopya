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

Base class to mannage connection to a Qpid broker.

@since    2013-Avr-19
@instance hash
@self     $self

=end classdoc

=cut

package MessageQueuing::Qpid;

use strict;
use warnings;

use cqpid_perl;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


my $session;
my $connection;


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

Return the connection status.

=end classdoc
=cut

sub connected {
    my ($self, %args) = @_;

    return (defined $session and defined $session->getConnection());
}


=pod
=begin classdoc

Return the session singleton.

=end classdoc
=cut

sub _session {
    my ($self, %args) = @_;

    return $session;
}

1;
