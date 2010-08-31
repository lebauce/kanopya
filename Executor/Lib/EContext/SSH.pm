# EContext::SSH.pm - EContext for remote execution using ssh connection

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

EComponent - Abstract class of component object

=head1 SYNOPSIS



=head1 DESCRIPTION

EComponent is an abstract class of component objects

=head1 METHODS

=cut
package EContext::SSH;

use strict;
use warnings;
use Data::Dumper;
use Net::Ping;
use GRID::Machine qw/is_operative/;

use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);

use lib qw(/workspace/mcs/Executor/Lib /workspace/mcs/Common/Lib);
use base "EContext";
use McsExceptions;

my $log = get_logger("executor");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head $sshcontexts

store EContext::SSH instances to avoid many ssh connections on the same host 

=cut

my $sshcontexts = {};

=head2 new

constructor
    
=cut

sub new {
    my $class = shift;
    my %args = @_;
    # do not reinstanciate existing ssh context, reuse 
    if(exists $sshcontexts->{$args{ip}}) {
    	$log->info("EContext::SSH instance for $args{ip} retrieved");
    	return $sshcontexts->{$args{ip}};
    }
    
    my $self = {
    	ip => $args{ip},
    };
    
    # is the host available on ssh port 22
    my $p = Net::Ping->new();
    $p->port_number(22);
    if(not $p->ping($args{ip}, 2)) {
    	$p->close();
    	$errmsg = "EContext::SSH->new : can't contact $args{ip} on port 22";
    	$log->error($errmsg);
    	throw Mcs::Exception::Network(error => $errmsg);	
    }
    $p->close();
    
    # TODO better checking with is_operative
   	#my $host = "root\@$args{ip}";
   	# to verify if connection to $host can be done,
	# try to connect with $host and execute hostname in less than 1 seconds 
	#$log->debug("using GRID::Machine::is_operative to test the connection");
	#eval { is_operative('ssh', $host, 'hostname', 1); };
	#if($@) {	
	#	throw Mcs::Exception::Network(error => "EContext::SSH->new : $@"); 
	#}
	bless $self, $class;
	$sshcontexts->{$args{ip}} = $self;	
	return $self;
}

=head2 _init

	_init initialise ssh connection to the host 

=cut

sub _init {
	my $self = shift;
	$log->debug("Initialise ssh connection to $self->{ip}");
	my $m  = GRID::Machine->new(
		host => "root\@$self->{ip}",	# host to contact
		prefix => '/tmp/perl5lib',				# directory on remote host to install perl code
		startdir => '/tmp',						# initial working directory on remote host
		log => '/tmp/rperl$$.log',				# execution stdout on remote host 
		err => '/tmp/rperl$$.err',				# execution stderr on remote host
		cleanup => 1,							# delete stdout and stderr files when finish
		sendstdout => 1							# ?
	);
	$self->{machine} = $m;
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
	my $self = shift;
	my %args = @_;
	if(! exists $args{command} or ! defined $args{command}) {
		$errmsg = "EContext::SSH->execute need a command named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg); 
	}
	
	if($args{command} =~ m/2>/) {
		$errmsg = "EContext::SSH->execute : command must not contain stderr redirection (2>)!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg); 
	}
		
	if(not exists $self->{machine}) {
		$log->debug("Initialize ssh connection on $self->{ip}");
		$self->_init();
	}	
		
	my $result = {};
	my $command = $args{command};
	$log->debug("Command execute is : <$command>");
	my $r = $self->{machine}->system($command);
	if(not $r->ok) {
		$errmsg = "EContext::SSH->execute RPC failed";
		$log->error($errmsg);
		throw Mcs::Exception::Network(error => $errmsg);
	}
	$result->{stdout} = $r->stdout;
	chomp($result->{stdout});
	$result->{stderr} = $r->stderr;
	chomp($result->{stderr});
	$log->debug("Command stdout is : '$result->{stdout}'");
	$log->debug("Command stderr is : '$result->{stderr}'");
	if($result->{stderr}) {
		$errmsg = "EContext::SSH->execute : got stderr: $result->{stderr}";
		$log->error($errmsg);
		throw Mcs::Exception::Execution(error => $errmsg);
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
	my $self = shift;
	my %args = @_;
	#TODO check to be sure src and dest are full path to files
	if((! exists $args{src} or ! defined $args{src}) ||
	   (! exists $args{dest} or ! defined $args{dest})) {
		$errmsg = "EContext::SSH->execute need a src and dest named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg); 
	}
	if(not -e $args{src}) {
		$errmsg = "EContext::SSH->execute src file $args{src} no found";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongParam(error => $errmsg);
	}
	
	if(not exists $self->{machine}) {
		$log->debug("Initialize ssh connection on $self->{ip}");
		$self->_init();
	}
	my $result = $self->{machine}->put([$args{src}], $args{dest});
	# return TRUE if success
	if(not $result) {
		$errmsg = "EContext::SSH->send failed while putting $args{src} to $args{dest}!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg); 
	}
}
	

=head2 DESTROY

	destructor : remove stored instance    
    
=cut

sub DESTROY {
	my $self = shift;
	delete $sshcontexts->{$self->{ip}};
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut