# Powersupplycardmodel.pm - This object allows to manipulate Powersupplycard model
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
# Created 17 july 2010
package Entity::Powersupplycardmodel;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	powersupplycardmodel_name => { pattern => 'm/\w*/s',
						  is_mandatory => 1,
						  is_extended => 0 },
	
	powersupplycardmodel_brand => { pattern => 'm/\w*/s',
						  is_mandatory => 1,
						  is_extended => 0 },
	
	powersupplycardmodel_slotscount => { pattern => 'm//s',
						 is_mandatory => 1,
						 is_extended => 0 },
};


sub methods {
	return {
		'create'	=> {'description' => 'create a new powersupply card model', 
						'perm_holder' => 'mastergroup',
		},
		'get'		=> {'description' => 'view this powersupply card model', 
						'perm_holder' => 'entity',
		},
		'update'	=> {'description' => 'save changes applied on this powersupply card model', 
						'perm_holder' => 'entity',
		},
		'remove'	=> {'description' => 'delete this powersupply card model', 
						'perm_holder' => 'entity',
		},
		'setperm'	=> {'description' => 'set permissions on this powersupply card model', 
						'perm_holder' => 'entity',
		},
	}; 
}

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Powersupplycardmodel->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $adm = Administrator->new();
   	my $powersupplycardmodel = $adm->{db}->resultset('Powersupplycardmodel')->find($args{id});
   	if(not defined $powersupplycardmodel) {
   		$errmsg = "Entity::Powersupplycardmodel->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	} 
   	my $entity_id = $powersupplycardmodel->entitylink->get_column('entity_id');
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get powersupply card model with id $args{id}");
   	}
	
   my $self = $class->SUPER::get( %args, table=>"Powersupplycardmodel");
   return $self;
}

sub getPowersupplycardmodels {
	my $class = shift;
    my %args = @_;
	
	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getPowersupplycardmodels need a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Powersupplycardmodel");
}

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Powersupplycardmodel");
	
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
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new powersupply card model");
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
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to delete this powersupply card model");
   	}
	$self->SUPER::delete();
}

sub getAttrDef{
    return ATTR_DEF;
}

sub extension { return; }

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->get_column('powersupplycardmodel_brand')." ".$self->{_dbix}->get_column('powersupplycardmodel_name');
	return $string;
}

1;
