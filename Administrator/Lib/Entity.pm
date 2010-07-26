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
use lib qw(../../Common/Lib);
use McsExceptions;

my $log = get_logger("administrator");


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
		throw Mcs::Exception::Internal(error => "Entity->new need a data and rightschecker named argument!"); }
    $log->warn("Data : $args{data} and $args{rightschecker}");
    
    my $self = {
    	_rightschecker	=> $args{rightschecker},
        _dbix			=> $args{data},
        _ext_attrs		=> {},
        extension		=> undef,
    };
    bless $self, $class;
    
    # getting groups where we find this entity (entity already exists)
	if($self->{_dbix}->in_storage) {
		$self->{_groups} = $self->getGroups;
	}
	$log->warn("new return $self");
    return $self;
}

# Default, no extension
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
	foreach my $k (keys %$ext){
		$attrs{$k} = $ext->{$k};
		}
	
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

=head2 setValue
	
	args: name, value
	set entity param 'name' to 'value'
	Follow 'ext' link to set extended params
	
=cut

sub setAttr {
	my $self = shift;
	my %args = @_;
	my $data = $self->{_dbix};

    if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value} or ! defined $args{value})) { 
		throw Mcs::Exception::Internal(error => "Entity->setAttr need a name and value named argument!"); }

	eval {
		$self->checkAttr(%args);};
	if ($@){
		throw Mcs::Exception::Internal(error => "Entity->setAttr wrong attr name ($args{name}) or value ($args{value})!"); }
		
	if ( $data->has_column( $args{name} ) ) {
    		$data->set_column( $args{name}, $args{value} );	
    }
    elsif ( $self->extension() ) {
    	# TODO check if ext param name is a valid name for this entity
    	$self->{ _ext_attrs }{ $args{name} } = $args{value};
    }
    else {
    	warn "setAttrs() : No parameter named '$args{name}' for ", ref $self;
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
		throw Mcs::Exception::Internal(error => "Entity->setAttrs need an attrs hash named argument!"); }


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
		throw Mcs::Exception::Internal(error => "Entity->setAttrs need an attrs hash named argument!"); }


	$log->info(ref($self) . " getAttr of $args{name}");
	
	if ( $data->has_column( $args{name} ) ) {
		$value = $data->get_column( $args{name} );
		$log->info("  found value = $value");
	}
	elsif ( exists $self->{_ext_attrs}{ $args{name} } ) {
			$value = $self->{_ext_attrs}{ $args{name} };
			$log->info("  found value = $value (in ext local)");
		}
		else {
			throw Mcs::Exception::Internal(error => "Entity->setAttr no attr name $args{name}!");
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
		#print "\n##### MODIFY \n";
		$data->update;
		$self->_saveExtendedAttrs();
	}
	else {
		# CREATE
		my $relation = lc(ref $self);
		$relation =~ s/.*\:\://g;
		print "la relation: $relation\n";
		my $newentity = $self->{_dbix}->insert;
		$log->debug("new entity inserted.");
		my $row = $self->{_rightschecker}->{_schema}->resultset('Entity')->create(
			{ "${relation}_entities" => [ { "${relation}_id" => $newentity->get_column("${relation}_id")} ] },
		);
		$log->debug("new $self inserted with his entity relation.");
		$self->{_entity_id} = $row->get_column('entity_id');
		
		$self->_saveExtendedAttrs();
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
	
	if ( $ext_attrs )
	{
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
	
	my $entity = $self->{_rightschecker}->{_schema}->resultset('Entity')->find( { entity_id => $self->{_entity_id} } );
	if ( $entity ) {
		$entity->delete;
	}
	
	# Delete extended Attrs (cascade delete)
	my $extension = $self->extension();
	if ($extension) {
		my $Attrs_rs = $data->related_resultset( $extension );
		if ( $Attrs_rs )
		{
			$Attrs_rs->delete;	
		}
	}
	
	$data->delete;

}

# destructor
    
sub DESTROY {}

1;
