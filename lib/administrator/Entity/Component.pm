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

use strict;

use base "Entity";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
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
