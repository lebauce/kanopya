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
    	_rightschecker => $args{rightschecker},
        _data => $args{data},
        _ext_params => {},
    };
    bless $self, $class;
    
    # getting groups where we find this entity (entity already exists)
	if($self->{_data}->in_storage) {
		$self->{_groups} = $self->{_rightschecker}->getGroups(EntityId => $self->{_data}->get_column('entity_id'));
	}
	$log->warn("new return $self");
    return $self;
}

=head2 getAllAttrs

	return a hash with all (param => value) of our data, including extending Attrs

=cut

sub getAllAttrs {
	my $self = shift;
	my $data = $self->{_data};
	
	# build hash corresponding to class table (with local changes)
	my %attrs = $data->get_columns;
	
	# add extended Attrs from db
	if ( $data->extended_table ) {
		my $ext_attrs_rs = $data->search_related( $data->extended_table );
		while ( my $param = $ext_attrs_rs->next ) {
			$attrs{ $param->name } = $param->value;
		}
	}
	
	# add local extended Attrs (localy changed ext Attrs override ext Attrs load from db)
	my $local_ext_attrs = $self->{_ext_attrs};
	#TODO Search a clean concatenation method
	my %all_attrs = ( %attrs, %$local_ext_attrs );

	return %all_attrs;	
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
	my $data = $self->{_data};

    if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value} or ! defined $args{value})) { 
		throw Mcs::Exception::Internal(error => "Entity->setAttr need a name and value named argument!"); }

	if ( $data->has_column( $args{name} ) ) {
    		$data->set_column( $args{name}, $args{value} );	
    }
    
    elsif ( $data->extended_table ) {
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
    my $data = $self->{_data};
    my $value = undef;
    
	if (! exists $args{name} or ! defined $args{name}) { 
		throw Mcs::Exception::Internal(error => "Entity->setAttrs need an attrs hash named argument!"); }


	$log->info(ref($self) . " getAttr of $args{name}");
	
	if ( $data->has_column( $args{name} ) ) {
		$value = $data->get_column( $args{name} );
		$log->info("  found value = $value");
	}
	else # search extended
	{
		# in local hash
		if ( $self->{_ext_attrs}{ $args{name} } ) {
			$value = $self->{_ext_attrs}{ $args{name} };
			$log->info("  found value = $value (in ext local)");
		}
		# in extented table
		elsif ($data->extended_table) {
			my $resultset = $data->search_related( $data->extended_table, {name => $args{name}} );
			if ( $resultset->count == 1 ) {
				$value = $resultset->next->value;
				$log->info("  found value = $value (in ext table)");
			}
		}
	}
	
	warn( "getValue() : No parameter named '$args{name}' for ", ref $self ) if ( ! defined $value );
		
	return $value;
}


=head2 save
	
	Save entity data in DB afer rights check
	Support entity creation or modification
	
=cut

sub save {
	my $self = shift;
	my $data = $self->{_data};
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
		my $newentity = $self->{_data}->insert;
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
	WARN: this will insert _data in DB if it's not already in
	
=cut

sub _saveExtendedAttrs {
	my $self = shift;
	my $ext_Attrs = $self->{_ext_attrs};
	my $data = $self->{_data};
	
	if ( $ext_Attrs )
	{
		foreach my $k (keys %$ext_Attrs) {
			$data->update_or_create_related( $data->extended_table, { name => $k, value => $ext_Attrs->{$k} } );
		}
	}
}


=head2 delete
	
	Class : Public
	
	Desc : This method delete Entity in DB
	
=cut

sub delete {
	my $self = shift;
	my $data = $self->{_data};
	
	my $entity = $self->{_rightschecker}->{_schema}->resultset('Entity')->find( { entity_id => $self->{_entity_id} } );
	if ( $entity ) {
		$entity->delete;
	}
	
	# Delete extended Attrs (cascade delete)
	if ( $data->extended_table ) {
		my $Attrs_rs = $data->related_resultset( $data->extended_table );
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
