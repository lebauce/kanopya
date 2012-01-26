# Openldap1.pm - Openldap1 component
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
# Created 4 sept 2010

=head1 NAME

<Entity::Component::Openldap1> <Openldap1 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Openldap1> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Openldap1>;

my $component_instance_id = 2; # component instance id

Entity::Component::Openldap1->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Openldap1->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Openldap1 is class allowing to instantiate a Openldap1 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Openldap1;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Crypt::SaltedHash;

my $log = get_logger("administrator");
my $errmsg;

sub insertDefaultConfiguration {
    my $self = shift;
    my %args = @_;
    my $default_conf = { 
    	openldap1_id => undef,
    	openldap1_port 	=>	389, 
    	openldap1_suffix =>	"dc=nodomain",
		openldap1_directory  =>	"/var/lib/ldap",
		openldap1_rootdn =>	"dc=admin,dc=nodomain",
		openldap1_rootpw => undef
    };
   $self->{_dbix}->create($default_conf);
}

#sub getConf {
#    my $self = shift;
#    my $conf = {};
#    my $confindb = $self->{_dbix};
#    if($confindb) {   
#        #TODO build conf hash with db data    
#    }
#   return $conf;
#}

sub getConf {
    my $self = shift;
    my $slapd_conf = {
    	openldap1_id => undef,
    	openldap1_port 	=>	389, 
    	openldap1_suffix =>	"dc=nodomain",
		openldap1_directory  =>	"/var/lib/ldap",
		openldap1_rootdn =>	"dc=admin,dc=nodomain",
		openldap1_rootpw => ""
    };
    
    my $confindb = $self->{_dbix};
    if($confindb) {
       $slapd_conf = {
         openldap1_id  => $confindb->get_column('openldap1_id'),
         openldap1_port   => $confindb->get_column('openldap1_port'),
         openldap1_suffix  => $confindb->get_column('openldap1_suffix'),
         openldap1_directory => $confindb->get_column('openldap1_directory'),
         openldap1_rootdn  => $confindb->get_column('openldap1_rootdn'),
         openldap1_rootpw  => $confindb->get_column('openldap1_rootpw')           
       };    
    }
    $log->debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" . Dumper $slapd_conf);
    return $slapd_conf; 
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;   
   
   $log->debug(">>>>>>>>>>>>>>>>>>>>>>" . Dumper  $conf);  
    my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
      		#$conf->{openldap1_rootpw}='splendid';
      		my $a=$conf->{openldap1_rootpw}; 
      		$csh->add($a);
      		  	my $salted = $csh->generate;
      		    print $salted;
     		$conf->{openldap1_rootpw}=$salted;
   $self->{_dbix}->update($conf);
}    


sub getNetConf {
    #TODO return { port => [protocol] };
    my $self = shift;
    my $port = $self->{_dbix}->get_column('openldap1_port');
    return { $port => ['tcp'] };
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
