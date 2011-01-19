# EntityRights.pm  

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
# Created 16 july 2010

=head1 NAME

EntityRights

=head1 SYNOPSIS


=head1 DESCRIPTION

	Base class for EntityRights::User/System
	Provide setPerm, _getEntityds and getPerms method

=cut

package EntityRights;

use strict;
use warnings;
use Kanopya::Exceptions;
use Log::Log4perl "get_logger";

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

=head2 _getEntityIds

	Class : Protected
	
	Desc : return an array reference containing entity id and its groups entity ids
	
	args :
			entity_id : entity_id about an entity object
	return : array reference of entity_id 

=cut

sub _getEntityIds {
	my $self = shift;
	my %args = @_;
	
	if (! exists $args{entity_id} or ! defined $args{entity_id}) { 
		$errmsg = "EntityRights->_getEntityIds: need an entity_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}

	my $ids = [];
	# TODO verifier que l'entity_id fournis exists en base
	push @$ids, $args{entity_id};
	
	# retrieve entity_id of groups containing this entity object
	my @groups = $self->{schema}->resultset('Groups')->search( 
		{ 'ingroups.entity_id' => $args{entity_id} },
		{ 
			columns 	=> [], 									# use no columns from Groups table
			'+columns' 	=> [ 'groups_entities.entity_id' ], 	# but add the entity_id column from groups_entity related table
			join 		=> [qw/ingroups groups_entities/],
		}
	);
	# add entity_id groups to the arrayref
	foreach my $g (@groups) { 
		push @$ids, $g->get_column('entity_id');
	}
	
	return $ids;
}

=head2 addPerm

	Class : public
	Desc : given a consumer_id - User (or Groups with user type) entity id - a consumed_id 
		   and a method, grant the permission to that consumed method for that 
		   consumer entity 
	args:
		consumer : Entity::User instance or Entity::Groups instance
		consumed : Entity::* instance
		method   : scalar (string) : method name

=cut

sub addPerm {
	my $self = shift;
	my %args = @_;
	
	if (! exists $args{consumer_id} or ! defined $args{consumer_id}) { 
		$errmsg = "EntityRights::addPerm need a consumer_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	if (! exists $args{consumed_id} or ! defined $args{consumed_id}) { 
		$errmsg = "EntityRights::addPerm need a consumed_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	if (! exists $args{method} or ! defined $args{method}) { 
		$errmsg = "EntityRights::addPerm need a method named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	
	# TODO verifier que la methode donnée en argument exists sur l'entity
	# représentée par consumed_id
	
	$self->{schema}->resultset('Entityright')->find_or_create(
		{	entityright_consumer_id => $args{consumer_id},
			entityright_consumed_id => $args{consumed_id},
			entityright_method => $args{method}
		},
		{ key => 'entityright_right' },	
	);
	return;
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut