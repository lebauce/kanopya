# Motherboardmodel.pm - This object allows to manipulate Motherboard model
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

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
# Created 11 aug 2010
package Entity::Motherboardmodel;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	motherboardmodel_brand => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	motherboardmodel_name => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	motherboardmodel_chipset => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_processor_num => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_consumption => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	motherboardmodel_iface_num => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_ram_slot_num => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	motherboardmodel_ram_max => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
	processormodel_id => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },
};

sub methods {
	return {
		'create'	=> {'description' => 'create a new motherboard model', 
						'perm_holder' => 'mastergroup',
		},
		'get'		=> {'description' => 'view this motherboard model', 
						'perm_holder' => 'entity',
		},
		'update'	=> {'description' => 'save changes applied on this motherboard model', 
						'perm_holder' => 'entity',
		},
		'remove'	=> {'description' => 'delete this motherboard model', 
						'perm_holder' => 'entity',
		},
		'setperm'	=> {'description' => 'set permissions on this motherboard model', 
						'perm_holder' => 'entity',
		},
	}; 
}

=head2 get

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Motherboardmodel->new need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $adm = Administrator->new();
   	my $motherboardmodel = $adm->{db}->resultset('Motherboardmodel')->find($args{id});
   	if(not defined $motherboardmodel) {
   		$errmsg = "Entity::Motherboardmodel->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	} 
   	my $entity_id = $motherboardmodel->entitylink->get_column('entity_id');
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get motherboard model with id $args{id}");
   	}
  	my $self = $class->SUPER::get( %args,  table => "Motherboardmodel");
   	return $self;
}

=head2 getMotherboardmodels

=cut

sub getMotherboardmodels {
	my $class = shift;
    my %args = @_;

	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getMotherboardmodels need a type and a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Motherboardmodel");
}

=head2 new

=cut

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Motherboardmodel");
	
	# Set the extended parameters
	$self->{_ext_attrs} = $attrs->{extended};

    return $self;
}

=head2 create

=cut

sub create {
	my $self = shift;
	my $adm = Administrator->new();
	my $mastergroup_eid = $self->getMasterGroupEid();
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new motherboardmodel");
   	}
   	
   	$self->save();
}

=head2 update

=cut 

sub update {}

=head2 remove

=cut

sub remove {
	my $self = shift;
	my $adm = Administrator->new();
	# delete method concerns an existing entity so we use his entity_id
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'remove');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to delete this motherboard model");
   	}
	$self->SUPER::delete();
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('motherboardmodel_name')." ".$self->{_dbix}->get_column('motherboardmodel_brand');
	return $string;
}

sub getAttrDef{
    return ATTR_DEF;
}
1;
