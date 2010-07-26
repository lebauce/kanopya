# Entity::Groups.pm  

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

Entity::Groups

=head1 SYNOPSIS



=head1 DESCRIPTION

blablabla

=cut

package Entity::Groups;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use lib qw(../../../Common/Lib);
use McsExceptions;

use base "Entity";

=head2 new

	Class : Private
	
	Desc : constructor method

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
        
    return $self;
}

=head2 addEntity

	Class : Public
	
	Desc : add a entity object to the groups ; the entity must have been saved to the database before adding it to a group.
	Does nothing if already in this groups
	
	args:
		entity : Entity::* object : an Entity object

=cut

sub addEntity {
	my $self = shift;
	my %args = @_;
	if (! exists $args{entity} or ! defined $args{entity}) {  die "Entity::Groups->addEntity need an entity named argument!"; }
	# TODO check rights
}

=head2 removeEntity

	Class : Public
	
	Desc : remove an entity object from the groups
	
	args:
		entity : Entity::* object : an Entity object contained by the groups

=cut

sub removeEntity {
	my $self = shift;
	my %args = @_;
	if (! exists $args{entity} or ! defined $args{entity}) {  die "Entity::Groups->removeEntity need an entity named argument!"; }
	# TODO check rights
	

}

=head2 getEntities

	Class : Public
	
	Desc : remove an entity object from the groups
	
	args:
		entity : Entity::* object : an Entity object contained by the groups

=cut

sub getEntities {
	my $self = shift;
	my %args = @_;
	if (! exists $args{administrator} or ! defined $args{administrator}) {  die "Entity::Groups->getEntities need an administrator named argument!"; }
}



1;