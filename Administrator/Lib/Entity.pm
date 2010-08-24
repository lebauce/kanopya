# Entity.pm - Abstract Object class of Entity

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
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;

my $log = get_logger("administrator");
my $errmsg;


=head2 new
	
	Class : Public
	
	Desc : This method instanciate Entity.
	
	Args :
		rightschecker : Rightschecker : Object use to check write and update entity_id
		data : DBIx class: object data
	Return : Entity, this class could not be instanciated !!
	
=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) {
		$errmsg = "Entity->new need a data and rightschecker named argument!"; 	 
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
    $log->debug("Arguments: ".ref($args{data})." and ".ref($args{rightschecker}));
    
    my $self = {
    	_rightschecker	=> $args{rightschecker},
        _dbix			=> $args{data},
        _ext_attrs		=> {},
        extension		=> undef
    };
    bless $self, $class;
    
    # getting groups where we find this entity (entity already exists)
	if($self->{_dbix}->in_storage) {
		$self->{_groups} = $self->getGroups;
	}
	return $self;
}

=head extension

=cut 

sub extension {
	return undef;
}

=head2 getGroups

return groups resultset where this entity appears (only on an already saved entity)

=cut

sub getGroups {
	my $self = shift;
	if( not $self->{_dbix}->in_storage ) { return undef; } 
	my $mastergroup = ref $self;
	$mastergroup =~ s/.*\:\://g;
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
		throw Mcs::Exception::Internal(error => $errmsg);
	}
		
	$self->checkAttr(%args);
		
	if($data->has_column( $args{name})) {
    	$data->set_column( $args{name}, $args{value} );	
    } elsif( $self->extension() ) {
    	# TODO check if ext param name is a valid name for this entity
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
		throw Mcs::Exception::Internal(error => $errmsg);
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
		throw Mcs::Exception::Internal(error => $errmsg);
	}

	if ( $data->has_column( $args{name} ) ) {
		$value = $data->get_column( $args{name} );
		$log->debug(ref($self) . " getAttr of $args{name} : $value");
	} elsif ( exists $self->{_ext_attrs}{ $args{name} } ) {
		$value = $self->{_ext_attrs}{ $args{name} };
		$log->debug(ref($self) . " getAttr (extended) of $args{name} : $value");
	} else {
		$errmsg = "Entity->getAttr no attr name $args{name}!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
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
	#TODO check rights

	if ( $data->in_storage ) {
		# MODIFY existing db obj
		$data->update;
		$self->_saveExtendedAttrs();
	} else {
		# CREATE
		my $relation = lc(ref $self);
		$relation =~ s/.*\:\://g;
		$log->debug("la relation: $relation");
		my $newentity = $self->{_dbix}->insert;
		$log->debug("new entity inserted.");
		my $row = $self->{_rightschecker}->{_schema}->resultset('Entity')->create(
			{ "${relation}_entities" => [ { "${relation}_id" => $newentity->get_column("${relation}_id")} ] },
		);
		$log->debug("new $self inserted with his entity relation.");
		$self->{_entity_id} = $row->get_column('entity_id');
		
		$self->_saveExtendedAttrs();
		$log->info(ref($self)." saved to database");
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
	#TODO A reflechir ne vaut il pas mieux de faire un update sur le champs active sinon pb avec le save qui prendra en compte les autres champs modifiés 
	if (defined $self->ATTR_DEF->{active}) {
		$self->setAttr(name => 'active', value => 1);
		$log->debug("Entity::Activate : Entity is activated");
	} else {
		$errmsg = "Entity->activate Entity ". ref($self) . " unable to activate !";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
}

sub deactivate {}

# destructor
sub DESTROY {}

1;
