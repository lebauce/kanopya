# General.pm - This lib contain general function used in microCluster system

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
# Created 14 july 2010

=head1 NAME

General - Common Lib

=head1 SYNOPSIS

    use General;
    
    # Get EEntity Location from Entity
    my $execloc = General::getLocEEntityFromEntity($entity : Entity);
    
    # Get EEntity Class name from Entity
    my $execclass = General::getClassEEntityFromEntity($entity : Entity);


=head1 DESCRIPTION

Executor is the main object use to create execution objects

=head1 METHODS

=cut
package General;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use strict;
use warnings;

my $log = get_logger("executor");
my $errmsg;

sub getClassEEntityFromEntity{
	my %args = @_;
	my $data = $args{entity};
#	$log->debug("Try to get Eentity class from object". ref($data));
	
	if(! exists($args{entity})) {
		$errmsg = "Try to get Eentity class from object not entity : ". ref($args{entity});
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);	
	}
		 
	my $entityclass = ref($args{entity});
	my $class = $entityclass;
	$class =~s/\:\:/\:\:E/g;
    $class = "E".$class;
#    $log->debug("$class retrieved from ".ref($args{entity}));
    return $class;
}

#TODO Tester si les regexp fonctionne en simulant le use.
sub getLocFromClass{
	my %args = @_;
	
	   if (! exists $args{entityclass} or ! defined $args{entityclass}) { 
		$errmsg = "getLocFromClass need a  entityclass named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
    }
	my $data = $args{entityclass};
	my $location = $args{entityclass};
    $location =~ s/\:\:/\//g;
    return $location . ".pm";
}

sub getClassEntityFromType{
    my %args = @_;
    
    if (! exists $args{type} or ! defined $args{type}) { 
		$errmsg = "getClassEntityFromType need a  type named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
    }
		
    
    my $requested_type = $args{type};
    my $obj_class = "Entity::$requested_type";
    return $obj_class;
}

=head2 getAsArrayRef
	
	Class : Public
	
	Desc : 	Util for hash loaded from an xml file with xml::simple and list management.
			<tag> could be mapped with a hash (if only one defined in xml) or an array of hash (if list of <tag>).
			This sub returns a array ref of <tag> in all cases.
			
			WARNING: don't use attribute ['name','id','key'] (see @DefKeyAttr in XML::Simple) in your xml tag when list context!
	
	Args :
		data : hash ref where one key is <tag> (but value could be hash ref or array ref)
		tag : string :the name of the tag 
	
	Return : Array ref with all hash ref corresponding to tag (in data).
	
=cut

sub getAsArrayRef {
	my %args = @_;
	
	my $data = $args{data};
	my $elems = $data->{ $args{tag} };
	if ( ref $elems eq 'ARRAY' ) {
		return $elems;
	}
	return $elems ? [$elems] : [];
}

=head2 getAsHashRef
	
	Class : Public
	
	Desc : 	Util for hash loaded from an xml file with xml::simple and list management.
			Map the value of an element of <tag> with the hash correponding to all elements of <tag> (without the key element)
			for all <tag> in data.
			
			WARNING: don't use attribute ['name','id','key'] (see @DefKeyAttr in XML::Simple) in your xml tag when list context!
	
	Args :
		data : hash ref where one key is <tag> (but value could be hash ref or array ref)
		tag : string : the name of the tag 
		key : string : name of a element of <tag> we want as key in the resulting hash
		
	Return : The resulting hash ref.
	
=cut

sub getAsHashRef {
	my %args = @_;
	
	my $key = $args{key};
	my $array = getAsArrayRef( data => $args{data}, tag => $args{tag} );
	my %res = ();
	for my $elem (@$array) {
		my %e = %$elem;
		my $val = delete $e{$key}; 
		$res{ $val } = \%e; 
	}
	return \%res;
}

1;