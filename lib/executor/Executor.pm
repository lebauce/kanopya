# Executor.pm - Object class of Executor server

#    Copyright © 2011 Hedera Technology SAS
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
use Message;

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
    
    $self->{config} = XMLin("/opt/kanopya/conf/executor.conf");
    General::checkParams(args=>$self->{config}->{user}, required=>["name","password"]);

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
    
    Message->send(from => 'Executor', level => 'info', content => "Kanopya Executor started.");
       while ($$running) {
           $self->oneRun();
       }
       $log->debug("condition become false : $$running"); 
       Message->send(from => 'Executor', level => 'warning', content => "Kanopya Executor stopped");
}

sub oneRun {
    my $self = shift;
    my $adm = Administrator->new();
    $log->debug("Try to get an operation");
    my $opdata = Operation::getNextOp();
    
    if ($opdata){
        # start transaction
        $opdata->setProcessing();
        my $op = EFactory::newEOperation(op => $opdata);
        
        $log->info("New operation (".ref($op).") retrieve ; execution processing");
        Message->send(from => 'Executor', level => 'info', content => "Executor begin an operation process (".ref($op).")");
        
        $adm->{db}->txn_begin;
        eval {
            $op->prepare(internal_cluster => $self->{config}->{cluster});
            $op->process();
        };
        if ($@) {
            my $error = $@;
            if($error->isa('Kanopya::Exception::Execution::OperationReported')) {
                $op->report();
                # commit transaction
                $adm->{db}->txn_commit;
                Message->send(from => 'Executor', level => 'info', content => ref($op)." reported");
                $log->debug("Operation ".ref($op)." reported");
            } else {
                # rollback transaction
                $adm->{db}->txn_rollback;
                $log->info("Rollback, Cancel operation will be call");
                eval {
                    $adm->{db}->txn_begin;
                    $op->cancel();
                    $adm->{db}->txn_commit;};
                if ($@){
                    my $error2 = $@;
                    $log->error("Error during operation cancel :\n$error2");
                }
                if (!$error->{hidden}){
                    Message->send(from => 'Executor',level => 'error', content => ref($op)." abording:<br/> $error");
                    $log->error("Error during execution : $error");} 
                else {
                    $log->info("Warning : $error");}
           }
        } else {
                   # commit transaction
                   $op->finish();
                   $adm->{db}->txn_commit;
                   Message->send(from => 'Executor',level => 'info', content => ref($op)." processing finished");    
        }
        eval {$op->delete();};
        if ($@) {
            my $error = $@;
            $log->error("Error during operation deletion : $error"); 
            Message->send(from => 'Executor', level => 'error', content => "Error during operation deletion : $error");}
     }
     else { sleep 5; }
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
           $self->oneRun();
       }
}





1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
