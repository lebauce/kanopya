# Kernel.pm - This object allows to manipulate Kernel configuration
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
# Created 7 july 2010
package Entity::Kernel;

use strict;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use base "Entity";

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	kernel_name => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	kernel_version => { pattern => 'm//s', is_mandatory => 1, is_extended => 0 },
	kernel_desc => { pattern => 'm//s', is_mandatory => 0, is_extended => 0 },

};



=head2 checkAttrs
	
	Desc : This function check if new object data are correct and sort attrs between extended and global
	args: 
		class : String : Real class to check
		data : hashref : Entity data to be checked
	return : hashref of hashref : a hashref containing 2 hashref, global attrs and extended ones

=cut

sub checkAttrs {
	# Remove class
	shift;
	my %args = @_;
	my (%global_attrs, %ext_attrs, $attr);
	my $attr_def = ATTR_DEF;
	#print Dumper $attr_def;
	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::Kernel->checkAttrs need an attrs hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			#TODO Check param with regexp in pattern field of struct
			if ($attr_def->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			$errmsg = "Entity::Kernel->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Kernel->checkAttrs detect a missing attribute $attr !";
				$log->error($errmsg);
				throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
			}
	}
	#TODO Check if id (systemimage, kernel, ...) exist and are correct.
	return {global => \%global_attrs, extended => \%ext_attrs};
}

=head2 checkAttr
	
	Desc : This function check new object attribute
	args: 
		name : String : Attribute name
		value : String : Attribute value
	return : No return value only throw exception if error

=cut

sub checkAttr{
	my $self = shift;
	my %args = @_;
	my $attr_def = ATTR_DEF;

	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value})) { 
		$errmsg = "Entity::Kernel->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::Kernel->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Kernel->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

sub extension { return undef; }

sub new {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) { 
		$errmsg = "Entity::Kernel->new need a data and rightschecker named argument!";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $ext_attrs = $args{ext_attrs};
	delete $args{ext_attrs};
    my $self = $class->SUPER::new( %args );
	$self->{_ext_attrs} = $ext_attrs;
	$self->{extension} = $self->extension();
    return $self;
}


1;
