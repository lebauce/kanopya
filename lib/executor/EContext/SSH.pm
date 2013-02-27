# EContext::SSH.pm - EContext for remote execution using ssh connection

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=head1 NAME

EComponent - Abstract class of component object

=head1 SYNOPSIS



=head1 DESCRIPTION

EComponent is an abstract class of component objects

=head1 METHODS

=cut
package EContext::SSH;
use base "EContext";

use strict;
use warnings;
use Net::Ping;
if ($^O eq 'linux') {
    require Net::OpenSSH;
} elsif ( $^O eq 'MSWin32') {
    require Net::SSH::Perl;
}
use Log::Log4perl "get_logger";

use General;
use Kanopya::Exceptions;

my $log = get_logger("command");
my $errmsg;

our $VERSION = "1.00";


=head2 new

constructor

=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'ip' ]);

    my $self = $class->SUPER::new(%args);
    $self->{ip} = $args{ip};

    # is the host available on ssh port 22
    my $p = Net::Ping->new();
    $p->port_number(22);
    if(not $p->ping($args{ip}, 2)) {
        $p->close();
        $errmsg = "EContext::SSH->new : can't contact $args{ip} on port 22";
        $log->debug($errmsg);
        throw Kanopya::Exception::Network(error => $errmsg);
    }
    $p->close();
    $log->debug("Remote econtext ssh instanciate");
    bless $self, $class;
    return $self;
}

=head2 _init

    _init initialise ssh connection to the host

=cut

sub _init {
    my ($self) = @_;
    $log->debug("Initialise ssh connection to $self->{ip}");
    my %opts = (
        user        => 'root',                   # user login
        port        => 22,                       # TCP port number where the server is running
        key_path    => '/root/.ssh/kanopya_rsa', # Use the key stored on the given file path for authentication
        ssh_cmd     => '/usr/bin/ssh',           # full path to OpenSSH ssh binary
        scp_cmd     => '/usr/bin/scp',           # full path to OpenSSH scp binary
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


=head2 execute

execute ( command )
    desc: execute a command in a remote shell
    args:
        command : string: command to execute
    return:
        result ref hash containing stdout, stderr and exit code of execution

    WARNING: in your command, don't use stderr redirection ( 2> )

=cut

sub execute {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['command']);
    
    if($args{command} =~ m/2>/) {
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
    my ($stdout, $stderr) = $self->{ssh}->capture2($command);

    $result->{stdout} = $stdout;
    $result->{stderr} = $stderr;
    $result->{exitcode} = 0;
    chop($stdout);
    chop($stderr);
    my $error = $self->{ssh}->error;
    if($error) {
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

=head2 send

send(src => $srcfullpath, dest => $destfullpath)
    desc: send a file to a specific directory
    args:
        src : string: complete path to the file to send
        dest : string: complete path to the destination directory/file
    return:
        result ref hash containing resulting stdout and stderr

=cut

sub send {
    my ($self, %args) = @_;

    General::checkParams(args => %args, required => ['src', 'dest']);
    #TODO check to be sure src and dest are full path to files

    if(not -e $args{src}) {
        $errmsg = "EContext::SSH->execute src file $args{src} no found";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    if(not exists $self->{ssh}) {
        $self->_init();
    }

    my $success = $self->{ssh}->scp_put({ recursive => 1 }, $args{src}, $args{dest});
    # return TRUE if success
    if(not $success) {
        $errmsg = "EContext::SSH->send failed while putting $args{src} to $args{dest}!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
}




1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
