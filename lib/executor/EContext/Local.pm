# Local.pm - EContext::Local for local execution using system buitin function

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

EContext::Local  

=head1 SYNOPSIS



=head1 DESCRIPTION

EContext::Local offers execute method via system builtin function

=head1 METHODS

=cut
package EContext::Local;

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);

use base "EContext";
use Kanopya::Exceptions;

my $log = get_logger("executor");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 $localcontext

$localcontext use to make this class a singleton

=cut

my $localcontext;

=head2 new


    
=cut

sub new {
    my $class = shift;
    # do not reinstanciate local context, reuse 
    if(defined $localcontext) {
    	$log->info("EContext::Local instance retrieved");
    	return $localcontext;
    }
    my $self = {};
    bless $self, $class;
    $localcontext = $self;
	$log->info("new EContext::Local instance");
	return $self;
}

=head2 execute

execute ( command )
	desc: execute a command in shell
	args:
		command : string: command to execute
	return:
		result ref hash containing resulting stdout and stderr  
	
	WARNING: in your command, don't use stderr redirection ( 2> )
    
=cut

sub execute {
	my $self = shift;
	my %args = @_;
	if(! exists $args{command} or ! defined $args{command}) {
		$errmsg = "EContext::Local->execute need a command named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
	}
	
	# command must no contain stderr redirection !
	if($args{command} =~ m/2>/) {
		$errmsg = "EContext::Local->execute : command must not contain stderr redirection (2>)!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
	}
		
	my $result = {};
	my $command = $args{command};
	$log->debug("Command execute is : <$command>");
	$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin'; 
	my $stdout = `$command 2> /tmp/EContext.stderr`;
	$result->{exitcode} = $?;
	$result->{stdout} = $stdout;
	$result->{stderr} = `cat /tmp/EContext.stderr`;
	$log->debug("Command stdout is : '$result->{stdout}'");
	$log->debug("Command stderr is : '$result->{stderr}'");
	#if($result->{stderr}) {
		#throw Kanopya::Exception::Execution(
			#error => "EContext::Local->execute : got stderr: $result->{stderr}");
	#}
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
		$errmsg = "EContext::Local->execute need a src and dest named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg); 
	}
	if(not -e $args{src}) {
		$errmsg = "EContext::Local->execute src file $args{src} no found";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# TODO faire plus de test sur la destination
	my $result = {};
	my $command = "cp $args{src} $args{dest}";
	$log->debug("send Command is : <$command>");
	$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin'; 
	my $stdout = `$command 2> /tmp/EContext.stderr`;
	$result->{stdout} = $stdout;
	$result->{stderr} = `cat /tmp/EContext.stderr`;
	$log->debug("Command stdout is : '$result->{stdout}'");
	$log->debug("Command stderr is : '$result->{stderr}'");
	return $result;
}

=head2 DESTROY

	destructor : remove stored instance    
    
=cut

sub DESTROY {
	$localcontext = undef;
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
