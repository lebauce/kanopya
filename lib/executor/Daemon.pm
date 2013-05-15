#    Copyright © 2012 Hedera Technology SAS
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

Base class to manage internal daemons.

@since    2013-Mar-28
@instance hash
@self     $self

=end classdoc

=cut

package Daemon;

use strict;
use warnings;

use Kanopya::Exceptions;
use Kanopya::Config;

use Message;
use EEntity;
use Entity::Host;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

# The host on which the daemon is running.
my $host;

# The component corresponding to the daemon
my $component;


my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


=pod
=begin classdoc

Base method to authenticate daemon to the api.

@param confkey the key of the configuration file to use for authentication to the api.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'confkey' => undef,
                                       'config'  => {},
                                       'name'    => $class });

    my $self = { name => $args{name} };
    bless $self, $class;

    # Get the authentication configuration
    $self->{config} = defined $args{confkey} ? Kanopya::Config::get($args{confkey}) : $args{config};

    eval {
        General::checkParams(args => $self->{config}->{user}, required => [ "name", "password" ]);
    };
    if ($@) {
        throw Kanopya::Exception::Internal(
                  error => "Could not find <name> or/and <password> in the <user> configuration"
              );
    }

    # Authenticate the daemon to the api.
    BaseDB->authenticate(login    => $self->{config}->{user}->{name},
                         password => $self->{config}->{user}->{password});

    # Get the component configuration for the daemon.
    $self->refreshConfiguration();

    return $self;
}


=pod
=begin classdoc

Base method to run the daemon.

=end classdoc
=cut

sub run {
    my ($self, $running) = @_;

    Message->send(
        from    => $self->{name},
        level   => 'info',
        content => "Kanopya $self->{name} started."
    );

    while ($$running) {
        $self->execnround(run => 1);
    }

    Message->send(
        from    => $self->{name},
        level   => 'warning',
        content => "Kanopya $self->{name} stopped"
    );
}


=pod
=begin classdoc

Base method to run one loop of the daemon.

=end classdoc
=cut

sub oneRun {
    my $self = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Base method to run one loop of the daemon.

=end classdoc
=cut

sub execnround {
    my ($self, %args) = @_;

    while ($args{run}) {
        $args{run} -= 1;

        # Refresh the configuration as it could be changed.
        $self->refreshConfiguration();

        $self->oneRun();
    }
}


=pod
=begin classdoc

Merge the daemon configuration with authentication conf.

=end classdoc
=cut

sub refreshConfiguration {
    my ($self, %args) = @_;

    # Retrieve the corresponding component
    eval {
        # Update the daemon configuration
        $self->{config} = $merge->merge($self->{config}, $self->_component->getConf());
    };
    if ($@) {
        my $err = "Could not find component corresponding to service <$self->{name}> " .
                  "on host <" . $self->_host->node->node_hostname . ">.";
        $log->warn($err);
    }
}


=pod
=begin classdoc

Prefix all logs by the name and pid of the daemon.

@param msg the log message
@param level the log level

=end classdoc
=cut

sub log {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'msg', 'level' ]);

    my $prefix = "[ $self->{name} - PID $$ ] ";

    my $method = $args{level};
    $log->$method($prefix . $args{msg});
}


=pod
=begin classdoc

Return/instanciate the host singleton.

=end classdoc
=cut

sub _host {
    my $self = shift;
    my %args = @_;

    return $host if defined $host;

    my $hostname = `hostname`;
    chomp($hostname);

    $host = EEntity->new(entity => Entity::Host->find(hash => { 'node.node_hostname' => $hostname }));
    return $host;
}


=pod
=begin classdoc

Return/instanciate the component singleton.

=end classdoc
=cut

sub _component {
    my $self = shift;
    my %args = @_;

    return $component if defined $component;

    $component = $self->_host->node->getComponent(name => 'Kanopya' . $self->{name});
    return $component;
}

1;
