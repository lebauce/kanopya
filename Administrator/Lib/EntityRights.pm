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

=cut

package EntityRights;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use lib qw(../../Common/Lib);
use McsExceptions;
use Data::Dumper;

use vars qw(@ISA $VERSION);

my $log = get_logger("administrator");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# TODO get out user identification

=head2 new

	Class : Public
	
	Desc : constructor method
	
	args:
		schema : AdministratorDB::Schema object : DBIx database schema
		login : string : user login
		password : string : user password
	return: EntityRights

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
		
	bless $self, $class;
 	return $self;
}

=head2 getRights

	Class : Public
	
	Desc : return true if the right between a consumer entity object and a consumed entity object exists
	
	args :
		consumer : Entity object : the consumer object
		consumed : Entity object : the consumed object
		right : character (r/w/x)
	return : bool (integer 0/1)

=cut

sub getRights {
	my $self = shift;
	my %args = @_;
	if (! exists $args{consumer} or ! defined $args{consumer}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a consumer named argument!"); }
	    
	if(! exists $args{consumed} or ! defined $args{consumed}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a consumed named argument!"); }
		
	if(! exists $args{right} or ! defined $args{right}) { 
		throw Mcs::Exception::Internal(error => "EntityRights->getRights need a right named argument!"); }
	    	
	my $consumer_ids = $self->_getEntityIds( entity => $args{consumer} );
	$log->debug("consumer ids found: ".Dumper $consumer_ids);
	my $consumed_ids = $self->_getEntityIds( entity => $args{consumed} );
	$log->debug("consumed ids found: ".Dumper $consumed_ids);
	
	my $row = $self->{_schema}->resultset('Entityright')->search(
		{
			entityright_consumer_id => $consumer_ids,
			entityright_consumed_id => $consumed_ids,
		},
		{ select => [
			'entityright_consumer_id',
			'entityright_consumed_id',
			'entityright_rights' ],
			order_by => { -desc => ['entityright_rights']},
		}
	)->first;
	if($row) { 
		$log->debug("Upper rights found: ".$row->entityright_rights);
		return $self->_rightsConversion(rights => $row->entityright_rights); };
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
	
	# TODO verify rights format
	
	# we retrieve the rights row if exists
	my $row = $self->{_schema}->resultset('Entityright')->search(
		{
			entityright_consumer_id => $args{consumer}->{_dbix}->entitylink->get_column('entity_id'),
			entityright_consumed_id => $args{consumed}->{_dbix}->entitylink->get_column('entity_id')
		},
	)->single;
	
	if($args{rights} eq 0 or $args{rights} eq '') {
		# no right so we remove the row 
		$row->delete;
		
	} else {
		# row exists so we update it
		if(defined $row) {
			$row->entityright_rights( $self->_rightsConversion(rights => $args{rights}) );
			$row->update;
			
		} else {
		# row does not exist so we create it
			$row = $self->{_schema}->resultset('Entityright')->new({
				entityright_consumer_id => $args{consumer}->{_dbix}->entitylink->get_column('entity_id'),
				entityright_consumed_id => $args{consumed}->{_dbix}->entitylink->get_column('entity_id'),
				entityright_rights => $self->_rightsConversion(rights => $args{rights})
			});
			$row->insert;
		}	
	}
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
	my $entity_id = $args{entity}->{_dbix}->entitylink->get_column('entity_id');
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
			'r' return 2 (write)
			'rx' return 3 (read/execution)
			'w' return 4 (read)  
			'wx' return 5 (write/execution)
			'rw' return 6 (read/write)
			'rwx' return 7 (read/write/execution)
			1 return 'x'
			2 return 'r'
			3 return 'rx'
			4 return 'w'
			5 return 'wx'
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
	
	# TODO find a best solution
	return 'x' if($args{rights} eq 1);
	return 'r' if($args{rights} eq 2);
	return 'rx' if($args{rights} eq 3);
	return 'w' if($args{rights} eq 4);
	return 'wx' if($args{rights} eq 5);
	return 'rw' if($args{rights} eq 6);
	return 'rwx' if($args{rights} eq 7);
	return 1 if($args{rights} eq 'x');
	return 2 if($args{rights} eq 'r');
	return 3 if($args{rights} eq 'rx');
	return 4 if($args{rights} eq 'w');
	return 5 if($args{rights} eq 'wx');
	return 6 if($args{rights} eq 'rw');
	return 7 if($args{rights} eq 'rwx');
		
	throw Mcs::Exception::Internal(error => 
		"EntityRights->_rightsConversion: bad rights named argument (possible values are 0, 1, 2, 3, 4, 5, 6, 7, '', 'r', 'w', 'x', 'rw', 'rx', 'wx', 'rwx')"); 
}


=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut