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

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl "get_logger";
use General;
use Kanopya::Exceptions;
use DateTime;

my $log = get_logger("administrator");
our $VERSION = '1.00';
my $errmsg;

sub enqueue {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['priority','type','params']);
    
    my $params = $args{params};
    my @hash_keys = keys %$params;
    foreach my $key (@hash_keys) {
        if (! defined $params->{$key}){
            $errmsg = "Operation->enqueue needs defined params";
            $log->error($errmsg); 
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    }
    my $adm = Administrator->new();
    my $nbparams = scalar(@hash_keys);
    my $whereclause = [];
    while( my ($key, $value) = each %{$args{params}}) {
        $log->debug("key $key value $value");
        push @$whereclause, {name => $key, value =>$value};
    }
        
    my $op_rs = $adm->{db}->resultset('Operation')->search(
        {    type => $args{type}, 
            -or => $whereclause,
        },
        {     select => [{ count => 'operation_parameters.operation_id', -as => 'mycount'}],
            join => 'operation_parameters',
            group_by => 'operation_parameters.operation_id',
            having => { 'mycount' => $nbparams }
        }
    );
    my @rows = $op_rs->all;
    if(scalar(@rows)) {
        $errmsg = "An operation with exactly same parameters already enqueued !";
        throw Kanopya::Exception::OperationAlreadyEnqueued(error => $errmsg);
    }
    
    #$log->debug("-------------------> total count : ".(scalar(@rows)));
       
    my $operation = Operation->new(%args);
    $operation->save();
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    
    General::checkParams(args => \%args, required => ['priority','type','params']);
    
    my $adm = Administrator->new();
    
    my $hoped_execution_time = defined $args{hoped_execution_time} ? time + $args{hoped_execution_time} : undef; 
    my $execution_rank = $adm->_get_lastRank() + 1;
    my $user_id = $adm->{_rightchecker}->{user_id};
    
    $self->{_dbix} = $adm->_newDbix( table => 'Operation', row => {     type => $args{type},
                                                                    execution_rank => $execution_rank,
                                                                    user_id => $user_id,
                                                                    priority => $args{priority},
                                                                    creation_date => \"CURRENT_DATE()",
                                                                    creation_time => \"CURRENT_TIME()",
                                                                    hoped_execution_time => $hoped_execution_time
                                                                    });
    $self->{_params} = $args{params};
    bless $self, $class;

    return $self;
}

=head2 get
    
    Class : Public
    
    Desc : This method instanciate Operation.
    
    Args :
        data : DBIx class: object data
        params : hashref : Operation parameters
    Return : Operation, this class could not be instanciated !!
    
=cut

sub get {
    my $class = shift;
    my %args = @_;
    my $self = {};
    
    General::checkParams(args => \%args, required => ['id']);

    my $adm = Administrator->new();
    $self->{_dbix} = $adm->{db}->resultset( "Operation" )->find(  $args{id});
#    $self->{_dbix} = $adm->getRow(id=>$args{id}, table => "Operation");
    # Get Operation parameters
    my $params_rs = $self->{_dbix}->operation_parameters;
    my %params;
    while ( my $param = $params_rs->next ) {
        $params{ $param->name } = $param->value;
    }
    $self->{_params} = \%params;
    $log->debug("Parameters ", Dumper (%params));
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
        { order_by => { -asc => 'execution_rank' }}   
    )->next();
    if (! defined $opdata){
        #$log->info("No operation in queue");
        return;
    }
    my $op = Operation->get(id => $opdata->get_column("operation_id"));
    $log->info("Operation execution: ".$op->getAttr(attr_name => 'type'));
    return $op;
}

sub getType{
    my $self = shift;
    return $self->{_dbix}->get_column('type');
}

=head2 delete
    
    Class : Public
    
    Desc : This method delete Operation and its parameters
    
=cut

sub delete {
    my $self = shift;

    my $params_rs = $self->{_dbix}->operation_parameters;
    my $adm = Administrator->new();
    my $op_status = "Done";
    if ($self->{cancelled}){
        $op_status = "Cancelled";
    }
    my $params = $self->getParams();
    my $new_old_op = $adm->_newDbix( table => 'OldOperation', row => {type => $self->getAttr(attr_name =>"type"),
                                                                    user_id => $self->getAttr(attr_name =>"user_id"),
                                                                    priority => $self->getAttr(attr_name =>"priority"),
                                                                    creation_date =>$self->getAttr(attr_name =>"creation_date"),
                                                                    creation_time => $self->getAttr(attr_name =>"creation_time"),
                                                                    execution_date => \"CURRENT_DATE()",
                                                                    execution_time => \"CURRENT_TIME()",
                                                                    execution_status => $op_status,
                                                                    });
    $new_old_op->insert;
    foreach my $k (keys %$params) {
        $new_old_op->create_related( 'old_operation_parameters', { name => $k, value => $params->{$k} } );}

    $params_rs->delete;
    $self->{_dbix}->delete();
    $log->info(ref($self)." deleted from database (removed from execution list)");
}

=head2 getAttr
    
    Class : Public
    
    Desc : This method return operation Attr specified in args
    
    args :
        attr_name : String : Attribute name
    
    Return : String : Parameter specified
    
=cut

sub getAttr {
    my $self = shift;
    my %args = @_;
    my $value;

    General::checkParams(args => \%args, required => ['attr_name']);

    if ( $self->{_dbix}->has_column( $args{attr_name} ) ) {
        $value = $self->{_dbix}->get_column( $args{attr_name} );
        $log->debug(ref($self) . " getAttr of $args{attr_name} : $value");
    } else {
        $errmsg = "Operation->getAttr : Wrong value asked!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    return $value;
}

=head2 getParams
    
    Class : Public
    
    Desc : This method returns all params 
    
    Return : hashref : all parameters of operation
=cut

sub getParams {
    my $self = shift;
    my %params;

    my $params_rs = $self->{_dbix}->operation_parameters;
    while (my $param = $params_rs->next){
        $params{$param->name} = $param->value;
    }
    return \%params;
}

=head2 save

    Class : Public
    
    Desc : Save operation and its params
    args : 
        op : Entity::Operation::OperationType : 
            concrete Entity::Operation type (Real Operation type (AddMotherboard, MigrateNode, ...))

=cut

sub save {
    my $self = shift;

    my $newentity = $self->{_dbix}->insert;
    my $params = $self->{_params};
    
    foreach my $k (keys %$params) {
        $self->{_dbix}->create_related( 'operation_parameters', { name => $k, value => $params->{$k} } );}
    $log->info(ref($self)." saved to database (added in execution list)");
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

=head setProcessing
    Set execution_rank to 0, it signifies that operation is in execution
=cut

sub setProcessing {
    my $self = shift;
    $self->{_dbix}->update({'execution_rank' => 0});
}

1;
