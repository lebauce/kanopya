# Component.pm - This module is components generalization
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
# Created 3 july 2010
package Entity::Component;



use base "Entity";
use McsExceptions;
use Data::Dumper;
use strict;
use warnings;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

# contructor

sub new {
	my $class = shift;
    my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id})||
		(! exists $args{component_id} or ! defined $args{component_id})){ 
		$errmsg = "Entity::Component->new need a cluster_id and a component_id named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $admin = Administrator->new();
	my $template_id = undef;
	if(exists $args{component_template_id} and defined $args{component_template_id}) {
		$template_id = $args{component_template_id};
	}
	
	# check if component_id is valid
	my $row = $admin->{db}->resultset('Component')->find($args{component_id});
	if(not defined $row) {
		$errmsg = "Entity::Component->new : component_id does not exist";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}
	
	# check if instance of component_id is not already inserted for  this cluster
	$row = $admin->{db}->resultset('ComponentInstance')->search(
		{ component_id => $args{component_id}, 
		  cluster_id => $args{cluster_id} })->single;
	if(defined $row) {
		$errmsg = "Entity::Component->new : cluster has already the component with id $args{component_id}";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}
	
	# check if component_template_id correspond to component_id
	if(defined $template_id) {
		my $row = $admin->{db}->resultset('ComponentTemplate')->find($template_id);
		if(not defined $row) {
			$errmsg = "Entity::Component->new : component_template_id does not exist";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
		} elsif($row->get_column('component_id') != $args{component_id}) {
			$errmsg = "Entity::Component->new : component_template_id does not belongs to component specified by component_id";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
		}
	}
	# We create a new DBIx containing new entity
	my $self = $class->SUPER::new( attrs => \%args, table => "ComponentInstance");
    return $self;
}

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Component->get need an id named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args, table=>"ComponentInstance");
   return $self;
}

sub getTemplateDirectory {
	my $self = shift;
	if( defined $self->{_dbix}->get_column('component_template_id') ) {
		return $self->{_dbix}->component_template_id->get_column('component_template_directory');
	} else {
		return undef;
	}
}

sub getComponentAttr {
	my $self = shift;
	my %args = @_;
	my $componentAttr = {};
	
	$componentAttr->{component_name} = $self->{_dbix}->component_id->get_column('component_name');
	$componentAttr->{component_id} = $self->{_dbix}->component_id->get_column('component_id');	
	$componentAttr->{component_version} = $self->{_dbix}->component_id->get_column('component_version');
	$componentAttr->{component_category} = $self->{_dbix}->component_id->get_column('component_category');
	
	return $componentAttr;	
}

=head2 toString

	desc: return a string representation of the entity

=cut

sub toString {
	my $self = shift;
	my $string = $self->{_dbix}->component_id->get_column('component_name')." ".$self->{_dbix}->component_id->get_column('component_version');
	return $string;
}
1;
