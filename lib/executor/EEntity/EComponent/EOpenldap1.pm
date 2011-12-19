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
package EEntity::EComponent::EOpenldap1;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";
use Data::Dumper;
use General;

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

# generate configuration files on node
sub configureNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point']);

    #TODO insert configuration files generation
}

sub addNode {
    my $self = shift;
    my %args = @_;    
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point']);   
    $self->configureNode(%args);   
    #TODO addInitScript(..) if there is a daemon associated to this component
    my $data = $self->_getEntity()->getConf();    
 
   
    my $data1={};
   
		foreach my $key ('openldap1_suffix','openldap1_directory','openldap1_rootdn','openldap1_rootpw'){
        		$data1->{$key}=$data->{$key};    
    	} 
     
     my $data2 ->{openldap1_suffix}= $data->{openldap1_suffix};   
     my $data3->{openldap1_port}=$data->{openldap1_port};
    
    
    # generation of /etc/ldap/slapd.conf
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/openldap",
                         input_file => "slapd.conf.tt", output => "/ldap/slapd.conf", data => $data1);
                         
     # generation of /etc/ldap/ldap.conf
     $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/openldap",
                         input_file => "ldap.conf.tt", output => "/ldap/ldap.conf", data => $data2);
    
    
     # generation of /etc/default/slapd
     $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/openldap",
                         input_file => "default.slapd.conf.tt", output => "/default/slapd", data => $data3);
    
    
    
   
    $self->addInitScripts(etc_mountpoint => $args{mount_point}, 
                                econtext => $args{econtext}, 
                                scriptname => 'slapd', 
                                startvalue => '18', 
                                stopvalue => '02'); 
                                


  print Dumper $data1;
  print Dumper $data2;	
}

sub removeNode {}

# Reload process
sub reload {
    my $self = shift;
    my %args = @_;   
    General::checkParams(args => \%args, required => ['econtext']);
    my $command = "/etc.init.d/slapd restart";
    my $result = $args{econtext}->execute(command => $command);
    return undef;
}
1;

