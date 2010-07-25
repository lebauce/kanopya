# EntityRights.pm  

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
# Created 16 july 2010

=head1 NAME

EntityRights

=head1 SYNOPSIS



=head1 DESCRIPTION

Provide permissions management methods

=head1 METHODS

=cut

package EntityRights;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use lib qw(../../Common/Lib);
use McsExceptions;

use vars qw(@ISA $VERSION);

my $log = get_logger("administrator");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

new (schema => $schema, login => $login, password => $password)

simple constructer

=cut

sub new {
	my $class = shift;
	my %args = @_;
	if (! exists $args{schema} or ! defined $args{schema}) {  die "EntityRights->new need a schema named argument!"; }
	if (! exists $args{login} or ! defined $args{login}) {  die "EntityRights->new need a login named argument!"; }
	if (! exists $args{password} or ! defined $args{password}) {  die "EntityRights->new need a password named argument!"; }
	
	my $self = {
		_schema => $args{schema},
	};
		
	# check user identity
	$self->{_user} = $self->{_schema}->resultset('User')->search( 
		{ user_login => $args{login}, user_password => $args{password} },
		{ 
			'+columns' => ['user_entities.entity_id'],
    		join => ['user_entities'] 
		}
	)->single;
		
	if(! $self->{_user} ) {
		warn "incorrect login/password pair";
		return undef;
	}
	
	# get user groups
	my $groups = $self->{_schema}->resultset('Groups')->search(
	{ 'ingroups.entity_id' => $self->{_user}->get_column('entity_id') },
	{ 	'+columns' => [ 'groups_entities.entity_id' ], 
		join => [qw/ingroups groups_entities/] }
	);
		
	$self->{_groups} = $groups;	
		
	bless $self, $class;
 	return $self;
}

=head2 getRights

	Class : Public
	
	Desc : return an integer specifying rights between a consumer entity object and a consumed entity object
	
	args :
		consumer : Entity object : the consumer object
		consumed : Entity object : the consumed object
	return : integer

=cut

sub getRights {
	my $self = shift;
	my %args = @_;
	if (! exists $args{consumer} or ! defined $args{consumer}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a consumer named argument!"); }
	    
	if(! exists $args{consumed} or ! defined $args{consumed}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a consumed named argument!"); }
	    	
	my $consumer_ids = $self->_getEntityIds( entity => $args{consumer} );
	my $consumed_ids = $self->_getEntityIds( entity => $args{consumed} );
	
	my $row = $self->{_schema}->resultset('Entityright')->search(
		{
			entityright_consumer_id => $consumer_ids,
			entityright_consumed_id => $consumed_ids,
		},
		{ select => [
			'entityright_consumer_id',
			'entityright_consumed_id',
			{ max => 'entity_rights' }
			],
			as => [ qw/consumer_id consumed_id rights/ ],
		}
	)->single;
	if($row) { return $self->_rightsConversion($row->rights); };
	return '';
	
}

=head2 setRights

	Class : Public
	
	Desc : add/update/delete a row to the entityright table, specifying rights between two entity
	
	args :
		consumer : Entity object : the consumer object
		consumed : Entity object : the consumed object
		rights   : string
	
=cut

sub setRights {
	my $self = shift;
	my %args = @_;
	if (! exists $args{consumer} or ! defined $args{consumer}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a consumer named argument!"); }
	    
	if(! exists $args{consumed} or ! defined $args{consumed}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a consumed named argument!"); }
	
	if(! exists $args{rights} or ! defined $args{rights}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a rights named argument!"); }
	
	# we retrieve the rights row if exists
	my $row = $self->{_schema}->resultset('Entityright')->search(
		{
			entityright_consumer_id => $args{consumer}->entityright_consumer_id->get_column('entity_id'),
			entityright_consumed_id => $args{consumed}->entityright_consumed_id->get_column('entity_id')
		},
	)->single;
	
	
	if($args{rigths} eq 0 or $args{rigths} eq '') {
		# no right so we remove the row 
		$row->delete;
		
	} else {
		
	}
	
	
	$self->_rightsConversion;
}

=head2 _getEntityIds

	Class : Private
	
	Desc : return an array reference containing entity id and its groups entity ids
	
	args :
		entity : Entity object : the entity object
	return : array reference of integers 

=cut

sub _getEntityIds {
	my $self = shift;
	my %args = @_;
	if (! exists $args{entity} or ! defined $args{entity}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->_getEntityIds: need an entity named argument!"); }

	my $ids = [];
	# get the entity_id value and add it to the arrayref
	my $entity_id = $args{entity}->entitylink->get_column('entity_id');
	push @$ids, $entity_id;
	
	# retrieve entity_id of groups containing this entity object
	my @groups = $self->{_schema}->resultset('Groups')->search( 
		{ 'ingroups.entity_id' => $entity_id },
		{ 
			columns => [], 									# use no columns from Groups table
			'+columns' => [ 'groups_entities.entity_id' ], 	# but add the entity_id column from groups_entity related table
			join => [qw/ingroups groups_entities/]
		}
	);
	# add entity_id groups to the arrayref
	foreach my $g (@groups) { push @$ids, $g->get_column('entity_id'); }
	return $ids;
}

=head2 _righsConversion

	Class : Private
	
	Desc : depending of the passed argument type (integer or string), return the corresponding rwx integer/string.
	Example: called with
			'x' return 1 (execution)
			'w' return 2 (write)
			'r' return 4 (read)  
			'rw' return 6 (read/write)
			'rwx' return 7 (read/write/execution)
			1 return 'x'
			2 return 'w'
			3 return 'wx'
			4 return 'r'
			5 return 'rx'
			6 return 'rw'
			7 return 'rwx'
	args :
		rights : integer/string 
	return : integer/string 

=cut

sub _rightsConversion {
	my $self = shift;
	my %args = @_;
	if (! exists $args{rights} or ! defined $args{rights}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->_rightsToString: need a rights named argument!"); }
	
	# TODO find 
	return 'x' if($args{rights} eq 1);
	return 'w' if($args{rights} eq 2);
	return 'wx' if($args{rights} eq 3);
	return 'r' if($args{rights} eq 4);
	return 'rx' if($args{rights} eq 5);
	return 'rw' if($args{rights} eq 6);
	return 'rwx' if($args{rights} eq 7);
	return 1 if($args{rights} eq 'x');
	return 2 if($args{rights} eq 'w');
	return 3 if($args{rights} eq 'wx');
	return 4 if($args{rights} eq 'r');
	return 5 if($args{rights} eq 'rx');
	return 6 if($args{rights} eq 'rw');
	return 7 if($args{rights} eq 'rwx');
		
	throw Mcs::Exception::Internal(error => "EntityRights->_rightsConversion: bad rights named argument!"); 
}


=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut