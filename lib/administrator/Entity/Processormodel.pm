# Processormodel.pm - This object allows to manipulate Processor model
#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 17 july 2010
package Entity::Processormodel;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	processormodel_brand => { pattern => 'm//s', is_mandatory => 1, is_extended	=> 0},
	processormodel_name => { pattern => 'm//s', is_mandatory => 1, is_extended => 0},
 	processormodel_core_num => { pattern => 'm//s', is_mandatory => 0, is_extended => 0},
 	processormodel_clock_speed => { pattern => 'm//s', is_mandatory => 1, is_extended => 0},
  	#processormodel_fsb => { pattern => 'm//s', is_mandatory => 1, is_extended => 0},
  	processormodel_l2_cache => { pattern => 'm//s', is_mandatory => 1, is_extended	=> 0},
  	#processormodel_max_consumption => { pattern => 'm//s', is_mandatory => 1, is_extended => 0},
  	processormodel_max_tdp => { pattern => 'm//s', is_mandatory => 1, is_extended => 0},
  	processormodel_64bits => { pattern => 'm//s', is_mandatory => 1, is_extended => 0},
	#processormodel_cpu_flags => { pattern => 'm//s', is_mandatory => 1, is_extended	=> 0},		
};


sub methods {
	return {
		'create'	=> {'description' => 'create a new processor model', 
						'perm_holder' => 'mastergroup',
		},
		'get'		=> {'description' => 'view this processor model', 
						'perm_holder' => 'entity',
		},
		'update'	=> {'description' => 'save changes applied on this processor model', 
						'perm_holder' => 'entity',
		},
		'remove'	=> {'description' => 'delete this processor model', 
						'perm_holder' => 'entity',
		},
		'setperm'	=> {'description' => 'set permissions on this processor model', 
						'perm_holder' => 'entity',
		},
	}; 
}

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Processormodel->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $adm = Administrator->new();
   	my $processormodel = $adm->{db}->resultset('Processormodel')->find($args{id});
   	if(not defined $processormodel) {
   		$errmsg = "Entity::Processormodel->get : id <$args{id}> not found !";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
   	} 
   	my $entity_id = $processormodel->entitylink->get_column('entity_id');
   	my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
   	if(not $granted) {
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get processor model with id $args{id}");
   	}
	
   my $self = $class->SUPER::get( %args, table=>"Processormodel");
   return $self;
}

sub getProcessormodels {
	my $class = shift;
    my %args = @_;
	
	if ((! exists $args{hash} or ! defined $args{hash})) { 
		$errmsg = "Entity::getProcessormodels need a hash named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $adm = Administrator->new();
   	return $class->SUPER::getEntities( %args,  type => "Processormodel");
}

sub new {
	my $class = shift;
    my %args = @_;

	# Check attrs ad throw exception if attrs missed or incorrect
	my $attrs = $class->checkAttrs(attrs => \%args);
	
	# We create a new DBIx containing new entity (only global attrs)
	my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Processormodel");
	
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
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new processor model");
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
   		throw Kanopya::Exception::Permission::Denied(error => "Permission denied to delete this processor model");
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
	my $string = $self->{_dbix}->get_column('processormodel_name')." ".$self->{_dbix}->get_column('processormodel_brand');
	return $string;
}

1;
