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

<Executor> – <Executor main class>

=head1 VERSION

This documentation refers to <Executor> version 1.0.0.

=head1 SYNOPSIS

use <Executor>;


=head1 DESCRIPTION

Executor is the main execution class of executor service

=head1 METHODS

=cut

package Executor;

use strict;
use warnings;

use Log::Log4perl "get_logger";
our $VERSION = '1.00';
use General;
use Kanopya::Exceptions;
use Administrator;
use XML::Simple;
use Data::Dumper;
use EFactory;
use Operation;

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
	
	$self->{config} = XMLin("/etc/kanopya/executor.conf");
	if ((! exists $self->{config}->{user}->{name} ||
		 ! defined exists $self->{config}->{user}->{name}) &&
		(! exists $self->{config}->{user}->{password} ||
		 ! defined exists $self->{config}->{user}->{password})){ 
		throw Kanopya::Exception::Internal::IncorrectParam(error => "Executor->new need user definition in config file!"); }
	my $adm = Administrator::authenticate(login => $self->{config}->{user}->{name},
								 password => $self->{config}->{user}->{password});
	return;
}

=head2 run

Executor->run() run the executor server.

=cut

sub run {
	my $self = shift;
	my $running = shift;
	
	my $adm = Administrator->new();
	$adm->addMessage(from => 'Executor', level => 'info', content => "Kanopia Executor started.");
   	while ($$running) {
   		my $opdata = Operation::getNextOp();
   		if ($opdata){
	   		# start transaction
	   		my $op = EFactory::newEOperation(op => $opdata);
   			$log->info("New operation (".ref($op).") retrieve ; execution processing");
   			$adm->addMessage(from => 'Executor', level => 'info', content => "Executor begin an operation process (".ref($op).")");
   			$adm->{db}->txn_begin;
   			eval {
   			    eval {
   			        $op->prepare(internal_cluster => $self->{config}->{cluster});
   			    };
   			    if ($@) {
   			        my $error = $@;
   			        throw $error;
   			    }
   			    else {
   			        $op->execute();
   				     $op->finish();
   			    }
   			};
			if ($@) {
   				my $error = $@;
   				if($error->isa('Kanopya::Exception::Execution::OperationReported')) {
   					$op->report();
   					# commit transaction
   					$adm->{db}->txn_commit;
   					$adm->addMessage(from => 'Executor', level => 'info', content => ref($op)." reported");
   					$log->debug("Operation ".ref($op)." reported");
   				} else {
   					# rollback transaction
   					eval { $adm->{db}->txn_rollback; };
   					$adm->addMessage(from => 'Executor',level => 'error', content => ref($op)." abording: $error");
   					$log->error("Error during execution : $error");
   					$op->delete();
   				}
   			} else {
   				# commit transaction
   				$adm->{db}->txn_commit;
   				$adm->addMessage(from => 'Executor',level => 'info', content => ref($op)." processing finished");	
   				$op->delete();
   			}
   			
   		}
   		else { sleep 5; }
   	}
   	$log->debug("condition become false : $$running"); 
   	$adm->addMessage(from => 'Executor', level => 'warning', content => "Kanopia Executor stopped");
}

=head2 execnrun

Executor->execnround((run => $nbrun)) run the executor server for only one round.

=cut

sub execnround {
	my $self = shift;
	my %args = @_;

	my $adm = Administrator->new();

   	while ($args{run}) {
   	    $args{run} -= 1;
   		my $opdata = Operation::getNextOp();
   		if ($opdata){
	   		# start transaction
	   		my $op = EFactory::newEOperation(op => $opdata);
   			$log->info("New operation (".ref($op).") retrieve ; execution processing");
   			$adm->addMessage(from => 'Executor', level => 'info', content => "Executor begin an operation process (".ref($op).")");
   			$adm->{db}->txn_begin;
   			eval {
   			    eval {
   			        $op->prepare(internal_cluster => $self->{config}->{cluster});
   			    };
   			    if ($@) {
   			        my $error = $@;
   				    $adm->{db}->txn_rollback;
#   				    $adm->addMessage(from => 'Executor',level => 'error', content => ref($op)." abording: $error");
#   				    $log->error("Error during operation evaluation :\n$error");
   				    $op->delete();
   			        throw $error;
   			    }
   			    else {
   			        $op->execute();
   				    $op->finish();
   			    }
   			};
			if ($@) {
   				my $error = $@;
                throw $error;
   			} else {
   				# commit transaction
   				$adm->{db}->txn_commit;
   				$adm->addMessage(from => 'Executor',level => 'info', content => ref($op)." processing finished");	
   				$op->delete();
   			}
   			
   		}
   		else { sleep 5; }
   	}
}





1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
