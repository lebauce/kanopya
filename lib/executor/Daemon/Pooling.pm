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

Base class to manage internal pooling daemon that loop in function
of a defined time step.

@since    2013-Mar-28
@instance hash
@self     $self

=end classdoc

=cut

package Daemon::Pooling;
use base Daemon;

use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


my $method;


=pod
=begin classdoc

Base method to configure the daemon as pooling daemon.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    eval {
        General::checkParams(args => $self->{config}, required => [ "time_step" ]);
    };
    if ($@) {
        throw Kanopya::Exception::Internal(
                  error => "Could not find <time_step> in the daemon configuration"
              );
    }
    return $self;
}


=pod
=begin classdoc

Register a method to call back every round loop.

=end classdoc
=cut

sub registerPollingMethod {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'callback' ]);

    $method = $args{callback};
}


=pod
=begin classdoc

Main loop of the pooling daemon.

=end classdoc
=cut

sub oneRun {
    my ($self) = @_;

    # Get the start time
    my $start_time = time();

    # Execute the callback
    eval {
        $method->();
    };
    if ($@) {
        $log->error("(Deamon $self->{name}) Pooling method failled:\n$@");
    }

    # Get the end time
    my $update_duration = time() - $start_time;
    $log->info("(Deamon $self->{name}) Update duration : $update_duration second(s)");

    if ($update_duration > $self->{config}->{time_step}) {
        $log->warn("(Deamon $self->{name}) Duration > time step <$self->{config}->{time_step}>");
    }
    else {
        sleep($self->{config}->{time_step} - $update_duration);
    }
}

1;
