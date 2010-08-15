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
use NetAddr::IP;
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
#use lib qw(. ../../Common/Lib);
use AdministratorDB::Schema;
use EntityRights;
use McsExceptions;
use General;
use Entity;
use XML::Simple;

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
		throw Mcs::Exception::Internal(error => "Administrator->need a login and password named argument!"); }
	
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
		$log->debug("instanciating AdministratorDB::Schema");
		$log->debug("dbi : $dbi, use : $self->{config}->{dbconf}->{user}, password : $self->{config}->{dbconf}->{password}");
#		print "dbi : $dbi, use : $self->{config}->{dbconf}->{user}, password : $self->{config}->{dbconf}->{password}\n";
		$schema = AdministratorDB::Schema->connect($dbi, $self->{config}->{dbconf}->{user}, $self->{config}->{dbconf}->{password}, \%opts);
#		print "adm->new : login $login, password $password with dbi : $dbi\n";

		# When debug is set, all sql queries are printed
		# $schema->storage->debug(1); # or: $ENV{DBIC_TRACE} = 1 in any file

		$log->debug("instanciating EntityRights");
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
	return $self;
}

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
			throw Mcs::Exception::Internal::IncorrectParam(error => "Administrator->new need internalnetwork definition in config file!");
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
			throw Mcs::Exception::Internal::IncorrectParam(error => "Administrator->new need db definition in config file!");
		}

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
		throw Mcs::Exception::Internal(error => "Administrator->_getEntity need a type and an id named argument!"); }
	$log->debug( "getEntity( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );
	
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
				$attrs{ $param->name } = $param->value;}
			return $entity_class->new( rightschecker => $self->{_rightschecker}, data => $entity_dbix, ext_attrs => \%attrs);
		}
		else {
			return $entity_class->new( rightschecker => $self->{_rightschecker}, data => $entity_dbix );}
	}
	else {
		$log->warn( "Administrator::getEntity( ", map( { "$_ => $args{$_}, " } keys(%args) ), ") : Object not found!");
		throw Mcs::Exception::Internal(error => "Administrator::getEntity : Object not found with type ($args{type}) and id ($args{id})");
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
		throw Mcs::Exception::Internal(error => "Administrator->_getEntityFromHash need a type and a hash named argument!"); }
	$log->debug( "getEntityFromHash( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );
	
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
		throw Mcs::Exception::Internal(error => "Administrator->newEntity need params and type named argument!"); }

	$log->info( "newEntity( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );

	# We get class and require Entity::$entity_class
	my $entity_class = $self->_getEntityClass(type => $args{type});
	
	# We check entity attributes and separate them in two categories :
	#	- ext_attrs
	#	- global_attrs
	my $attrs = $entity_class->checkAttrs(attrs => $args{params});
	
	# We create a new DBIx containing new entity (only global attrs)
	my $entity_data = $self->_newDbix( table =>  $args{type}, row => $attrs->{global} );
	
	warn( "Administrator::newEntity( .. ) : Object creation failed!" ) if (  not defined $entity_data );
	
	# We instanciate entity with DBIx data and rightchecker
	my $new_entity;
	if ($entity_class->extension()) {
		$new_entity = $entity_class->new( data => $entity_data, rightschecker => $self->{_rightschecker}, ext_attrs => $attrs->{extended});
	}
	else {
		$new_entity = $entity_class->new( data => $entity_data, rightschecker => $self->{_rightschecker});
	}
	
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
			throw Mcs::Exception::Internal(error => "Administrator->newOp need a priority, params and type named argument!"); }
	#TODO Check if operation is allowed
	my $rank = $self->_get_lastRank() + 1;
	#TODO Put the good user in operation
#	my $user_id = $self->{_rightschecker}->{_user};
	my $user_id = 16;
	$log->debug("User id in _rightschecker is $user_id");
	my $op_data = $self->_newDbix( table => 'Operation', row => { 	type => $args{type},
																	execution_rank => $rank,
																	user_id => $user_id,
																	priority => $args{priority}});

	my $subclass = $args{type};
	eval {
		require "Operation/$subclass.pm";
	};
	if ($@) {
		throw Mcs::Exception::Internal(error => "Administrator->newOp : Operation type ($args{type}) does not exist when require Operation::$subclass.pm");}

	my $op = "Operation::$subclass"->new(data => $op_data, rightschecker => $self->{_rightschecker}, params => $args{params});
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
	$log->debug("Parameters get <" . %params . ">");
	# Try to load Operation::$op_type
	eval {
		require "Operation/$op_type.pm";
	};
	if ($@) {
		throw Mcs::Exception::Internal(error => "Administrator->newOp : Operation type does not exist!");}

	# Operation instanciation
	my $op = "Operation::$op_type"->new(data => $op_data, rightschecker => $self->{_rightschecker}, params => \%params);
	$log->debug("Operation instanciate " . ref($op) . " and will be returned");
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
	
	if ((! exists $args{table} or ! defined $args{table}) ||
		(! exists $args{id} or ! defined $args{id})) { 
			throw Mcs::Exception::Internal(error => "Administrator->_getDbix need a table and id named argument!"); }

	my $dbix;
#	my $entitylink = lc($args{table})."_entities";
	eval {
		$dbix = $self->{db}->resultset( $args{table} )->find(  $args{id}, 
										{ 	'+columns' => [ "entitylink.entity_id" ], 
										join => ["entitylink"] });};
	if ($@) {
		my $error = $@;
		throw Mcs::Exception::Internal(error => "Administrator->_getDbix error " . $error);
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
			throw Mcs::Exception::Internal(error => "Administrator->_getDbixFromHash need a table and hash named argument!"); }

	my $dbix;
	my $entitylink = lc($args{table})."_entities";
#	my $entitylink = lc($args{table})."_entities";
	eval {
		$log->debug("Search obj with the following hash $args{hash} in the following table : $args{table}");
		print Dumper $args{hash};
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
		my $error = $@;
		throw Mcs::Exception::Internal(error => "Administrator->_getDbix error " . $error);
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
	my $entity_class;

	if (! exists $args{type} or ! defined $args{type}) { 
		throw Mcs::Exception::Internal(error => "Administrator->_getEntityClass a type named argument!"); }

	if (defined $args{class_path} && exists $args{class_path}){
		$entity_class = $args{class_path}}
	else {
		$entity_class = General::getClassEntityFromType(%args);}
    my $location = General::getLocFromClass(entityclass => $entity_class);
	$log->debug("$entity_class at Location $location");
	eval {
	    require $location;};
    if ($@){
    	throw Mcs::Exception::Internal(error => "Administrator->_getEntityClass type or class_path invalid!");
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
		throw Mcs::Exception::Network(
			error => "Administrator->getFreeInternalIP : all internal ip addresses seems to be used !")
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
		! exists $args{ip_mask} or ! defined $args{ip_mask})
	{ 
		throw Mcs::Exception::Internal(
			error => "Administrator->newPublicIP need ip_address and ip_mask named argument!"); }
	# ip format valid ?
	my $pubip = new NetAddr::IP($args{ip_address}, $args{ip_mask});
	if(not defined $pubip) { 
		throw Mcs::Exception::Internal(error => "Administrator->newPublicIP : wrong value for ip_address/ip_mask!")}; 
	
	my $gateway;
	if(exists $args{gateway} and defined $args{gateway}) {
		$gateway = new NetAddr::IP($args{gateway});
		if(not defined $gateway) {
			throw Mcs::Exception::Internal(error => "Administrator->newPublicIP : wrong value for gateway!");
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
	if($@) { throw Mcs::Exception::DB(error => "Administrator->newPublicIP: $@"); }
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
		! exists $args{gateway} or ! defined $args{gateway})
	{ 
		throw Mcs::Exception::Internal(
			error => "Administrator->addRoute need publicip_id, ip_destination and gateway named argument!");}
	# check valid ip_destination and gateway format
	my $destinationip = new NetAddr::IP($args{ip_destination});
	if(not defined $destinationip) {
		throw Mcs::Exception::Internal(error => "Administrator->addRoute : wrong value for ip_destination!");}
	
	my $gateway = new NetAddr::IP($args{gateway});
	if(not defined $gateway) {
		throw Mcs::Exception::Internal(error => "Administrator->addRoute : wrong value for gateway!");}
	
	# try to create route
	eval {
		my $row = {ip_destination => $destinationip->addr, publicip_id => $args{publicip_id}};
		if($gateway) { $row->{gateway} = $gateway->addr; }
		$self->{db}->resultset('Route')->create($row);
	};
	if($@) { throw Mcs::Exception::DB(error => "Administrator->addRoute: $@");}
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
		throw Mcs::Exception::Internal(error => "Administrator->delPublicIP need a publicip_id named argument!"); }
	
	# getting the row	
	my $row = $self->{db}->resultset('Publicip')->find( $args{publicip_id} );
	if(! defined $row) {
		throw Mcs::Exception::DB(error => "Administrator->delPublicIP : publicip_id $args{publicip_id} not found!"); }
	
	# verify that it is not used by a cluster
	if(defined ($row->get_column('cluster_id'))) {
		throw Mcs::Exception::DB(error => "Administrator->delPublicIP : publicip_id $args{publicip_id} is used by a cluster!"); }
	
	# related routes are automatically deleted due to foreign key 
	$row->delete;
	$log->debug("Public ip ($args{publicip_id}) deleted with its routes");
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
		throw Mcs::Exception::Internal(error => "Administrator->setClusterPublicIP need publicip_id and cluster_id named argument!"); }
	my $row = $self->{db}->resultset('Publicip')->find($args{publicip_id});
	# getting public ip row
	if(! defined $row) {
		throw Mcs::Exception::DB(error => "Administrator->setClusterPublicIP : publicip_id $args{publicip_id} not found!"); }
	# try to set cluster_id to this ip
	eval {
		$row->set_column('cluster_id', $args{cluster_id});
		$row->update;
	};
	if($@) { throw Mcs::Exception::DB(error => "Administrator->setClusterPublicIP : $@"); }
	$log->debug("Public ip $args{publicip_id} set to cluster $args{cluster_id}");
}

=head delRoute

delRoute delete a route given its id

=cut

sub delRoute {
	my $self = shift;
	my %args = @_;
	if (! exists $args{route_id} or ! defined $args{route_id}) {
		throw Mcs::Exception::Internal(error => "Administrator->delRoute need a route_id named argument!"); }
	
	my $row = $self->{db}->resultset('Route')->find($args{route_id});
	if(not defined $row) {
		throw Mcs::Exception::DB(error => "Administrator->delRoute : route_id $args{route_id} not found!"); }
	$row->delete;
	$log->debug("route ($args{route_id}) successfully deleted");	
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

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut