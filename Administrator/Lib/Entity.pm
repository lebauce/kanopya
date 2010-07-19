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

my $log = get_logger("administrator");


=head2 new

	Constructor
	args: data, rightschecker
	
=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {
    	_rightschecker => $args{rightschecker},
        _data => $args{data},
        _ext_params => {},
    };
    bless $self, $class;

    return $self;
}

=head2 getAllParams

	return a hash with all (param => value) of our data, including extending params

=cut

sub getAllParams {
	my $self = shift;
	
	# build hash corresponding to class table (with local changes)
	my %params = $self->{_data}->get_columns;
	
	# add extended params from db
	if ( $self->{_ext} ) {
		my $ext_params_rs = $self->{_data}->search_related( $self->{_ext} );
		while ( my $param = $ext_params_rs->next ) {
			$params{ $param->name } = $param->value;
		}
	}
	
	# add local extended params (localy changed ext params override ext params load from db)
	my $local_ext_params = $self->{_ext_params};
	my %all_params = ( %params, %$local_ext_params );

	return %all_params;	
}

=head2 asString

	Return a string with the entity class name an all of its data

=cut

sub asString {
	my $self = shift;
	
	my %h = $self->getAllParams;
	my @s = map { "$_ => $h{$_}, " } keys %h;
	return ref $self, " ( ",  @s,  " )";
}

=head2 setValue
	
	args: name, value
	set entity param 'name' to 'value'
	Follow 'ext' link to set extended params
	
=cut

sub setValue {
	my $self = shift;
	my %args = @_;

	if ( $self->{_data}->has_column( $args{name} ) ) {
    		$self->{_data}->set_column( $args{name}, $args{value} );	
    }
    elsif ( $self->{_ext} ) {
    	# TODO check if ext param name is a valid name for this entity
    	$self->{ _ext_params }{ $args{name} } = $args{value};
    }
    else {
    	warn "setValues() : No parameter named '$args{name}' for ", ref $self;
    }

}

=head2 setValues
	
	args: 
		params : { p1 => v1, p2 => v2, ... }
	
	Set all entity params pX to corresponding value vX, including ext params
	
=cut

sub setValues {
	my $self = shift;
	my %args = @_;

	my $params = $args{params};
	while ( (my $col, my $value) = each %$params ) {
    	$self->setValue( name  => $col, value => $value );
	}
	
}


=head2 getValue
	
	args: name
	return value of param 'name'
	Follow 'ext' link to get extended params

=cut

sub getValue {
	my $self = shift;
    my %args = @_;
    my $value = undef;
    
	$log->info(ref($self) . " getValue of $args{name}");
	
	if ( $self->{_data}->has_column( $args{name} ) ) {
		$value = $self->{_data}->get_column( $args{name} );
		$log->info("  found value = $value");
	}
	else # search extended
	{
		# in local hash
		if ( $self->{_ext_params}{ $args{name} } ) {
			$value = $self->{_ext_params}{ $args{name} };
			$log->info("  found value = $value (in ext local)");
		}
		# in extented table
		elsif ($self->{_ext}) {
			my $resultset = $self->{_data}->search_related( $self->{_ext}, {name => $args{name}} );
			if ( $resultset->count == 1 ) {
				$value = $resultset->next->value;
				$log->info("  found value = $value (in ext table)");
			}
		}
	}
	
	warn( "getValue() : No parameter named '$args{name}' for ", ref $self ) if ( ! defined $value );
		
	return $value;
}

sub update {
}

=head2 save
	
	Save entity data in DB afer rights check
	Support entity creation or modification
	
=cut

sub save {
	my $self = shift;

	#TODO check rights

	if ( $self->{_data}->in_storage ) {
		# MODIFY existing db obj
		#print "\n##### MODIFY \n";
		$self->{_data}->update;
		$self->_saveExtendedParams();
	}
	else {
		# CREATE
		my $newentity = $self->{_data}->insert;
		$self->_saveExtendedParams();
		#my $row = $self->{_rightschecker}->{_schema}->resultset('Entity')->create(
		#	{ user_entities => [ {user_id => $newentity->get_column('user_id')} ] },
		#);
		#$self->{_entity_id} = $row->get_column('entity_id');
	}
		
}

=head2 _saveExtendedParams

	add or update extended params on the related table 'ext'
	WARN: this will insert _data in DB if it's not already in
	
=cut

sub _saveExtendedParams {
	my $self = shift;
	my $ext_params = $self->{_ext_params};
	my $data = $self->{_data};
	
	if ( $ext_params )
	{
		foreach my $k (keys %$ext_params) {
			$data->update_or_create_related( $self->{_ext}, { name => $k, value => $ext_params->{$k} } );
		}
	}
}

=head2 delete

	Delete entity data in DB 
	
=cut

sub delete {
	my $self = shift;
	
	my $entity = $self->{_rightschecker}->{_schema}->resultset('Entity')->find( { entity_id => $self->{_entity_id} } );
	if ( $entity ) {
		$entity->delete;
	}
	
	# Delete extended params (cascade delete)
	if ( $self->{_ext} ) {
		my $params_rs = $self->{_data}->related_resultset( $self->{_ext} );
		if ( $params_rs )
		{
			$params_rs->delete;	
		}
	}
	
	$self->{_data}->delete;

}


# destructor
    
sub DESTROY {}

1;
