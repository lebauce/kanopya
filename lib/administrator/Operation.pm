# Operation.pm - Operation class, this is an abstract class

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

Operation.pm - Operation class, this is an abstract class

=head1 SYNOPSIS

This Object represent an operation.

=head1 DESCRIPTION


=head1 METHODS

=cut

package Operation;
use base 'BaseDB';

use strict;
use warnings;

use General;
use Workflow;
use Kanopya::Exceptions;
use DateTime;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
our $VERSION = '1.00';
my $errmsg;

sub enqueue {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => [ 'priority', 'type' ]);

    # check for an identical operation in the queue
    my $params = $args{params};
    my @hash_keys = keys %$params;
    my $adm = Administrator->new();
    my $nbparams = scalar(@hash_keys);
    my $op_params = [];

    if (defined $args{params}) {
        $op_params = Workflow->buildParams(hash => $args{params});
    }

#    my $op_rs = $adm->{db}->resultset('Operation')->search(
#                    { type => $args{type}, 
#                      -or  => $op_params, },
#                    { select   => [ { count => 'operation_parameters.operation_id', -as => 'mycount'} ],
#                      join     => 'operation_parameters',
#                      group_by => 'operation_parameters.operation_id',
#                      having   => { 'mycount' => $nbparams } }
#                );
#
#    my @rows = $op_rs->all;
#    if(scalar(@rows)) {
#        $errmsg = "An operation with exactly same parameters already enqueued !";
#        throw Kanopya::Exception::OperationAlreadyEnqueued(error => $errmsg);
#    }

    $args{params} = $op_params;
    return Operation->new(%args);
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};

    General::checkParams(args => \%args, required => [ 'priority', 'type' ]);

    my $adm = Administrator->new();

    # If workflow not defined, initiate a new one with parameters
    if (not defined $args{workflow_id}) {
        my $workflow = Workflow->new();
        if (defined $args{params}) {
            $workflow->setParams(params => $args{params});
        }

        $args{workflow_id} = $workflow->getAttr(name => 'workflow_id');
    }

    my $hoped_execution_time = defined $args{hoped_execution_time} ? time + $args{hoped_execution_time} : undef;
    my $execution_rank = $class->getNextRank(workflow_id => $args{workflow_id});
    my $user_id = $adm->{_rightchecker}->{user_id};

    $log->info("Enqueuing new operation <$args{type}>, in workflow <$args{workflow_id}>, " .
                 "with params:\n" . Dumper(\$args{params}));

    my $row = {
        type                 => $args{type},
        execution_rank       => $execution_rank,
        workflow_id          => $args{workflow_id},
        user_id              => $user_id,
        priority             => $args{priority},
        creation_date        => \"CURRENT_DATE()",
        creation_time        => \"CURRENT_TIME()",
        hoped_execution_time => $hoped_execution_time,
    };

    $self->{_dbix} = $adm->{db}->resultset('Operation')->create($row);
    $log->info(ref($self)." saved to database (added in execution list)");

    bless $self, $class;

    return $self;
}

=head2 getNextOp
    
    Class : Public
    
    Desc : This method return next operation to execute

    Returns the concrete Operation with the execution_rank min 
    
=cut

sub getNextOp {
    my $adm = Administrator->new();
    # Get all operation
    my $all_ops = $adm->_getDbixFromHash( table => 'Operation', hash => {});
    #$log->debug("Get Operation $all_ops");
    
    # Choose the next operation to be treated :
    # if hoped_execution_time is definied, value returned by time function must be superior to hoped_execution_time
    # unless operation is not execute at this moment
    #$log->error("Time is : ", time);
    my $opdata = $all_ops->search( 
        { -or => [ hoped_execution_time => undef, hoped_execution_time => {'<',time}] }, 
#        { order_by => { -asc => 'execution_rank' }}
        { order_by => { -asc => 'operation_id' }}
    )->next();
    if (! defined $opdata){
        #$log->info("No operation in queue");
        return;
    }
    my $op = Operation->get(id => $opdata->get_column("operation_id"));
    $log->info("Operation execution: ".$op->getAttr(name => 'type'));
    return $op;
}

=head2 delete
    
    Class : Public
    
    Desc : This method delete Operation and its parameters
    
=cut

sub delete {
    my $self = shift;

    my $adm = Administrator->new();

    my $op_status = "Done";
    if ($self->{cancelled}){
        $op_status = "Cancelled";
    }

    my $new_old_op = $adm->_newDbix(
        table => 'OldOperation',
        row => {
            type             => $self->getAttr(name => "type"),
            workflow_id      => $self->getAttr(name => "workflow_id"),
            user_id          => $self->getAttr(name => "user_id"),
            priority         => $self->getAttr(name => "priority"),
            creation_date    => $self->getAttr(name => "creation_date"),
            creation_time    => $self->getAttr(name => "creation_time"),
            execution_date   => \"CURRENT_DATE()",
            execution_time   => \"CURRENT_TIME()",
            execution_status => $op_status,
        }
    );
    $new_old_op->insert;

    $self->{_dbix}->delete();
    $log->info(ref($self)." deleted from database (removed from execution list)");
}

sub getWorkflow {
    my $self = shift;
    my %args = @_;

    # my $workflow = $self->getRelation(name => 'workflow');
    return Workflow->get(id => $self->getAttr(name => 'workflow_id'));
}
=head2 getParams
    
    Class : Public
    
    Desc : This method returns all params
    
    Return : hashref : all parameters of operation
=cut

sub getParams {
    my $self = shift;
    my %params;

    return $self->getWorkflow->getParams();
}

=head setHopedExecutionTime
    modify the field value hoped_execution_time in database
    arg: value : duration in seconds 
=cut

sub setHopedExecutionTime {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['value']);
    
    my $t = time + $args{value};
    $self->{_dbix}->set_column('hoped_execution_time', $t);
    $self->{_dbix}->update;
    $log->debug("hoped_execution_time updated with value : $t");
}

sub getNextRank {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'workflow_id' ]);

    my $adm = Administrator->new();
    my $row = $adm->{db}->resultset('Operation')->search(
                  { workflow_id => $args{workflow_id} },
                  { column   => 'execution_rank',
                    order_by => [ 'execution_rank desc' ]}
              )->first;

    if (! $row) {
        $log->debug("No previous operation in queue for workflow $args{workflow_id}");
        return 0;
    }
    else {
        my $last_in_db = $row->get_column('execution_rank');
        $log->debug("Previous operation in queue is $last_in_db");
        return $last_in_db + 1;
    }
}

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'state', value => $args{state});
    $self->save();
}

1;
