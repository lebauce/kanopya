# Executor.pm - Object class of Executor server

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

Executor - Executor object

=head1 SYNOPSIS

    use Executor;
    
    # Creates executor
    my $executor = Executor->new();
    
    # Create object
    $executor->newobject($type : String, %ObjectDefinition);


=head1 DESCRIPTION

Executor is the main object use to create execution objects

=head1 METHODS

=cut
package Executor;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib /workspace/mcs/Executor/Lib);
use General;
use McsExceptions;
use Administrator;
use XML::Simple;
use Data::Dumper;
use EFactory;

my $log = get_logger("executor");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $executor = Executor->new();

Executor::new creates a new executor object.

=cut

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;
        
   $self->_init();
    
    # Plus tard rajouter autre chose
    return $self;
}

=head2 _init

Executor::_init is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;
	
	$self->{config} = XMLin("/workspace/mcs/Executor/Conf/executor.conf");
	if ((! exists $self->{config}->{user}->{name} ||
		 ! defined exists $self->{config}->{user}->{name}) &&
		(! exists $self->{config}->{user}->{password} ||
		 ! defined exists $self->{config}->{user}->{password})){ 
		throw Mcs::Exception::Internal::IncorrectParam(error => "Executor->new need user definition in config file!"); }
	my $adm = Administrator->new(login => $self->{config}->{user}->{name},
								 password => $self->{config}->{user}->{password});
	return;
}

=head2 run

Executor->run() run the executor server.

=cut

sub run {
	my $self = shift;
	my $running = shift;
	
	$log->warn("Before New Administrator");
	my $adm = Administrator->new();
	$log->warn("After New Administrator"); 
   	while ($$running) {
   		my $opdata = $adm->getNextOp();
   		if ($opdata){
	   		my $op = EFactory::newEEntity(data => $opdata);
   			$log->info("New operation (".ref($op).") retrieve ; execution processing");
   			$adm->addMessage(type => 'info', content => "Executor begin an operation process (".ref($op).")");
   			eval {
   				$op->prepare(internal_cluster => $self->{config}->{cluster});
   				$op->execute();
   				$op->finish();
   				$adm->addMessage(type => 'success', content => ref($op)." processing finished");
   			};
			if ($@) {
   				my $error = $@;
   				$op->cancel();
   				$adm->addMessage(type => 'error', content => ref($op)." abording: $error");
   				$log->error("Error during execution : $error");
   			}
   		}
   		else {
   			$log->debug("nothing to execute ; waiting 20 seconds before asking execution list again");
   			sleep 20;
   		}
   	}
   	$log->debug("condition become false : $$running"); 
}

=head2 execnrun

Executor->execnround((run => $nbrun)) run the executor server for only one round.

=cut

sub execnround {
	my $self = shift;
	my %args = @_;

	my $adm = Administrator->new();

   	while ($args{run}) {
   		my $opdata = $adm->getNextOp();
   		if ($opdata){
   				$log->warn("Get Next Operation, its type is ".ref($opdata));
   				my $op = EFactory::newEEntity(data => $opdata);
   			eval {
   				$op->prepare(internal_cluster => $self->{config}->{cluster}, internal_net => $self->{config}->{internalnetwork});
   				$log->info("Operation execution");
   				$op->execute();
   				$log->info("Operation finishing");
   				$op->finish();
   				$log->info("Operation finished");
   			};
			if ($@) {
   				my $error = $@;
   				$op->cancel();
   				$log->error("Error during execution : $error");
   				print Dumper $error;
   			}
   			$args{run}--;

   		} else {
   			$log->debug('5 secondes waiting before next round');
   			sleep 20;
   		
   		}
   	} 
}





1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
