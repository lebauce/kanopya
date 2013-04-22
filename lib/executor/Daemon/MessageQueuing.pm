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

Base class to manage internal daemons that communicate between them.

@since    2013-Mar-28
@instance hash
@self     $self

=end classdoc

=cut

package Daemon::MessageQueuing;
use base Daemon;
use base MessageQueuing::Qpid::Receiver;

use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod
=begin classdoc

Base method to configure the daemon to use the message queuing middleware.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    return $self;
}


=pod
=begin classdoc

Register the daemon as a worker on a specific channel.
Produced data is distributed among workers, each data is delivered to exactly one worker.

@param channel the channel on which the callback is resistred
@param callback the classback method to call when data is produced on the channel

=end classdoc
=cut

sub registerWorker {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel', 'callback' ]);

    # Set up the daemon as receiver worker on the queue corresponding to the
    # specified channel name.
    $self->register(type => 'queue', %args);
}


=pod
=begin classdoc

Register the daemon as a subscriber on a specific channel.
Produced data is delivred to each subscribers.

@param channel the channel on which the callback is resistred
@param callback the classback method to call when data is produced on the channel

=end classdoc
=cut

sub registerSubscriber {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel', 'callback' ]);

    # Set up the daemon as receiver subscriber on the topic corresponding to the
    # specified channel name.
    $self->register(type => 'topic', %args);
}


=pod
=begin classdoc

Base method to run the daemon.
Override the parent method, create a child process for each registration on channels.

=end classdoc
=cut

sub run {
    my ($self, $running) = @_;

    Message->send(
        from    => $self->{name},
        level   => 'info',
        content => "Kanopya $self->{name} started."
    );

    # Disconnect possibly connected session, as we must do
    # the connection inside the childs created for each channel.
    if ($self->connected) {
        $self->disconnect();
    }

    my $pid;
    for my $type ('queue', 'topic') {
        for my $channel (keys %{ $self->receivers->{$type} }) {
            $log->info("Run child process for waiting on <$type>, channel <$channel>");

            $pid = fork();
            if ($pid == 0) {
                while (1) {
                    eval {
                        $self->oneRun(channel => $channel, type => $type);
                    };
                    if ($@) {
                        my $err = $@;
                        $log->warn("(Deamon $self->{name}) oneRun failled:\n$@");
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
    $self->disconnect();

    Message->send(
        from    => $self->{name},
        level   => 'warning',
        content => "Kanopya $self->{name} stopped"
    );
}


=pod
=begin classdoc

Receive messages from the channels on which the daemon is registred,
and call the corresponding callbacks.

=end classdoc
=cut

sub oneRun {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel', 'type' ]);

    if (not $self->connected) {
        # Connect to the broker
        $self->connect();
    }

    # Blocking call
    $self->receive(type => $args{type}, channel => $args{channel});
}

1;
