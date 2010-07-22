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

=head2 getGroups

return groups resultset containing entity with entity_id

=cut

sub getGroups {
	my $self = shift;
	my %args = @_;
	if (! exists $args{EntityId} or ! defined $args{EntityId}) {  die "EntityRights->getGroups need a EntityId named argument!"; }
	
	my $groups = $self->{_schema}->resultset('Groups')->search(
	{ 'ingroups.entity_id' => $args{EntityId} },
	{ 	'+columns' => [ 'groups_entities.entity_id' ], 
		join => [qw/ingroups groups_entities/] }
	);
	return $groups;
}

=head2 _getRights

Get rights result of association between 2 entityData objetcs

=cut

sub _getRights {
	my $self = shift;
	my %args = @_;
	if (! exists $args{EntityId} or ! defined $args{EntityId}) {  die "EntityRights->getRights need a EntityId named argument!"; }
	if (! exists $args{ConsumerId} or ! defined $args{ConsumerId}) {  die "EntityRights->getRights need a ConsumerId named argument!"; }
	
	my $res = $self->{_schema}->resultset('Entityright')->single( {
		entityright_entity_id =>  $args{EntityId},
		entityright_consumer_id =>  $args{ConsumerId} }
	);
	if( ! $res ) { die 'EntityRights->getRights : no record found.'; }
	return $res;
}

=head2 canGet

Check if a user has rights to retrieve an EntityData object

=cut

sub canGet {
	my $self = shift;
	my %args = @_;
	if (! exists $args{userEntityId} or ! defined $args{userEntityId}) {  die "EntityRights->getRights need a userEntityId named argument!"; }
	if (! exists $args{EntityId} or ! defined $args{EntityId}) {  die "EntityRights->getRights need a secondEntityId named argument!"; }
	
	my $groupadmin = $self->{_groups}->find({group_name => 'admin'});
	
	return;
}

=head2 canNew

Check if a user has rights to instanciate an EntityData object

=cut

sub canNew {
	my $self = shift;
	my %args = @_;
	if (! exists $args{userEntityId} or ! defined $args{userEntityId}) {  die "EntityRights->getRights need a userEntityId named argument!"; }
	if (! exists $args{EntityId} or ! defined $args{EntityId}) {  die "EntityRights->getRights need a secondEntityId named argument!"; }
	
	
	
	return;
}



=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut