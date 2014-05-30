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

use Kanopya::Database;
use Kanopya::Exceptions;
use Kanopya::Config;

use Manager::DaemonManager;

use IPC::Cmd;
use POSIX qw(setsid);
use Unix::PID::Tiny;

use Message;
use EEntity;
use Entity::Host;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use TryCatch;
my $err;

# The host on which the daemon is running.
my $host;

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

    my $self = { name => $args{name}, component => undef };
    bless $self, $class;

    # Get the authentication configuration
    $self->{config} = defined $args{confkey} ? Kanopya::Config::get($args{confkey}) : $args{config};

    try {
        General::checkParams(args => $self->{config}->{user}, required => [ "name", "password" ]);
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(
                  error => "Could not find <name> or/and <password> in the <user> configuration"
              );
    }

    # Authenticate the daemon to the api.
    Kanopya::Database::authenticate(login    => $self->{config}->{user}->{name},
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
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'daemonize' => 0, 'pidfile' => undef });

    $SIG{TERM} = $SIG{HUP} = $SIG{INT} = $SIG{QUIT} = sub {
        my ($sig) = @_;
        $log->info($sig . " signal received: stopping $self->{name} daemon");

        $self->stop();
    };

    if ($args{daemonize}) {
        $self->daemonize(%args);
    }

    if ($args{pidfile}) {
        my $pid = Unix::PID::Tiny->new();
        my $pid_result = $pid->pid_file($args{pidfile});
        if (!$pid_result) {
            my $err = "$args{name} is already running";
            $log->error($err);
            throw Kanopya::Exception::Daemon(error => $err);    	
        }
    }

    Message->send(
        from    => $self->{name},
        level   => 'info',
        content => "Kanopya $self->{name} started."
    );

    try {
        $log->info("Entering main loop");

        # execute the daemon main loop
        $self->runLoop();
    }
    catch ($err) {
        $log->error($err);
    }

    Message->send(
        from    => $self->{name},
        level   => 'warning',
        content => "Kanopya $self->{name} stopped"
    );
}


=pod
=begin classdoc

=end classdoc
=cut

sub runLoop {
    my $self = shift;

    $self->setRunning(running => 1);

    while ($self->isRunning) {
        $self->execnround(run => 1);
    }
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
    try {
        # Update the daemon configuration
        $self->{config} = $merge->merge($self->{config}, $self->_component->getConf());
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        $log->warn("Could not find component corresponding to service <$self->{name}> " .
                   "running on host <" . $self->_host->node->node_hostname . ">.");
    }
    catch ($err) {
        $err->rethrow();
    }
}


=pod
=begin

Stop the daemon.

=end classdoc
=cut

sub stop {
    my ($self, %args) = @_;

    # Interrupt the daemon event loop
    $self->setRunning(running => 0);

    $log->debug("Service stopped");
}


=pod
=begin

Daemonize the current process

=end classdoc
=cut

sub daemonize {
    my ($self, %args) = @_;

    $log->info("Daemonizing process");

    chdir '/';
    umask 0;

    open STDIN,  '/dev/null'   or die "Can't read /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $!";

    defined (my $pid = fork) or die "Can't fork: $!";
    exit if $pid;

    # dissociate this process from the controlling terminal that started it and stop being part
    # of whatever process group this process was a part of.
    POSIX::setsid() or die "Can't start a new session.";
}


=pod
=begin classdoc

Set the running prviate member.

@param running the running flag to set

=end classdoc
=cut

sub setRunning {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'running' ]);

    $self->{_running} = $args{running};
}


=pod
=begin classdoc

@return the running private member.

=end classdoc
=cut

sub isRunning {
    my ($self, %args) = @_;

    return ($self->{_running} == 1);
}


=pod
=begin classdoc

Return/instanciate the host singleton.

=end classdoc
=cut

sub _host {
    my $self = shift;

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

    return $self->{component} if defined $self->{component};

    try {
        $self->{component} = $self->_host->node->getComponent(name => 'Kanopya' . $self->{name});
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        $log->warn("Could not find component corresponding to service <$self->{name}> " .
                   "running on host <" . $self->_host->node->node_hostname . ">, " .
                   "using generic DaemonManager instead.");
        $self->{component} = Manager::DaemonManager->new();
    }
    catch ($err) {
        $err->rethrow();
    }

    return $self->{component};
}

=pod
=begin classdoc

Class method.

@return Listref A list of all HCM services that should normally be running

=end classdoc
=cut

sub daemonsToRun {
    return [ map ("kanopya-$_",
        qw(aggregator collector front executor mail-notifier openstack-sync rulesengine state-manager))
    ];
}

=pod
=begin classdoc

Class method.

@return Listref A list of HCM services that are currently running.

=end classdoc
=cut

sub runningDaemons {
    my ($class)= @_;
    
    my @all_services = @{ $class->daemonsToRun() };
    my $ps_auxww; 
    IPC::Cmd::run(command => "ps auxww", buffer  => \$ps_auxww);
    
    my @found_services = ();
    foreach my $service (@all_services) {
        my $search = quotemeta($service);
        if ($ps_auxww =~ /$search /) {
            push @found_services, $service;
        }
    }
    return \@found_services;
}

=pod
=begin classdoc

Class method.

@param name String Checks whether the given HCM service is running.
"HCM service" is any string returned by daemonsToRun().
The parameter can be a particular HCM service, "any" or "all".

@return Integer Boolean value: 1 or 0.

=end classdoc
=cut

sub isDaemonRunning {
    my ($class, %args)= @_;
    General::checkParams(args => \%args, required => [ 'name' ]);
    
    my @found_services = @{ $class->runningDaemons() };
    my @all_services   = @{ $class->daemonsToRun() };

    my $running = 0;
    if ($args{name0} eq 'any') {
        if (@found_services > 0) {
            $running = 1;
        }
    }
    elsif ($args{name} eq 'all') {
        if (scalar(@found_services) == scalar(@all_services)) {
            $running = 1;
        }
    }
    else {
        foreach my $found_service (@found_services) {
            if ($found_service eq $args{name}) {
                $running = 1;
            }
        }
    }
    return $running;
}

1;
