# Operation.pm - Operation class, this is an abstract class

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Hedera Technology sas.

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

Operation.pm - Operation class, this is an abstract class

=head1 SYNOPSIS

This Object represent an operation.

=head1 DESCRIPTION


=head1 METHODS

=cut

package Operation;

use strict;
use warnings;

use Log::Log4perl "get_logger";

use Kanopya::Exceptions;

my $log = get_logger("administrator");
our $VERSION = '1.00';
my $errmsg;

sub new {
    my $class = shift;
	my %args = @_;
	my $self = {};
	if ((! exists $args{priority} or ! defined $args{priority}) ||
		(! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{params} or ! defined $args{params})) {
			$errmsg = "Operation->new need a priority, params and type named argument!";
			$log->error($errmsg); 
			throw Kanopya::Exception::Internal(error => $errmsg); 
	}
	my $adm = Administrator->new();
	$self->{hoped_execution_time} = defined $args{hoped_execution_time} ? time + $args{hoped_execution_time} : undef; 
	#TODO Check if operation is allowed
	$self->{execution_rank} = $adm->_get_lastRank() + 1;
	$self->{user_id} = $self->{_rightschecker}->{_user};
	$self->{type} = $args{type};
	
	$log->debug("User id in _rightschecker is $self->{user_id}");
	$self->{_dbix} = $adm->_newDbix( table => 'Operation', row => { 	type => $args{type},
																	execution_rank => $self->{execution_rank},
																	user_id => $self->{user_id},
																	priority => $args{priority},
																	creation_date => \"CURRENT_DATE()",
																	creation_time => \"CURRENT_TIME()",
																	hoped_execution_time => $self->{hoped_execution_time}
																	});
	bless $self, $class;
    #TODO CHoose if op is saved during new
    # Here Insert in db directly. 	
	$self->{_dbix}->insert;
	my $params = $args{params};
	foreach my $k (keys %$params) {
		$self->{_dbix}->create_related( 'operation_parameters', { name => $k, value => $params->{$k} } );}
	$log->info(ref($self)." saved to database (added in execution list)");

    return $self;
}

=head2 new
	
	Class : Public
	
	Desc : This method instanciate Operation.
	
	Args :
		rightschecker : Rightschecker : Object use to check write and update entity_id
		data : DBIx class: object data
		params : hashref : Operation parameters
	Return : Operation, this class could not be instanciated !!
	
=cut

=head2 getNextOp
	
	Class : Public
	
	Desc : This method return next operation to execute

	Returns the concrete Operation with the execution_rank min 
	
=cut

sub getNextOp {
	my $adm = Administrator->new();
	# Get all operation
	my $all_ops = $adm->_getDbixFromHash( table => 'Operation', hash => {});
	$log->debug("Get Operation $all_ops");
	
	# Choose the next operation to be treated :
	# if hoped_execution_time is definied, value returned by time function must be superior to hoped_execution_time
	# unless operation is not execute at this moment
	$log->error("Time is : ", time);
	my $op_data = $all_ops->search( 
		{ -or => [ hoped_execution_time => undef, hoped_execution_time => {'<',time}] }, 
		{ order_by => { -asc => 'execution_rank' }}   
	)->next();
	
	# if no other operation to Operation::$subclassbe treated, return undef
	if(! defined $op_data) { 
		$log->info("No operation left in the queue");
		return;
	}
	# Get the operation type
	my $op_type = 
	
	my $op_hoped_exec_time = $op_data->get_column('type');
	
	# Get Operation parameters
	my $params_rs = $op_data->operation_parameters;
	my %params;
	while ( my $param = $params_rs->next ) {
		$params{ $param->name } = $param->value;
	}
	$log->debug("Parameters get <" . %params . ">");
	# Try to load Operation::$op_type
	eval {
		$log->debug("op_type: ".$op_type);
		my $class = "Operation/$op_type.pm";
		require $class;
	};
	if ($@) {
		$errmsg = "Administrator->newOp : Operation type <$op_type> does not exist!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}

	# Operation instanciation
	my $op = Operation->new(data => $op_data, params => \%params);
	$log->info(ref($op) . " retrieved from database (next operation from execution list)");
	return $op;
}

sub getType{
    my $self = shift;
    return $self->{_dbix}->get_column('type');
}

sub oldnew {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{administrator} or ! defined $args{administrator})||
		(! exists $args{params} or ! defined $args{params})) { 
		$errmsg = "Operation->new need a data, params and administrator named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
    
    # Here Check if users can execution this operation (We have the rightschecker)

    my $self = {
		_rightschecker => $args{administrator}->{_rightschecker},
        _dbix => $args{data},
        _params => $args{params},
    };
    bless $self, $class;
    return $self;
}

=head2 delete
	
	Class : Public
	
	Desc : This method delete Operation and its parameters
	
=cut

sub delete {
	my $self = shift;

	my $params_rs = $self->{_dbix}->operation_parameters;
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

	if (! exists $args{attr_name} or ! defined $args{attr_name}) { 
		$errmsg = "Operation->getAttr need an attr_name named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}

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
	if (! exists $args{value} or ! defined $args{value}) { 
		$errmsg = "Operation->setHopedExecutionTime need a value named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $t = time + $args{value};
	$self->{_dbix}->set_column('hoped_execution_time', $t);
	$self->{_dbix}->update;
	$log->debug("hoped_execution_time updated with value : $t");
}

1;
