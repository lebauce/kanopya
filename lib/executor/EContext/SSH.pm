#    Copyright 2011-2012 Hedera Technology SAS
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

The ssh econtext offers execute method using ssh connection to the remote host.

@since    2010-Nov-23
@instance hash
@self     $self

=end classdoc

=cut

package EContext::SSH;
use base "EContext";

use strict;
use warnings;

use General;
use Kanopya::Exceptions;

use Net::Ping;

use Net::OpenSSH;


use Log::Log4perl "get_logger";
my $log = get_logger("command");
my $errmsg;


=pod

=begin classdoc

@constructor

Instanciate a SSH econtext using the ip of the destination host.

@return a class instance

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'ip', 'timeout' ],
                         optional => { username => 'root', key => undef,
                                       port => 22 });

    my $self = {
        ip       => $args{ip},
        port     => $args{port},
        timeout  => $args{timeout},
        username => $args{username},
        key      => $args{key}
    };

    # is the host available on ssh port 22
    my $p = Net::Ping->new();
    $p->port_number(22);
    if (not $p->ping($args{ip}, 2)) {
        $p->close();
        $errmsg = "EContext::SSH->new : can't contact $args{ip} on port $args{port}";
        $log->debug($errmsg);
        throw Kanopya::Exception::Network(error => $errmsg);
    }
    $p->close();
    $log->debug("Remote econtext ssh instanciate");

    bless $self, $class;
    return $self;
}


=cut

=pod

=begin classdoc

Initialise ssh connection to the host

=end classdoc

=cut

sub _init {
    my ($self) = @_;

    $log->debug("Initialise ssh connection to $self->{ip}");
    my %opts = (
        user        => $self->{username},
        port        => $self->{port},
        key_path    => $self->{key},
        ssh_cmd     => '/usr/bin/ssh',
        scp_cmd     => '/usr/bin/scp',
        master_opts => [
         -o => "StrictHostKeyChecking=no"
        ],
        timeout => $self->{timeout},
        #kill_ssh_on_timeout => 1
    );

    my $ssh = Net::OpenSSH->new($self->{ip}, %opts);
    if($ssh->error) {
        my $errmsg = "SSH connection failed: " . $ssh->error;
        $log->error($errmsg);
        throw Kanopya::Exception::Network(error => $errmsg);
    }
    $self->{ssh} = $ssh;
}


=pod
=begin classdoc

execute ( command )
    desc: execute a command in a remote shell
    args:
        command : string: command to execute
    return:
        result ref hash containing stdout, stderr and exit code of execution

    WARNING: in your command, don't use stderr redirection ( 2> )

Use the OpenSSH module to execute the command remotely.
NOTE: don't use stderr redirection ( 2> ) in your command.

@param command the command to execute

@return the command result

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'command' ],
                                         optional => { 'timeout' => $self->{timeout} });

    if ($args{command} =~ m/2>/) {
        $errmsg = "EContext::SSH->execute : command must not contain stderr redirection (2>)!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    if(not exists $self->{ssh}) {
        $self->_init();
    }

    my $result = {};
    my $command = $args{command};
    $log->info("Running command on $self->{ip}: $command");
    my ($stdout, $stderr) = $self->{ssh}->capture2({ timeout => $args{timeout} },
                                                   $command);

    $result->{stdout} = $stdout;
    $result->{stderr} = $stderr;
    $result->{exitcode} = 0;
    chop($stdout);
    chop($stderr);
    my $error = $self->{ssh}->error;
    if ($error) {
         if($error =~ /child exited with code (\d)/) {
             $result->{exitcode} = $1;

         } else {
             $errmsg = "EContext::SSH->execute : error occured during execution: ".$error;
             $log->error($errmsg);
             throw Kanopya::Exception::Execution(error => $errmsg);
         }
    } else {
        $log->debug("Command stdout is : '$stdout'");
        $log->debug("Command stderr: $stderr");
        $log->debug("Command exitcode: $result->{exitcode}");
    }
    return $result;
}


=pod
=begin classdoc

Use the OpenSSH module to copy the local file to remote host.

@param src the source file to copy
@param dest the destionation to copy file

@return the command result

=end classdoc
=cut

sub send {
    my ($self, %args) = @_;

    General::checkParams(args => %args, required => [ 'src', 'dest' ],
                                        optional => { mode => undef,
                                                      user => undef,
                                                      group => undef });

    if (not -e $args{src}) {
        $errmsg = "EContext::SSH->execute src file $args{src} no found";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    if (not exists $self->{ssh}) {
        $self->_init();
    }

    if ($args{user} || $args{group}) {
        $self->execute(command => "chown -R $args{user}:$args{group} $args{src}");
    }

    if ($args{mode}) {
        $self->execute(command => "chmod -R $args{mode} $args{src}");
    }

    my $success = $self->{ssh}->scp_put({ recursive => 1, copy_attrs => 1 },
                                        $args{src}, $args{dest});

    # return TRUE if success
    if (not $success) {
        $errmsg = "EContext::SSH->send failed while putting $args{src} to $args{dest}!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
}

=pod
=begin classdoc

Use the OpenSSH module to retrieve file from remote host.

@param src the source file or folder to copy
@param dest the destination file or folder

@return the command result

=end classdoc
=cut

sub retrieve {
    my ($self, %args) = @_;

    General::checkParams(args => %args, required => [ 'src', 'dest' ]);

    if (not exists $self->{ssh}) {
        $self->_init();
    }

    my $success = $self->{ssh}->scp_get({ recursive => 1, copy_attrs => 1 },
                                          $args{src}, $args{dest});

    # return TRUE if success
    if (not $success) {
        $errmsg = "EContext::SSH->retrieve failed while getting $args{src} to $args{dest}!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

1;
