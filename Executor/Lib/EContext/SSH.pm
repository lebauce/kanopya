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

use lib "../", "../../../Common/Lib";
use base "EContext";
use McsExceptions;

my $log = get_logger("executor");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    
=cut

# to keep instances and retrieve them without reinstanciate an object
my $connections = {};
sub connections { return $connections; }


sub new {
    my $class = shift;
    my %args = @_;
    
    if(exists $connections->{$args{ip}}) {
    	return $connections->{$args{ip}};
    }
    
    my $self = {
    	ip => $args{ip},
    };
    
    # is the host available on ssh port 22
    my $p = Net::Ping->new();
    $p->port_number(22);
    if(not $p->ping($args{ip}, 2)) {
    	$p->close();
    	throw Mcs::Exception::Network(error => "EContext::SSH->new : can't contact $args{ip} on port 22");	
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
	return $self;
}

=head2 _init

	_init initialise ssh connection to the host 

=cut

sub _init {
	my $self = shift;
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
	$connections->{$self->{ip}} = $self;
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
		throw Mcs::Exception::Internal::IncorrectParam(
			error => "EContext::Local->execute need a command named argument!"); 
	}
	
	if($args{command} =~ m/2>/) {
		throw Mcs::Exception::Internal::IncorrectParam(
			error => "EContext::Local->execute : command must not contain stderr redirection (2>)!"); 
	}
		
	if(not exists $self->{machine}) {
		$log->debug("Initialize ssh connection on $self->{ip}");
		$self->_init();
	}	
		
	my $result = {};
	my $command = $args{command};
	$log->debug("command: $command");
	my $r = $self->{machine}->system($command);
	if(not $r->ok) {
		throw Mcs::Exception::Network(error => "EContext::SSH->execute RPC failed");
	}
	$log->debug("STDOUT: ".$r->stdout);
	$log->debug("STDERR: ".$r->stderr);
		
	$result->{stdout} = $r->stdout;
	chomp($result->{stdout});
	$result->{stderr} = $r->stderr;
	chomp($result->{stderr});
	return $result;	
}

=head2 DESTROY

=cut

sub DESTROY {
	my $self = shift;
	$log->debug("Removing instance from catalog");
	delete $connections->{$self->{ip}}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut