# Entity.pm - Abstract Object class of Entity

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

Entity - Abstract Object class of Entity, all object mother

=head1 SYNOPSIS

    use Entity;
    

=head1 DESCRIPTION

Entity is the mother object use in microcluster

=head1 METHODS

=cut

package Entity;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Kanopya::Exceptions;
use Administrator;

my $log = get_logger("administrator");
my $errmsg;

sub getEntities {
	my $class = shift;
    my %args = @_;
	my @objs = ();
    my ($rs, $entity_class);

	if ((! exists $args{type} or ! defined $args{type}) ||
		(! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getEntities need a type and a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
	
	$rs = $adm->_getDbixFromHash( table => $args{type}, hash => $args{hash} );
	$log->debug('resultset count:'.$rs->count());
	$log->debug( "_getEntityClass with type = $args{type}");

	while ( my $row = $rs->next ) {
		my $id_name = lc($args{type}) . "_id";
		my $id = $row->get_column($id_name);
		my $obj;
		eval { $obj = "Entity::$args{type}"->get(id => $id); };
		if($@) {
			my $exception = $@; 
			if(Kanopya::Exception::Permission::Denied->caught()) {
				next;
			} 
			else { $exception->rethrow(); } 
		}
		
		push @objs, $obj;
	}
	return  @objs;
}

=head2 new
	
	Class : Public
	
	Desc : This method instanciate Entity.
	
	Args :
		Attrs : Hash ref : This is a hash ref on attributes used for the new entity
		Table : String : This is the database table storing the entity (often corresponding to Entity type)
	Return : Entity, this class could not be instanciated !!
	
=cut

sub new {
	my $class = shift;
    my %args = @_;
	my $self = {};
    if ((! exists $args{attrs} or ! defined $args{attrs}) ||
    	(! exists $args{table} or ! defined $args{table})) {
		$errmsg = "Entity->new need an attrs and table named argument!"; 	 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $adm = Administrator->new();
#	my $rc = $adm->getRightChecker();
	# We create a new DBIx containing new entity (only global attrs)
	$self->{_dbix} = $adm->_newDbix( table =>  $args{table}, row => $args{attrs} );

    bless $self, $class;
    return $self;
}

=head2 get 

	Class : Public
	
	Desc : This method load an Entity from database.
	
	Args :
		id : Scalar (Int) : Entity identifier (not entity_id) related to a specific table (second arg)
		table : Scalar (String) : Entity searched table name
	Return : Entity, this class could not be instanciated !!

=cut

sub get {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{id} or ! defined $args{id}) ||
    	(! exists $args{table} or ! defined $args{table})) {
		$errmsg = "Entity->get need an id and table named argument!"; 	 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
	my $dbix = $adm->getRow(id=>$args{id}, table => $args{table});
    $log->debug("Arguments: ".ref($args{id}));
    
    my $self = {
        _dbix			=> $dbix,
        _entity_id		=> $dbix->get_column('entity_id'),
    };
    
    bless $self, $class;
    return $self;
}

=head2 getMasterGroupName

	Class : public
	desc : retrieve the master group name associated with this entity
	return : scalar : master group name

=cut

sub getMasterGroupName {
	my $self = shift;
	my $class = ref $self || $self;
	my @array = split(/::/, "$class");
	my $mastergroup = pop(@array);
	return $mastergroup;
}

=head2 getMasterGroupEid

	Class : public
	
	desc : return entity_id of entity master group
	TO BE CALLED ONLY ON CHILD CLASS/INSTANCE
	return : scalar : entity_id

=cut

sub getMasterGroupEid {
	my $self = shift;
	my $adm = Administrator->new();
	my $mastergroup = $self->getMasterGroupName();
	my $eid = $adm->{db}->resultset('Groups')->find({ groups_name => $mastergroup })->groups_entities->first->get_column('entity_id');
	return $eid;
}



sub getExtendedAttrs {
	my %attrs;
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{ext_table} or ! defined $args{ext_table})) {
		$errmsg = "Entity->getExtendedAttrs need an ext_table named argument!"; 	 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $ext_attrs_rs = $self->{_dbix}->search_related( $args{ext_table} );
	if (! defined $ext_attrs_rs){
	    $log->debug("No extended Attrs");
		return;
	}
	while ( my $param = $ext_attrs_rs->next ) {
		$attrs{ $param->name } = $param->value;
	}
	return \%attrs
}

=head extension

=cut 

sub extension {
	return;
}

=head2 getGroups

return groups resultset where this entity appears (only on an already saved entity)

=cut

sub getGroups {
	my $self = shift;
	if( not $self->{_dbix}->in_storage ) { return; } 
	#$log->debug("======> GetGroups call <======");
	my $mastergroup = $self->getMasterGroupEid();
	my $groups = $self->{_rightschecker}->{_schema}->resultset('Groups')->search({
		-or => [
			'ingroups.entity_id' => $self->{_dbix}->get_column('entity_id'),
			'groups_name' => $mastergroup ]},
			
		{ 	'+columns' => [ 'groups_entities.entity_id' ], 
			join => [qw/ingroups groups_entities/] }
	);
	return $groups;
}

=head2 getAttrs

	return a hash with all (param => value) of our data, including extending Attrs

=cut

sub getAttrs {
	my $self = shift;
	my $data = $self->{_dbix};
	
	# build hash corresponding to class table (with local changes)
	my %attrs = $data->get_columns;
	
	my $ext = $self->{_ext_attrs};
	# add extended Attrs from db
	foreach my $k (keys %$ext){ $attrs{$k} = $ext->{$k}; }
	
	return %attrs;	
}

=head2 asString

	Return a string with the entity class name an all of its data
	
=cut


sub asString {
	my $self = shift;
	
	my %h = $self->getAllAttrs;
	my @s = map { "$_ => $h{$_}, " } keys %h;
	return ref $self, " ( ",  @s,  " )";
}

=head2 setAttr
	
	args: 
		name : String : Field name
		value : String : Value
	set entity param 'name' to 'value'
	Follow 'ext' link to set extended params
	
=cut

sub setAttr {
	my $self = shift;
	my %args = @_;
	my $data = $self->{_dbix};

    if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value})) { 
		$errmsg = "Entity->setAttr need a name and value named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
		
	$self->checkAttr(%args);
		
	if($data->has_column( $args{name})) {
    	$data->set_column( $args{name}, $args{value} );	
    } elsif( $self->extension() ) {
    	$self->{ _ext_attrs }{ $args{name} } = $args{value};
    } else {
    	$log->debug("setAttrs() : No parameter named '$args{name}' for ". ref($self));
    }

}

=head2 setAttrs
	
	args: 
		Attrs : { p1 => v1, p2 => v2, ... }
	
	Set all entity Attrs pX to corresponding value vX, including ext Attrs
	
=cut

sub setAttrs {
	my $self = shift;
	my %args = @_;

	if (! exists $args{attrs} or ! defined $args{attrs}) { 
		$errmsg = "Entity->setAttrs need an attrs hash named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}

	my $attrs = $args{attrs};
	while ( (my $col, my $value) = each %$attrs ) {
    	$self->setAttr( name  => $col, value => $value );
	}
}

=head2 getAttr
	
	args: name
	return value of attr 'name'
	Follow 'ext' link to get extended Attrs

=cut

sub getAttr {
	my $self = shift;
    my %args = @_;
    my $data = $self->{_dbix};
    my $value = undef;
    
	if (! exists $args{name} or ! defined $args{name}) { 
		$errmsg = "Entity->getAttrs need a name named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}

    if ( $data->has_column( $args{name} ) ) {
        $value = $data->get_column( $args{name} );
        if (defined $args{name}){
            $log->debug(ref($self) . " getAttr of $args{name} : <$value>");
            }
        else {
            $log->debug(ref($self) . " getAttr of $args{name}  return undef");
        }
	} elsif ( exists $self->{_ext_attrs}{ $args{name} } ) {
		$value = $self->{_ext_attrs}{ $args{name} };
		$log->debug(ref($self) . " getAttr (extended) of $args{name} : $value");
	} else {
		$errmsg = "Entity->getAttr no attr name $args{name}!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	return $value;
}

=head2 save
	
	Save entity data in DB afer rights check
	Support entity creation or modification
	
=cut

sub save {
	my $self = shift;
	my $data = $self->{_dbix};
	
	if ( $data->in_storage ) {
		# MODIFY existing db obj
		$data->update;
		$self->_saveExtendedAttrs();
	} else {
		# CREATE
		my $adm = Administrator->new();
		my $relation = lc(ref $self);
		$relation =~ s/.*\:\://g;
		$log->debug("la relation: $relation");
		my $newentity = $self->{_dbix}->insert;
		$log->debug("new entity inserted.");
		my $row = $adm->{db}->resultset('Entity')->create(
			{ "${relation}_entities" => [ { "${relation}_id" => $newentity->get_column("${relation}_id")} ] },
		);
		$log->debug("new $self inserted with his entity relation.");
		$self->{_entity_id} = $row->get_column('entity_id');
		
		$self->_saveExtendedAttrs();
		$log->info(ref($self)." saved to database");
	}
		
}

=head2 getPerms

	class : public

	desc : return a structure describing method permissions 

	return : hash ref

=cut

sub getPerms {
	my $self = shift;
	my $class = ref $self;
	my $adm = Administrator->new();
	my $granted_methods = {};
	
	if($class) { # called on instance
		my $instancemethod = $class->methods()->{instance};
		foreach my $method (keys %$instancemethod) {
			my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => $method);
			if($granted) {
				$granted_methods->{$method} = 1;
			} 
			else {
				$granted_methods->{$method} = 0;
			}
		}
	}
	else { # called on class
		my $classmethod = $self->methods()->{class};
		my $mastergroupeid = $self->getMasterGroupEid();
		foreach my $method (keys %$classmethod) {
			my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $mastergroupeid, method => $method);
			if($granted) {
				$granted_methods->{$method} = 1;
			} 
			else {
				$granted_methods->{$method} = 0;
			}
		}
	}
		
	return $granted_methods;
}

=head2 addPerm

=cut

sub addPerm {
	my $self = shift;
	my %args = @_;
	my $class = ref $self;
	
	if (! exists $args{method} or ! defined $args{method}) { 
		$errmsg = "Entity::addPerm need a method named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	if (! exists $args{entity_id} or ! defined $args{entity_id}) { 
		$errmsg = "Entity::addPerm need a entity_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	my $adm = Administrator->new();
   	
	if($class) {
		# addPerm call from an instance of type $class
	  	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'setPerm');
   	   	if(not $granted) {
   			throw Kanopya::Exception::Permission::Denied(error => "Permission denied to set permission on cluster with id $args{entity_id}");
   		}
   		# 
		$adm->{_rightchecker}->addPerm(
			consumer_id => $args{entity_id}, 
			consumed_id => $self->{_entity_id}, 
			method 		=> $args{method},
		);
	}
	else {
		# addPerm call from class $self
		my @list = split(/::/, "$self");
		my $mastergroup = pop(@list);
		my $entity_id = $adm->{db}->resultset('Groups')->find({ groups_name => $mastergroup })->groups_entities->first->get_column('entity_id');
		my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'setPerm');
   	   	if(not $granted) {
   			throw Kanopya::Exception::Permission::Denied(error => "Permission denied to set permission on cluster with id $args{id}");
   		}
		
		$adm->{_rightchecker}->addPerm(
			consumer_id => $args{entity_id}, 
			consumed_id => $entity_id, 
			method 		=> $args{method},
		);
	
	}
}


=head2 _saveExtendedAttrs

	add or update extended Attrs on the related table 'ext'
	WARN: this will insert _dbix in DB if it's not already in
	
=cut

sub _saveExtendedAttrs {
	my $self = shift;
	my $ext_attrs = $self->{_ext_attrs};
	my $data = $self->{_dbix};
	
	if ( $ext_attrs ) {
		foreach my $k (keys %$ext_attrs) {
			$data->update_or_create_related( $self->extension(), { name => $k, value => $ext_attrs->{$k} } );
		}
	}
}

=head2 delete
	
	Class : Public
	
	Desc : This method delete Entity in DB
	
=cut

sub delete {
	my $self = shift;
	my $data = $self->{_dbix};

	my $adm = Administrator->new();
	


	my $relation = lc(ref $self);
	$relation =~ s/.*\:\://g;
	$log->debug("Delete Entity which type is " . ref($self));
	
	my $entity_rs = $data->related_resultset( $relation . "_entities" );
	$log->debug("First Deletion of entity link : " . $relation . "_entities");
	# J'essaie de supprimer dans la table entity
	my $real_entity_rs = $entity_rs->related_resultset("entity_id");
	$real_entity_rs->delete;
	$log->debug("Delete extension");
	# Delete extended Attrs (cascade delete)
	my $extension = $self->extension();
	if ($extension) {
		my $Attrs_rs = $data->related_resultset( $extension );
		if ( $Attrs_rs ) {
			$Attrs_rs->delete;}
	}
	$log->debug("Finally delete the dbix itself");
	$data->delete;

}


sub activate {
	my $self = shift;
	if (defined $self->ATTR_DEF->{active}) {
		$self->{_dbix}->update({active => "1"});
#		$self->setAttr(name => 'active', value => 1);
		$log->debug("Entity::Activate : Entity is activated");
	} else {
		$errmsg = "Entity->activate Entity ". ref($self) . " unable to activate !";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
}

sub deactivate {}

# destructor
sub DESTROY {}

1;
