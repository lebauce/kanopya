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

    use Administrator;
    
    # Creates administrator
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
use NetAddr::IP;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use AdministratorDB::Schema;
use EntityRights;
use McsExceptions;
use General;
use Entity;
use XML::Simple;

my $log = get_logger("administrator");
my $errmsg;

#$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $oneinstance;

=head2 Administrator::new (%args)
	
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
	if(defined $oneinstance) { 
		$log->info("Administrator instance retrieved");	
		return $oneinstance;
	}
	
	# Check named arguments
	if ((! exists $args{login} or ! defined $args{login})||
		(! exists $args{password} or ! defined $args{password})) { 
		$errmsg = "Administrator->need a login and password named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg); 
	}
	
	my $login = $args{login};
	my $password = $args{password};
	
	my %opts = ();
	my ($schema, $rightschecker);
	my $self = {};
	
	bless $self, $class;
	# Load Administrator config
	# Add singleton
	# Catch exception from DB connection
	eval {
		my $dbi = $self->loadConf();
		$log->debug("dbi connection : $dbi, user : $self->{config}->{dbconf}->{user}, password : $self->{config}->{dbconf}->{password}");
		$schema = AdministratorDB::Schema->connect($dbi, $self->{config}->{dbconf}->{user}, $self->{config}->{dbconf}->{password}, \%opts);

		# When debug is set, all sql queries are printed
		# $schema->storage->debug(1); # or: $ENV{DBIC_TRACE} = 1 in any file
		
		$rightschecker = EntityRights->new( schema => $schema, login => $login, password => $password );
	};
	if ($@) {
		my $error = $@;
		$log->error("Administrator->new : Error connecting Database $error");
		throw Mcs::Exception::DB(error => "$error"); 
	}
	
	$self->{db} = $schema;
	$self->{_rightschecker} = $rightschecker;		
	$oneinstance = $self;
	$log->info("new Administrator instance");
	return $self;
}

=head Administrator::loadConf

=cut

sub loadConf {
	my $self = shift;
	$self->{config} = XMLin("/workspace/mcs/Administrator/Conf/administrator.conf");
	if (! exists $self->{config}->{internalnetwork}->{ip} ||
		! defined $self->{config}->{internalnetwork}->{ip} ||
		! exists $self->{config}->{internalnetwork}->{mask} ||
		! defined $self->{config}->{internalnetwork}->{mask} ||
		! exists $self->{config}->{internalnetwork}->{gateway} ||
		! defined $self->{config}->{internalnetwork}->{gateway})
		{
			$errmsg = "Administrator->new need internalnetwork definition in config file!";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	
	if (! exists $self->{config}->{dbconf}->{name} ||
		! defined exists $self->{config}->{dbconf}->{name} ||
		! exists $self->{config}->{dbconf}->{password} ||
		! defined exists $self->{config}->{dbconf}->{password} ||
		! exists $self->{config}->{dbconf}->{type} ||
		! defined exists $self->{config}->{dbconf}->{type} ||
		! exists $self->{config}->{dbconf}->{host} ||
		! defined exists $self->{config}->{dbconf}->{host} ||
		! exists $self->{config}->{dbconf}->{user} ||
		! defined exists $self->{config}->{dbconf}->{user} ||
		! exists $self->{config}->{dbconf}->{port} ||
		! defined exists $self->{config}->{dbconf}->{port})
		{
			$errmsg = "Administrator->new need db definition in config file!";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}

	$log->info("Administrator configuration loaded");
	return "dbi:" . $self->{config}->{dbconf}->{type} .
			":" . $self->{config}->{dbconf}->{name} .
			":" . $self->{config}->{dbconf}->{host} .
			":" . $self->{config}->{dbconf}->{port};
}

=head2 getEntity
	
	Class : Public
	
	Desc : This method allows to get entity object. It
			get _data from table with _getData
			call _newObj on _data
	
	args: 
		type : String : Object Type
		id : int : Object id
		class_path : String : This is an optionnal parameter which allow to instanciate class_path with other DB tables
	Return : a new Entity::<type> with data corresponding to <id> (in <type> table)
	Comment : To modify data in DB call save() on returned obj (after modification)
	
=cut

sub getEntity {
	my $self = shift;
    my %args = @_;
    
    # entity_dbix will contain resultset row integrated into Entity
    # entity_class is Entity Class
    my ($entity_dbix, $entity_class);

	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Administrator->_getEntity need a type and an id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg); 
	}
	
	$log->debug( "getEntity( ".join(', ', map( { "$_ => $args{$_}" } keys(%args) )). ");" );
	$log->debug( "_getDbix with table = $args{type} and id = $args{id}");
	$entity_dbix = $self->_getDbix( table => $args{type}, id => $args{id} );
	
	# Test if Dbix is get
	if ( defined $entity_dbix ) {
		$log->debug( "_getEntityClass with type = $args{type}");
		if (! exists $args{class_path} or ! defined $args{class_path}){
			 $entity_class = $self->_getEntityClass(type => $args{type});}
		else {
			$entity_class = $self->_getEntityClass(type => $args{type}, class_path => $args{class_path});}

		# Extension Entity Management
		my $extension = $entity_class->extension();
		if ($extension){
			$log->debug("GetEntity with extension");
			my %attrs;
			my $ext_attrs_rs = $entity_dbix->search_related( $extension );
			while ( my $param = $ext_attrs_rs->next ) {
				$attrs{ $param->name } = $param->value;
			}
			my $entity = $entity_class->new( rightschecker => $self->{_rightschecker}, data => $entity_dbix, ext_attrs => \%attrs); 
			$log->info(ref($entity)." retrieved from database");
			return $entity;
		} else {
			my $entity = $entity_class->new( rightschecker => $self->{_rightschecker}, data => $entity_dbix );
			$log->info(ref($entity)." retrieved from database");
			return $entity;
		}
	} else {
		$errmsg = "Administrator::getEntity(".join(', ', map( { "$_ => $args{$_}" } keys(%args) )). ") : Object not found!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
}

=head2 getEntities
	
	Class : Public
	
	Desc : This method allows to get many entity objects. It
			get allowed object corresponding to where clause in hash param
	
	args: 
		type : String : Objects type
		hash : hashref : this hash describe field and constraint for search
	Return Entities hash 
	
=cut

sub getEntities {
	my $self = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

#TODO FAire du like et pas du where!!
	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Administrator->_getEntityFromHash need a type and a hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	$log->debug( "getEntityFromHash( ".join(', ', map( { "$_ => $args{$_}" } keys(%args) )). ");" );
	$log->debug( "_getDbix with table = $args{type} and hash = $args{hash}");
	$rs = $self->_getDbixFromHash( table => $args{type}, hash => $args{hash} );
	
	$log->debug( "_getEntityClass with type = $args{type}");
	if (! exists $args{class_path} or ! defined $args{class_path}){
		 $entity_class = $self->_getEntityClass(type => $args{type});}
	else {
		$entity_class = $self->_getEntityClass(type => $args{type}, class_path => $args{class_path});}

	my $extension = $entity_class->extension();

	while ( my $raw = $rs->next ) {
		my $obj;
		if ($extension){
			my %attrs;
			my $ext_attrs_rs = $raw->search_related( $extension );
			while ( my $param = $ext_attrs_rs->next ) {
				$attrs{ $param->name } = $param->value;}
			$obj = $entity_class->new(rightschecker => $self->{_rightschecker}, data => $raw, ext_attrs => \%attrs);}
		else {
			$obj = $entity_class->new(rightschecker => $self->{_rightschecker}, data => $raw );}
		push @objs, $obj;
	}
	return  @objs;
}


#sub getEntities {
#	my $self = shift;
#    my %args = @_;
#	
#	if (! exists $args{type}) { 
#		throw Mcs::Exception::Internal(error => "Administrator->newOp need a type named argument!"); }
#	
#	my @objs = ();
#	my $rs = $self->_getAllDbix( table => $args{type} );
#	my $entity_class = $self->_getEntityClass(type => $args{type});
#	my $extension = $entity_class->extension();
#	while ( my $raw = $rs->next ) {
#		my $obj;
#		if ($extension){
#			my %attrs;
#			my $ext_attrs_rs = $raw->search_related( $extension );
#			while ( my $param = $ext_attrs_rs->next ) {
#				$attrs{ $param->name } = $param->value;}
#			$obj = $entity_class->new(rightschecker => $self->{_rightschecker}, data => $raw, ext_attrs => \%attrs);}
#		else {
#			$obj = $entity_class->new(rightschecker => $self->{_rightschecker}, data => $raw );}
#		push @objs, $obj;
#	}
#    return  @objs;
#}

=head2 countEntities 

	args:
		type : concrete Entity type
	
	Return an integer	

=cut

sub countEntities {
	my $self = shift;
	my %args = @_;
	if (! exists $args{type} or ! defined $args{type}) { 
		$errmsg = "Administrator->countEntities need a type named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg); 
	}
	my $count = $self->{db}->resultset($args{type})->count;
	$log->debug("Total number of entities $args{type} : $count");
	return $count;
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
		$errmsg = "Administrator->newEntity need params and type named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg); 
	}

	$log->debug("newEntity(".join(', ', map( { "$_ => $args{$_}" } keys(%args) )).")");

	# We get class and require Entity::$entity_class
	my $entity_class;
	if (! exists $args{class_path} or ! defined $args{class_path}){
		$entity_class = $self->_getEntityClass(type => $args{type});
	} else {
		$entity_class = $self->_getEntityClass(type => $args{type}, class_path => $args{class_path});}
	
	# We check entity attributes and separate them in two categories :
	#	- ext_attrs
	#	- global_attrs
	my $attrs = $entity_class->checkAttrs(attrs => $args{params});
	
	# We create a new DBIx containing new entity (only global attrs)
	my $entity_data = $self->_newDbix( table =>  $args{type}, row => $attrs->{global} );
	
	# We instanciate entity with DBIx data and rightchecker
	my $new_entity;
	if ($entity_class->extension()) {
		$new_entity = $entity_class->new( data => $entity_data, rightschecker => $self->{_rightschecker}, ext_attrs => $attrs->{extended});
	}
	else {
		$new_entity = $entity_class->new( data => $entity_data, rightschecker => $self->{_rightschecker});
	}
	$log->info(ref($new_entity)." instanciated");
    return $new_entity;
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
			$errmsg = "Administrator->newOp need a priority, params and type named argument!";
			$log->error($errmsg); 
			throw Mcs::Exception::Internal(error => $errmsg); 
	}
	#TODO Check if operation is allowed
	my $rank = $self->_get_lastRank() + 1;
	#TODO Put the good user in operation
	my $user_id = $self->{_rightschecker}->{_user};
#	my $user_id = 16;
	$log->debug("User id in _rightschecker is $user_id");
	my $op_data = $self->_newDbix( table => 'Operation', row => { 	type => $args{type},
																	execution_rank => $rank,
																	user_id => $user_id,
																	priority => $args{priority},
																	creation_date => \"CURRENT_DATE()",
																	creation_time => \"CURRENT_TIME()"
																	});

	my $subclass = $args{type};
	eval {
		require "Operation/$subclass.pm";
	};
	if ($@) {
		$errmsg = "Administrator->newOp : Operation type ($args{type}) does not exist when require Operation::$subclass.pm";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}

	my $op = "Operation::$subclass"->new(data => $op_data, administrator => $self, params => $args{params});
	$op->save();
	# We do not return the operation to user.
}

=head2 _getLastRank

	Class : Private
	
	Desc : This method return last operation number

=cut

sub _get_lastRank{
	my $self = shift;
	my $row = $self->{db}->resultset('Operation')->search(undef, {column => 'execution_rank', order_by=> ['execution_rank desc']})->first;
	if (! $row) {
		$log->debug("No previous operation in queue");
		return 0;
	}
	else {
		my $last_in_db = $row->get_column('execution_rank');
		$log->debug("Previous operation in queue is $last_in_db");
		return $last_in_db;	
	}
}

=head2 getNextOp
	
	Class : Public
	
	Desc : This method return next operation to execute

	Returns the concrete Operation with the execution_rank min 
	
=cut

sub getNextOp {
	my $self = shift;
	
	# Get all operation
	my $all_ops = $self->_getDbixFromHash( table => 'Operation', hash => {});
	$log->debug("Get Operation $all_ops");
	# Choose the next operation to be trated
	my $op_data = $all_ops->search( {}, { order_by => { -asc => 'execution_rank' }  } )->next();
	# if no other operation to Operation::$subclassbe treated, return undef
	if(! defined $op_data) { 
		$log->info("No operation left in the queue");
		return undef;
	}
	# Get the operation type
	my $op_type = $op_data->get_column('type');
	
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
		require "Operation/$op_type.pm";
	};
	if ($@) {
		$errmsg = "Administrator->newOp : Operation type <$op_type> does not exist!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}

	# Operation instanciation
	my $op = "Operation::$op_type"->new(data => $op_data, administrator => $self, params => \%params);
	$log->info(ref($op) . " retrieved from database (next operation from execution list)");
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
		$errmsg = "Administrator->changeUser need a user_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg); 
	}
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
	
	if ((! exists $args{table} or ! defined $args{table}) ||
		(! exists $args{id} or ! defined $args{id})) { 
			$errmsg = "Administrator->_getDbix need a table and id named argument!";
			$log->error($errmsg);
			throw Mcs::Exception::Internal(error => $errmsg);
	}

	my $dbix;
#	my $entitylink = lc($args{table})."_entities";
	eval {
		$dbix = $self->{db}->resultset( $args{table} )->find(  $args{id}, 
										{ 	'+columns' => [ "entitylink.entity_id" ], 
										join => ["entitylink"] });};
	if ($@) {
		$errmsg = "Administrator->_getDbix error ".$@;
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	return $dbix;
}

=head2 Administrator::_getDbixFromHash(%args)
	
	Class : Private
	
	Desc : Instanciate dbix class mapped to corresponding raw in DB
	
	args: 
		table : String : DB table name
		hash: Hash ref : hash of constraints to find entity
	return: db schema (dbix)
	
=cut

sub _getDbixFromHash {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{table} or ! defined $args{table}) ||
		(! exists $args{hash} or ! defined $args{hash})) {
			$errmsg = "Administrator->_getDbixFromHash need a table and hash named argument!";
			$log->error($errmsg); 
			throw Mcs::Exception::Internal(error => $errmsg);
	}

	my $dbix;
	my $entitylink = lc($args{table})."_entities";
#	my $entitylink = lc($args{table})."_entities";
	eval {
		$log->debug("Search obj with the following hash $args{hash} in the following table : $args{table}");
		$log->debug(Dumper $args{hash});
		my $hash = $args{hash};
		if (keys(%$hash)){
			$log->debug("Hash has keys and value : %$hash when search in $args{table}");
			$dbix = $self->{db}->resultset( $args{table} )->search( $args{hash},
										{ 	'+columns' => [ "$entitylink.entity_id" ], 
										join => ["$entitylink"] });
		}
		else {
			$log->debug("hash is empty : %$hash when search in $args{table}");
			$dbix = $self->{db}->resultset( $args{table} )->search( undef,
										{ 	'+columns' => [ "$entitylink.entity_id" ], 
										join => ["$entitylink"] });
		}
	};
	if ($@) {
		$errmsg = "Administrator->_getDbix error ".$@;
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error =>  $errmsg);
	}
	return $dbix;
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
		$errmsg = "Administrator->_getAllData need a table named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}

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
		$errmsg = "Administrator->_newData need a table and row named argument!";
		$log->error($errmsg);		 
		throw Mcs::Exception::Internal(error => $errmsg);
	}

	my $new_obj = $self->{db}->resultset($args{table} )->new( $args{row});
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
	my $entity_class;

	if (! exists $args{type} or ! defined $args{type}) {
		$errmsg = "Administrator->_getEntityClass a type named argument!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}

	if (defined $args{class_path} && exists $args{class_path}){
		$entity_class = $args{class_path}}
	else {
		$entity_class = General::getClassEntityFromType(%args);}
    my $location = General::getLocFromClass(entityclass => $entity_class);
	$log->debug("$entity_class at Location $location");
	eval { require $location; };
    if ($@){
    	$errmsg = "Administrator->_getEntityClass type or class_path invalid!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
	return $entity_class;
}

=head2 getFreeInternalIP

return the first unused ip address in the internal network

=cut

sub getFreeInternalIP{
	my $self = shift;
	# retrieve internal network from config
	my $network = new NetAddr::IP(
		$self->{config}->{internalnetwork}->{ip},
		$self->{config}->{internalnetwork}->{mask},
	);
	
	my ($i, $row, $freeip) = 0;
	
	# try to find a matching motherboard of each ip of our network	
	while ($freeip = $network->nth($i)) {
		$row = $self->{db}->resultset('Motherboard')->find({ motherboard_internal_ip => $freeip->addr });
		
		# if no record is found for this ip address, it is free so we return it
		if(not defined $row) { return $freeip->addr; }
		
		$log->debug($freeip->addr." is already used");
		$i++;
	}
	if(not defined $freeip) {
		$errmsg = "Administrator->getFreeInternalIP : all internal ip addresses seems to be used !";
		$log->error($errmsg);
		throw Mcs::Exception::Network(error => $errmsg);
	}
}

=head2 newPublicIP

add a new public ip address
	args: 
		ip_address
		ip_mask
	optional args:
		gateway
=cut

sub newPublicIP {
	my $self = shift;
	my %args = @_;
	if (! exists $args{ip_address} or ! defined $args{ip_address} || 
		! exists $args{ip_mask} or ! defined $args{ip_mask}) {
		$errmsg = "Administrator->newPublicIP need ip_address and ip_mask named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	# ip format valid ?
	my $pubip = new NetAddr::IP($args{ip_address}, $args{ip_mask});
	if(not defined $pubip) { 
		$errmsg = "Administrator->newPublicIP : wrong value for ip_address/ip_mask!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	} 
	
	my $gateway;
	if(exists $args{gateway} and defined $args{gateway}) {
		$gateway = new NetAddr::IP($args{gateway});
		if(not defined $gateway) {
			$errmsg = "Administrator->newPublicIP : wrong value for gateway!";
			$log->error($errmsg);
			throw Mcs::Exception::Internal(error => $errmsg);
		}
	}

	my $res;	
	# try to save public ip
	eval {
		my $row = {ip_address => $pubip->addr, ip_mask => $pubip->mask};
		if($gateway) { $row->{gateway} = $gateway->addr; }
		$res = $self->{db}->resultset('Publicip')->create($row);
		$log->debug("Public ip create and return ". $res->get_column("publicip_id"));
	};
	if($@) { 
		$errmsg = "Administrator->newPublicIP: $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg); }
	$log->debug("new public ip created");
	return $res->get_column("publicip_id");
}

=head2 addRoute

add new route to a public ip given its id

=cut

sub addRoute {
	my $self = shift;
	my %args = @_;
	if (! exists $args{publicip_id} or ! defined $args{publicip_id} ||
		! exists $args{ip_destination} or ! defined $args{ip_destination} || 
		! exists $args{gateway} or ! defined $args{gateway}) {
		$errmsg = "Administrator->addRoute need publicip_id, ip_destination and gateway named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	# check valid ip_destination and gateway format
	my $destinationip = new NetAddr::IP($args{ip_destination});
	if(not defined $destinationip) {
		$errmsg = "Administrator->addRoute : wrong value for ip_destination!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);}
	
	my $gateway = new NetAddr::IP($args{gateway});
	if(not defined $gateway) {
		$errmsg = "Administrator->addRoute : wrong value for gateway!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	# try to create route
	eval {
		my $row = {ip_destination => $destinationip->addr, publicip_id => $args{publicip_id}};
		if($gateway) { $row->{gateway} = $gateway->addr; }
		$self->{db}->resultset('Route')->create($row);
	};
	if($@) { 
		$errmsg = "Administrator->addRoute: $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$log->debug("new route added to public ip");
}

=head2 getPublicIPs

Get list of public ip addresses 
	return: array ref

=cut

sub getPublicIPs {
	my $self = shift;
	my $pubips = $self->{db}->resultset('Publicip')->search;
	my $pubiparray = [];
	while(my $ips = $pubips->next) {
		push @$pubiparray, {
			publicip_id => $ips->get_column('publicip_id'),
			cluster_id => $ips->get_column('cluster_id'),
			ip_address => $ips->get_column('ip_address'),
			ip_mask => $ips->get_column('ip_mask'),
			gateway =>$ips->get_column('gateway') 
		};
	}
	return $pubiparray;
}

=head2 getPublicIPs

Get list of unused public ip addresses 
	return: array ref

=cut

sub getFreePublicIPs {
	my $self = shift;
	my $pubips = $self->{db}->resultset('Publicip')->search({ cluster_id => undef });
	my $pubiparray = [];
	while(my $ips = $pubips->next) {
		push @$pubiparray, {
			publicip_id => $ips->get_column('publicip_id'),
			cluster_id => $ips->get_column('cluster_id'),
			ip_address => $ips->get_column('ip_address'),
			ip_mask => $ips->get_column('ip_mask'),
			gateway =>$ips->get_column('gateway') 
		};
	}
	return $pubiparray;
}

=head2 delPublicIP

delete an unused public ip and its routes

=cut

sub delPublicIP {
	my $self = shift;
	my %args = @_;
	# arguments checking
	if (! exists $args{publicip_id} or ! defined $args{publicip_id}) { 
		$errmsg = "Administrator->delPublicIP need a publicip_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	# getting the row	
	my $row = $self->{db}->resultset('Publicip')->find( $args{publicip_id} );
	if(! defined $row) {
		$errmsg = "Administrator->delPublicIP : publicip_id $args{publicip_id} not found!";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	
	# verify that it is not used by a cluster
	if(defined ($row->get_column('cluster_id'))) {
		$errmsg = "Administrator->delPublicIP : publicip_id $args{publicip_id} is used by a cluster!";	
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	
	# related routes are automatically deleted due to foreign key 
	$row->delete;
	$log->info("Public ip ($args{publicip_id}) deleted with its routes");
}

=head2 setClusterPublicIP

associate public ip and cluster
	args:	publicip_id, cluster_id 
	

=cut

sub setClusterPublicIP {
	my $self = shift;
	my %args = @_;
	if (! exists $args{publicip_id} or ! defined $args{publicip_id} ||
		! exists $args{cluster_id} or ! defined $args{cluster_id}) { 
		$errmsg = "Administrator->setClusterPublicIP need publicip_id and cluster_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	my $row = $self->{db}->resultset('Publicip')->find($args{publicip_id});
	# getting public ip row
	if(! defined $row) {
		$errmsg = "Administrator->setClusterPublicIP : publicip_id $args{publicip_id} not found!";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	# try to set cluster_id to this ip
	eval {
		$row->set_column('cluster_id', $args{cluster_id});
		$row->update;
	};
	if($@) { 
		$errmsg = "Administrator->setClusterPublicIP : $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$log->info("Public ip $args{publicip_id} set to cluster $args{cluster_id}");
}

=head delRoute

delRoute delete a route given its id

=cut

sub delRoute {
	my $self = shift;
	my %args = @_;
	if (! exists $args{route_id} or ! defined $args{route_id}) {
		$errmsg = "Administrator->delRoute need a route_id named argument!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	my $row = $self->{db}->resultset('Route')->find($args{route_id});
	if(not defined $row) {
		$errmsg = "Administrator->delRoute : route_id $args{route_id} not found!";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$row->delete;
	$log->info("route ($args{route_id}) successfully deleted");	
}

=head getRoutes

return list of registered routes

=cut

sub getRoutes {
	my $self = shift;
	my $routes = $self->{db}->resultset('Route');
	my $routearray = [];
	while(my $r = $routes->next) {
		push @$routearray, {
			route_id => $r->get_column('route_id'),
			publicip_id => $r->get_column('publicip_id'),
			ip_destination => $r->get_column('ip_destination'),
			gateway =>$r->get_column('gateway') 
		};
	}
	return $routearray;
}


sub createNode{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id}) ||
		(! exists $args{motherboard_id} or ! defined $args{motherboard_id}) ||
		(! exists $args{master_node} or ! defined $args{master_node})){
		$errmsg = "Administrator->createNode need a cluster_id, motherboard_id and a master_node named argument!";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal(error => $errmsg);
	}
		
	$self->{db}->resultset('Node')->create({cluster_id=>$args{cluster_id},
											motherboard_id =>$args{motherboard_id},
											master_node => $args{master_node}});
}
sub removeNode{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id}) ||
		(! exists $args{motherboard_id} or ! defined $args{motherboard_id})){
		$errmsg = "Administrator->createNode need a cluster_id, motherboard_id and a master_node named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	#TODO Reflechir si on fait le delete sur le node_id ou sur la combo motherboard_id and cluster_id
	my $row = $self->{db}->resultset('Node')->search(\%args)->first;
	if(not defined $row) {
		$errmsg = "Administrator->removeNode : node representing motherboard $args{motherboard_id} and cluster $args{cluster_id} not found!";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$row->delete;
}

sub getNodes {
	my $self = shift;
	my %args = @_;
	if (! exists $args{cluster_id} or ! defined $args{cluster_id}) {
		$errmsg = "Administrator->getNodes need a cluster_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $nodes = $self->{db}->resultset('Node')->search({ cluster_id => $args{cluster_id}});
	my $motherboards = [];
	while (my $n = $nodes->next) {
		push @$motherboards, $self->getEntity(type => 'Motherboard', id => $n->get_column('motherboard_id'));
	}
	return scalar @$motherboards ? @$motherboards : undef;
}


########################################
## methodes for fast usage in web ui ##
########################################

# add a new message
sub addMessage {
	my $self = shift;
	my %args = @_;
	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{content} or ! defined $args{content})){
		$errmsg = "Administrator->addMessage need a type and content named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	$self->{db}->resultset('Message')->create({
		user_id => $self->{_rightschecker}->{_user},
		message_creationdate => \"CURRENT_DATE()",
		message_creationtime => \"CURRENT_TIME()",
		message_type => $args{type},
		message_content => $args{content}
	});
	return;
}

sub getMessages {
	my $self = shift;
	my $r = $self->{db}->resultset('Message')->search(undef, { 
		order_by => { -desc => [qw/message_id/] }
	});
	my @arr = ();
	while (my $row = $r->next) {
		push @arr, { 
			'TYPE' => $row->get_column('message_type'), 
			'DATE' => $row->get_column('message_creationdate'), 
			'TIME' => $row->get_column('message_creationtime'), 
			'CONTENT' => $row->get_column('message_content')  
		};
	}
	return @arr;
}

sub getOperations {
	my $self = shift;
	my $Operations = $self->{db}->resultset('Operation')->search(undef, { 
		order_by => { -desc => [qw/execution_rank creation_date creation_time/] },
		'+columns' => [ 'user_id.user_login' ],
		join => [ 'user_id' ]
	});
	my $arr = [];
	my $opparams = [];
	while (my $op = $Operations->next) {
		my $Parameters = $self->{db}->resultset('OperationParameter')->search({operation_id=>$op->get_column('operation_id')});
		
		while (my $param = $Parameters->next) {
			push @$opparams, { 
				'ID' => $op->get_column('operation_id'), 
				'PARAMNAME' => $param->get_column('name'), 
				'VAL' => $param->get_column('value')
			};
		}
		push @$arr, { 
			'ID' => $op->get_column('operation_id'),
			'TYPE' => $op->get_column('type'), 
			'FROM' => $op->get_column('user_login'), 
			'DATE' => $op->get_column('creation_date'), 
			'TIME' => $op->get_column('creation_time'), 
			'RANK' => $op->get_column('execution_rank'), 
			'PRIORITY' => $op->get_column('priority'), 
		};
	}
	return ($arr, $opparams);

}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
