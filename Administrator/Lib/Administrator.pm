# Administrator.pm - Object class of Administrator server

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

Administrator - Administrator object

=head1 SYNOPSIS

    use Executor;
    
    # Creates executor
    my $adm = Administrator->new();
    
    # Get object
    $adm->getobject($type : String, %ObjectDefinition);


=head1 DESCRIPTION

Administrator is the main object use to create administrator objects

=head1 METHODS

=cut

package Administrator;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use AdministratorDB::Schema;
use Data::Dumper;
use EntityRights;
use lib qw(../../Common/Lib);
use McsExceptions;

my $log = get_logger("administrator");

#$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $oneinstance;

=head2 Administrator::New (%args)
	
	Class : Public
	
	Desc : Instanciate Administrator object and check user authentication
	
	args: 
		login : String : user login to access to administrator
		password : String : user's password
	return: Administrator instance
	
=cut

sub new {
	my $class = shift;
	my %args = @_;
	
	if(defined $oneinstance) { return $oneinstance; }
	
	my $login = $args{login};
	my $password = $args{password};

	#TODO Load DB configuration from file 
	my $dbi = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %opts = ();
	my ($schema, $rightschecker);
	# Test if connection problem and catch exception
	
	print "Enter In new\n";
	eval {
		$log->debug("instanciating AdministratorDB::Schema");
		$schema = AdministratorDB::Schema->connect($dbi, $user, $pass, \%opts);
		print "adm->new : login $login, password $password\n";
	#TODO Understand why no catching exception from db connection but only 
	
	# When debug is set, all sql queries are printed
	# $schema->storage->debug(1); # or: $ENV{DBIC_TRACE} = 1 in any file

		$log->debug("instanciating EntityRights");
		$rightschecker = EntityRights->new( schema => $schema, login => $login, password => $password );
	};
	if ($@) {
#	print Dumper $@;
		#TODO Test exception type when exception are identified in EntityRight
		die $@;
		$log->error("Administrator->new : Error connecting Database");
		$@->rethrow();
		throw Mcs::Exception::DB(error => "Administrator->new : Database connection failed"); 
	}
	
	my $self = {
		db => $schema,
		_rightschecker => $rightschecker, 
	};
		
	bless $self, $class;
	$oneinstance = $self;
	return $self;
}

# private

=head2 Administrator::_getData(%args)
	
	Class : Private
	
	Desc : Instanciate dbix class mapped to corresponding raw in DB
	
	args: 
		table : String : DB table name
		id: Int : id of required entity in table
	return: db schema (dbix)
	
=cut
sub _getData {
	my $self = shift;
	my %args = @_;
	my $entitylink = lc($args{table})."_entities";
	return $self->{db}->resultset( $args{table} )->find(  $args{id}, 
		{ 	'+columns' => [ "$entitylink.entity_id" ], 
		join => ["$entitylink"] }
	);
	
}

=head2 _getAllData

	Class : Private

	Desc : Get all dbix class of table
	
	args:
		table : String : Table name
	return: resultset (dbix)
	
=cut

sub _getAllData {
	my $self = shift;
	my %args = @_;

	if (! exists $args{table} or ! defined $args{table}) { 
		throw Mcs::Exception::Internal(error => "Administrator->_getAllData need a table named argument!"); }


	my $entitylink = lc($args{table})."_entities";
	return $self->{db}->resultset( $args{table} )->search(undef, {'+columns' => [ "$entitylink.entity_id" ], 
		join => ["$entitylink"]});
}


=head2 _addData
	
	Class : Private
	
	Desc : Instanciate dbix class filled with <params>, add a corresponding row in DB
	
	args: 
		table : String : DB table name
		row: hash ref : representing the new row (key mapped on <table> columns)
	return: db schema (dbix)
	
=cut

sub _addData {
	my $self = shift;
	my %args  = @_;	
	#$args{params} = {} if !$args{params};
	
	if ((! exists $args{table} or ! defined $args{table}) ||
		(! exists $args{row} or ! defined $args{row})) { 
		throw Mcs::Exception::Internal(error => "Administrator->_allData need a table and row named argument!"); }
	
	
	my $new_obj = $self->{db}->resultset($args{table} )->create( $args{row} );
	return $new_obj;	
}


=head2 _newData
	
	Class : Private
	
	Desc : Instanciate dbix class filled with <params>, doesn't add in DB
	
	args: 
		table : String : DB table name
		row: hash ref : representing the new row (key mapped on <table> columns)
	return: db schema (dbix)

=cut

sub _newData {
	my $self = shift;
	my %args  = @_;	
	#$args{params} = {} if !$args{params};	

	if ((! exists $args{table} or ! defined $args{table}) ||
		(! exists $args{row} or ! defined $args{row})) { 
		throw Mcs::Exception::Internal(error => "Administrator->_newData need a table and row named argument!"); }

	
	my $new_obj = $self->{db}->resultset(  $args{table} )->new( $args{row} );
	
	return $new_obj;
}


=head2 _newObj
	
	Class : Private
	
	Desc : Instanciate concrete Entity
	
	args: 
		type : concrete entity type
		data : db schema (dbix)
	
=cut

sub _newObj {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{type} or ! defined $args{type})) { 
		throw Mcs::Exception::Internal(error => "Administrator->_newObj need a data and type named argument!"); }


    my $requested_type = $args{type};
    my $location = $requested_type;
    $location =~ s/::/\//;     
    $location = "Entity/$location.pm";
    my $obj_class = "Entity::$requested_type";
    require $location;   

    return $obj_class->new( data => $args{data}, rightschecker => $self->{_rightschecker} );
}

=head2 getObj
	
	Class : Public
	
	Desc : This method allows to get entity object. It
			get _data from table with _getData
			call _newObj on _data
	
	args: 
		type : String : Object Type
		id : int : Object id
	Return : a new Entity::<type> with data corresponding to <id> (in <type> table)
	Comment : To modify data in DB call save() on returned obj (after modification)
	
=cut

sub getObj {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{id} or ! defined $args{id})) { 
		throw Mcs::Exception::Internal(error => "Administrator->newOp need a type and an id named argument!"); }

	$log->debug( "getObj( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );

	$log->debug( "_getData with table = $args{type} and id = $args{id}");
	my $obj_data = $self->_getData( table => $args{type}, id => $args{id} );
	my $new_obj;
	if ( defined $obj_data ) {
		$log->debug( "_newObj with type = $args{type} and data of " . ref($obj_data));
		$new_obj = $self->_newObj( type => $args{type}, data => $obj_data );
	}
	else {
		$log->warn( "Administrator::getObj( ", map( { "$_ => $args{$_}, " } keys(%args) ), ") : Object not found!");
		throw Mcs::Exception::Internal(error => "Administrator::get Obj : Object not found");
		#return undef;
	}
	$log->debug( "Return newObj of " . ref($new_obj));
    return $new_obj;
}

=head2 getAllObjs
	
	Class : Public
	
	Desc : This method allows to get many entity objects. It
			get all allowed object from calling _getAllData
	
	args: 
		type : String : Objects type
	Return new Entities::<type> with data corresponding to <id> (in <type> table)
	To modify data in DB call save() on returned obj (after modification)
	
=cut

sub getAllObjs {
	my $self = shift;
    my %args = @_;
	
	if (! exists $args{type}) { 
		throw Mcs::Exception::Internal(error => "Administrator->newOp need a type named argument!"); }
	
	my @objs = ();
	my $rs = $self->_getAllData( table => $args{type} );
	while ( my $raw = $rs->next ) {
		my $obj = $self->_newObj( type => $args{type}, data => $raw );
		push @objs, $obj;
	}    
    return  @objs;
}


=head2 newObj
	
	Class : Public
	
	Desc : This method allows to instanciate entity object from hash table
			It Calls _newData and _newObj
	args: 
		type: concrete Entity type
		params: hash ref with key mapped on <type> table column
		
	Return a New Entity::<type> with params as data (not add in db)
	To add data in DB call save() on returned obj
	 
=cut

sub newObj {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{params} or ! defined $args{params})) { 
		throw Mcs::Exception::Internal(error => "Administrator->newObj need params and type named argument!"); }

	$log->info( "newObj( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );


	my $obj_data = $self->_newData( table =>  $args{type}, row => $args{params} );
	my $new_obj = $self->_newObj( type => $args{type}, data => $obj_data );
	
	warn( "Administrator::newObj( .. ) : Object creation failed!" ) if (  not defined $obj_data );
	
    return $new_obj;
}

=head2 new Op
	
	Class : Public
	
	Desc : This method allows to instanciate entity object from hash table
			It Calls _newData and _newObj
	args : 
		type : concrete Entity::Operation type (Real Operation type (AddMotherboard, MigrateNode, ...))
		params : hash ref with key mapped on <type> table column
		priority : Operation priority (<1000)
		
	Return a New Entity::Operation::type with data from hash (params)
	This Operation is immediatly saved
	
=cut

sub newOp {
	my $self = shift;
	my %args = @_;
	
		if ((! exists $args{priority} or ! defined $args{priority}) ||
			(! exists $args{type} or ! defined $args{type}) ||
			(! exists $args{params} or ! defined $args{params})) { 
		throw Mcs::Exception::Internal(error => "Administrator->newOp need a priority, params and type named argument!"); }
	#TODO Check if operation is allowed
	my $rank = $self->_get_lastRank() + 1;
	my $user_id = $self->{_rightschecker}->{_user};
	my $op_data = $self->_newData( table => 'Operation', row => { 	type => $args{type},
																	execution_rank => $rank,
																	user_id => $user_id,
																	priority => $args{priority}});
	my $op = $self->_newObj(type => "Operation::". $args{type}, data => $op_data) ;
	$self->_saveOp(op => $op);
	$op->addParams($args{params});
	return $op;
}

=head2 _saveOp

	Class : Private
	
	Desc : Save operation and its entity id in database
	args : 
		op : Entity::Operation::OperationType : 
			concrete Entity::Operation type (Real Operation type (AddMotherboard, MigrateNode, ...))

=cut

sub _saveOp {
	my $self = shift;
	my %args = @_;
	
	throw Mcs::Exception::Internal(error => "Try to save object not operation") if (
													(!exists $args{op})||
													(! $args{op}->isa('Entity::Operation')));

	my $newentity = $args{op}->{_data}->insert;
	$log->debug("new Operation inserted.");
	my $row = $args{op}->{_rightschecker}->{_schema}->resultset('Entity')->create(
		{ "operation_entities" => [ { "operation_id" => $newentity->get_column("operation_id")} ] },
	);
	$log->debug("new operation $args{op} inserted with his entity relation.");
	$args{op}->{_entity_id} = $row->get_column('entity_id');
}

=head2 _getLastRank

	Class : Private
	
	Desc : This method return last operation number

=cut

sub _get_lastRank{
	return 0;
}

=head2 getNextOp
	
	Class : Public
	
	Desc : This method return next operation to execute

	Returns the concrete Operation with the execution_rank min 
	
=cut

sub getNextOp {
	my $self = shift;
	
	my $all_ops = $self->_getAllData( table => 'Operation' );
	my $op_data = $all_ops->search( {}, { order_by => { -asc => 'execution_rank' }  } )->next();
	
	throw Mcs::Exception::Internal(error => "No more operation in queue!") if ( !$op_data );
	
	my $op_type = $op_data->type;

	my $op = $self->_newObj( type => "Operation::$op_type", data => $op_data );
	$log->warn("Data Class is : Operation::$op_type");

	return $op;
}

=head2 getNextOp
	
	Class : Public
	
	Desc : This method change user in context administrator.
	
	Args :
		user_id : Int : User Id which will be the new user
	
=cut

sub changeUser {
	my $self = shift;
	my %args = @_;
	if (! exists $args{user_id} or ! defined $args{user_id}) { 
		throw Mcs::Exception::Internal(error => "Administrator->changeUser need a user_id named argument!"); }
	my $nextuser = $self->getObj(type => "User",id => $args{user_id});
	$self->{_rightschecker}->{_userbackup} = $self->{_rightschecker}->{_user};
	$self->{_rightschecker}->{_user} = $nextuser;
} 

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut