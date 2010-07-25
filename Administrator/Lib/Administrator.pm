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
use Data::Dumper;
use lib qw(. ../../Common/Lib);
use AdministratorDB::Schema;
use EntityRights;
use McsExceptions;
use General;
use Entity;

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
	
	# If Administrator exists return its already existing instance
	if(defined $oneinstance) { return $oneinstance; }
	
	# Check named arguments
	if ((! exists $args{login} or ! defined $args{login})||
		(! exists $args{password} or ! defined $args{password})) { 
		throw Mcs::Exception::Internal(error => "Administrator->_getAllData need a table named argument!"); }
	
	my $login = $args{login};
	my $password = $args{password};

	#TODO Load DB configuration from file 
	my $dbi = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %opts = ();
	my ($schema, $rightschecker);
	
	# Catch exception from DB connection
	eval {
		$log->debug("instanciating AdministratorDB::Schema");
		$schema = AdministratorDB::Schema->connect($dbi, $user, $pass, \%opts);
		print "adm->new : login $login, password $password\n";

		# When debug is set, all sql queries are printed
		# $schema->storage->debug(1); # or: $ENV{DBIC_TRACE} = 1 in any file

		$log->debug("instanciating EntityRights");
		$rightschecker = EntityRights->new( schema => $schema, login => $login, password => $password );
	};
	if ($@) {
		$log->error("Administrator->new : Error connecting Database");
		die $@;
	}
	
	my $self = {
		db => $schema,
		_rightschecker => $rightschecker, 
	};
		
	bless $self, $class;
	# Add singleton
	$oneinstance = $self;
	return $self;
}


=head2 getEntity
	
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

sub getEntity {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{id} or ! defined $args{id})) { 
		throw Mcs::Exception::Internal(error => "Administrator->_getEntity need a type and an id named argument!"); }

	$log->debug( "getEntity( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );

	$log->debug( "_getEntity with table = $args{type} and id = $args{id}");
	my $entity_dbix = $self->_getDbix( table => $args{type}, id => $args{id} );
	my $new_obj;
	
	# Test if Dbix is get
	if ( defined $entity_dbix ) {
		$log->debug( "getEntity with type = $args{type} and data of " . ref($entity_dbix));
		my $entity_class = _getEntityClass(type => $args{type});
		return $entity_class->new( type => $args{type}, data => $entity_dbix );
	}
	else {
		$log->warn( "Administrator::getEntity( ", map( { "$_ => $args{$_}, " } keys(%args) ), ") : Object not found!");
		throw Mcs::Exception::Internal(error => "Administrator::getEntity : Object not found");
	}
}

=head2 getEntities
	
	Class : Public
	
	Desc : This method allows to get many entity objects. It
			get all allowed object from calling _getAllData
	
	args: 
		type : String : Objects type
	Return new Entities::<type> with data corresponding to <id> (in <type> table)
	To modify data in DB call save() on returned obj (after modification)
	
=cut

sub getEntities {
	my $self = shift;
    my %args = @_;
	
	if (! exists $args{type}) { 
		throw Mcs::Exception::Internal(error => "Administrator->newOp need a type named argument!"); }
	
	my @objs = ();
	my $rs = $self->_getAllDbix( table => $args{type} );
	my $entity_class = _getEntityClass(type => $args{type});
	while ( my $raw = $rs->next ) {
		my $obj = $entity_class->new(rightschecker => $self->{_rightschecker}, data => $raw );
		push @objs, $obj;
	}    
    return  @objs;
}


=head2 newEntity
	
	Class : Public
	
	Desc : This method allows to instanciate entity object from hash table
			It Calls _newData and _newObj
	args: 
		type: concrete Entity type
		params: hash ref with key mapped on <type> table column
		
	Return a New Entity::<type> with params as data (not add in db)
	To add data in DB call save() on returned obj
	 
=cut

sub newEntity {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{params} or ! defined $args{params})) { 
		throw Mcs::Exception::Internal(error => "Administrator->newObj need params and type named argument!"); }

	$log->info( "newObj( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );

	# We get class and require Entity::$entity_class
	my $entity_class = _getEntityClass(type => $args{type});
	
	# We check entity attributes and separate them in two categories :
	#	- ext_attrs
	#	- global_attrs
	
	my $attrs = $entity_class->checkAttrs(attr => $args{params});
	
	# We create a new DBIx containing new entity (only global attrs)
	my $entity_data = $self->_newDbix( table =>  $args{type}, row => $attrs->{global_attrs} );
	
	warn( "Administrator::newEntity( .. ) : Object creation failed!" ) if (  not defined $entity_data );
	
	# We instanciate entity with DBIx data and rightchecker
	my $new_obj = $entity_class->new( data => $entity_data, rightschecker => $self->{_rightschecker} );

	# We add extended params to entity
	
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
	my $op_data = $self->_newDbix( table => 'Operation', row => { 	type => $args{type},
																	execution_rank => $rank,
																	user_id => $user_id,
																	priority => $args{priority}});

	my $subclass = $args{type};
	eval {
		require "Operation::$subclass";
	};
	if ($@) {
		throw Mcs::Exception::Internal(error => "Administrator->newOp : Operation type does not exist!");}

	my $op = "Operation::$subclass"->new(data => $op_data, rightschecker => $self->{_rightschecker}, params => $args{params});
	$op->save();
	# We do not return the operation to user.
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
	
	# Get all operation
	my $all_ops = $self->_getAllData( table => 'Operation' );
	# Choose the next operation to be trated
	my $op_data = $all_ops->search( {}, { order_by => { -asc => 'execution_rank' }  } )->next();
	# if no other operation to be treated, send an exception
	throw Mcs::Exception::Internal(error => "No more operation in queue!") if ( !$op_data );
	# Get the operation type
	my $op_type = $op_data->type;
	
	# Get Operation parameters
	my $params_rs = $op_data->operation_parameters;
	my %params;
	while ( my $param = $params_rs->next ) {
		$params{ $param->name } = $param->value;
	}
	# Try to load Operation::$op_type
	eval {
		require "Operation::$op_type";
	};
	if ($@) {
		throw Mcs::Exception::Internal(error => "Administrator->newOp : Operation type does not exist!");}

	# Operation instanciation
	my $op = "Operation::$op_type"->new(data => $op_data, rightschecker => $self->{_rightschecker}, params => \%params);

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
	my $nextuser = $self->getEntity(type => "User",id => $args{user_id});
	$self->{_rightschecker}->{_userbackup} = $self->{_rightschecker}->{_user};
	$self->{_rightschecker}->{_user} = $nextuser;
} 


=head2 Administrator::_getDbix(%args)
	
	Class : Private
	
	Desc : Instanciate dbix class mapped to corresponding raw in DB
	
	args: 
		table : String : DB table name
		id: Int : id of required entity in table
	return: db schema (dbix)
	
=cut
sub _getDbix {
	my $self = shift;
	my %args = @_;
	my $entitylink = lc($args{table})."_entities";
	return $self->{db}->resultset( $args{table} )->find(  $args{id}, 
		{ 	'+columns' => [ "$entitylink.entity_id" ], 
		join => ["$entitylink"] }
	);
	
}

=head2 _getAllDbix

	Class : Private

	Desc : Get all dbix class of table
	
	args:
		table : String : Table name
	return: resultset (dbix)
	
=cut

sub _getAllDbix {
	my $self = shift;
	my %args = @_;

	if (! exists $args{table} or ! defined $args{table}) { 
		throw Mcs::Exception::Internal(error => "Administrator->_getAllData need a table named argument!"); }

	my $entitylink = lc($args{table})."_entities";
	return $self->{db}->resultset( $args{table} )->search(undef, {'+columns' => [ "$entitylink.entity_id" ], 
		join => ["$entitylink"]});
}


=head2 _newDbix
	
	Class : Private
	
	Desc : Instanciate dbix class filled with <params>, doesn't add in DB
	
	args: 
		table : String : DB table name
		row: hash ref : representing the new row (key mapped on <table> columns)
	return: db schema (dbix)

=cut

sub _newDbix {
	my $self = shift;
	my %args  = @_;	
	#$args{params} = {} if !$args{params};	

	if ((! exists $args{table} or ! defined $args{table}) ||
		(! exists $args{row} or ! defined $args{row})) { 
		throw Mcs::Exception::Internal(error => "Administrator->_newData need a table and row named argument!"); }

	my $new_obj = $self->{db}->resultset(  $args{table} )->new( $args{row} );
	return $new_obj;
}


=head2 _getEntityClass
	
	Class : Private
	
	Desc : Make good require during an Entity Instanciation
	
	args: 
		type : concrete entity type	
	return: Entity class
=cut

sub _getEntityClass{
	my $self = shift;
    my %args = @_;

	if (! exists $args{type} or ! defined $args{type}) { 
		throw Mcs::Exception::Internal(error => "Administrator->_requireEntity a type named argument!"); }

	my $entity_class = General::getEntityFromType(%args);
    my $location = General::getLocFromClass(entityclass => $entity_class);

    require $location;
    
	return $entity_class;
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut