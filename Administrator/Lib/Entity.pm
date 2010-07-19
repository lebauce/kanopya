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
    };
    bless $self, $class;

    return $self;
}

=head2 setValue
	
	args: name, value
	set entity param 'name' to 'value'
	
=cut

sub setValue {
	my $self = shift;
	my %args = @_;

	$self->{_data}->set_column( $args{name}, $args{value} );
}

=head2 setValues
	
	args: 
		params : { p1 => v1, p2 => v2, ... }
	
	Set all entity params pX to corresponding value vX
	Follow 'ext' link to set extended params transparently
	
=cut

sub setValues {
	my $self = shift;
	my %args = @_;

	my %ext_params;
	my $params = $args{params};
	while ( (my $col, my $value) = each %$params ) {
    	if ( $self->{_data}->has_column( $col ) ) {
    		$self->{_data}->set_column( $col, $value );	
    	}
    	# TODO check if ext param name is a valid name for this entity
    	elsif ( $self->{ext} ) {
    		$ext_params{ $col } = $value;
    		$self->{_data}->create_related( $self->{ext}, { name => $col, value => $value } );
    	}
    	else {
    		die "setValues() : No parameter '$col' for ", ref $self;
    	}
	}
	
}


=head2 getValue
	
	args: name
	return value of param 'name'
	Follow 'ext' link to get extended params transparently

=cut

sub getValue {
	my $self = shift;
    my %args = @_;
    my $value = undef;
    
	$log->info(ref($self) . " getValue of $args{name}");
	if ($self->{ext}) {
		my $resultset = $self->{_data}->search_related( $self->{ext}, {name => $args{name}} );
		if ( $resultset->count == 1 ) {
			$value = $resultset->next->value;
			$log->info("  found value = $value (in extended table)");
		}	
	}
	
	if ( ! $value ) {
		$value = $self->{_data}->get_column( $args{name} );
		$log->info("  found value = $value");
	}
	
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
	}
	else {
		# CREATE
		my $newentity = $self->{_data}->insert;
		my $row = $self->{_rightschecker}->{_schema}->resultset('Entity')->create(
			{ user_entities => [ {user_id => $newentity->get_column('user_id')} ] },
		);
		$self->{_entity_id} = $row->get_column('entity_id');
	}
		
}

=head2 delete

	Delete entity data in DB 
	
=cut

sub delete {
	my $self = shift;
	
	$self->{_rightschecker}->{_schema}->resultset('Entity')->find( { entity_id => $self->{_entity_id} } )->delete;
	
	# Delete extended params (cascade delete)
	if ( $self->{ext} ) {
		my $params_rs = $self->{_data}->related_resultset( $self->{ext} );
		$params_rs->delete;
	}
	
	$self->{_data}->delete;

}

sub _deleteExt {
	
}

# destructor
    
sub DESTROY {}

1;
