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
		$log->info("instanciating AdministratorDB::Schema");
		$schema = AdministratorDB::Schema->connect($dbi, $user, $pass, \%opts);
	};
	#TODO Understand why no catching exception from db connection but only 
	if ($@) {
		if ($@->isa('DBIx::Class::Exception')) {
			$log->error("Administrator Instanciation : Connection DB Failed");
			$@->rethrow();}
   }
		
	# When debug is set, all sql queries are printed
	# $schema->storage->debug(1); # or: $ENV{DBIC_TRACE} = 1 in any file
	eval {
		$log->info("instanciating EntityRights");
		$rightschecker = EntityRights->new( schema => $schema, login => $login, password => $password );
	};
	if ($@) {
		#TODO Test exception type when exception are identified in EntityRight
			$log->error("EntityRights Instanciation : Failed");
			$@->rethrow();
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


# permet de faire le lien entre les classes qui n'ont pas le meme noms que la table en bd
# pas beau trouver autre chose
sub _mapName {
	my %ClassTableMapping = (
		"Operation" => "OperationQueue" );
	
	my ($class_name) = @_;
	my $table_name = $ClassTableMapping{ $class_name };
	return $table_name ? $table_name : $class_name;
}

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

	return $self->{db}->resultset( _mapName( $args{table} ) )->find( $args{id} );
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

	return $self->{db}->resultset( _mapName( $args{table} ) );
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
	
	my $new_obj = $self->{db}->resultset( _mapName( $args{table} ) )->create( $args{row} );
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
	
	my $new_obj = $self->{db}->resultset( _mapName( $args{table} ) )->new( $args{row} );
	
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
	
	args: type, id
	Return a new Entity::<type> with data corresponding to <id> (in <type> table)
	To modify data in DB call save() on returned obj (after modification)
	
=cut

sub getObj {
	my $self = shift;
    my %args = @_;

	$log->info( "getObj( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );

	my $obj_data = $self->_getData( table => $args{type}, id => $args{id} );
	my $new_obj;
	if ( defined $obj_data ) {
		$new_obj = $self->_newObj( type => $args{type}, data => $obj_data );
	}
	else {
		warn( "Administrator::getObj( ", map( { "$_ => $args{$_}, " } keys(%args) ), ") : Object not found!");
		return undef;
	}

    return $new_obj;
}

=head2 getAllObjs
	
	Class : Public
	
	Desc : This method allows to get many entity objects. It
			get all allowed object from calling _getAllData
	
	args: type
	Return a new Entities::<type> with data corresponding to <id> (in <type> table)
	To modify data in DB call save() on returned obj (after modification)
	
=cut

sub getAllObjs {
	my $self = shift;
    my %args = @_;
	
	my @objs = ();
	my $rs = $self->_getAllData( table => $args{type} );
	while ( my $raw = $rs->next ) {
		my $obj = $self->_newObj( type => $args{type}, data => $raw );
		push @objs, $obj;
	}    
    return  @objs;
}


=head2 newObj
	
	args: 
		type: concrete Entity type
		params: hash ref with key mapped on <type> table column
		
	Return a New Entity::<type> with params as data (not add in db)
	To add data in DB call save() on returned obj
	 
=cut

sub newObj {
	my $self = shift;
    my %args = @_;

	$log->info( "newObj( ", map( { "$_ => $args{$_}, " } keys(%args) ), ");" );

	my $obj_data = $self->_newData( table =>  $args{type}, row => $args{params} );
	my $new_obj = $self->_newObj( type => $args{type}, data => $obj_data );
	
	warn( "Administrator::newObj( .. ) : Object creation failed!" ) if (  not defined $obj_data );
	
    return $new_obj;
}

=head2 new Op
	
=cut

sub newOp {
	my $self = shift;
	my %args = @_;
	#TODO Check if operation is allowed
	my $rank = $self->_get_lastRank() + 1;
	my $user_id = $self->{_rightschecker}->{_user};
	my $op_data = $self->_newData( table => 'Operation', row => { 	type => $args{type},
																	execution_rank => $rank,
																	user_id => $user_id,
																	priority => $args{priority}});
	my $op = $self->_newObj(type => "Operation::". $args{type}, data => $op_data) ;
	$op->save;
	$op->addParams($args{params});
	return $op;
}

sub _get_lastRank{
	return 0;
}

sub saveObj {}

=head2 getNextOp
	
	Returns the concrete Operation with the execution_rank min 
	
=cut

sub getNextOp {
	my $self = shift;
	
	my $all_ops = $self->_getAllData( table => 'OperationQueue' );
	my $op_data = $all_ops->search( {}, { order_by => { -asc => 'execution_rank' }  } )->next();
	
	die "No more operation in queue!" if ( !$op_data );
	
	my $op_type = $op_data->type;

	my $op = $self->_newObj( type => "Operation::$op_type", data => $op_data );
	$log->warn("Data Class is : Operation::$op_type");

	return $op;
}

=head2 getNextOperation

	adm->getNextOperation() : Operationdata send the next operation.

=cut

sub getNextOperation {
	my $self = shift;
	return $self->getObj("Operation", 1);
}

sub changeUser {
	my $self = shift;
	my %args = @_;
	if (! exists $args{user_id} or ! defined $args{user_id}) { die "Administrator->changeUser need a user_id named argument!"; }
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