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

use lib qw (/workspace/mcs/Executor/Lib /workspace/mcs/Common/Lib);
use base "EContext";
use McsExceptions;

my $log = get_logger("executor");

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
    	$log->debug("EContext::Local instance already exists, return it");
    	return $localcontext;
    }
    my $self = {};
    bless $self, $class;
    $localcontext = $self;
	return $self;
}

=head2 new

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
		throw Mcs::Exception::Internal::IncorrectParam(
			error => "EContext::Local->execute need a command named argument!"); 
	}
	
	# command must no contain stderr redirection !
	if($args{command} =~ m/2>/) {
		throw Mcs::Exception::Internal::IncorrectParam(
			error => "EContext::Local->execute : command must not contain stderr redirection (2>)!"); 
	}
		
	my $result = {};
	my $command = $args{command};
	$log->debug("Command execute is : <$command>");
	$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin'; 
	my $stdout = `$command 2> /tmp/EContext.stderr`;
	$result->{stdout} = $stdout;
	$result->{stderr} = `cat /tmp/EContext.stderr`;
	$log->debug("Command stdout is : '$result->{stdout}'");
	$log->debug("Command stderr is : '$result->{stderr}'");
	if($result->{stderr}) {
		throw Mcs::Exception::Execution(
			error => "EContext::Local->execute : got stderr: $result->{stderr}");
	}
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