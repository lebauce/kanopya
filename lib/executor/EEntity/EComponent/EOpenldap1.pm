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
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use General;

my $log = get_logger("executor");
my $errmsg;


sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['host', 'mount_point']);

    my $cluster = $self->_getEntity->getServiceProvider;
    my $data = $self->_getEntity()->getConf();
    my $data1={};
   
    foreach my $key ('openldap1_suffix','openldap1_directory','openldap1_rootdn','openldap1_rootpw'){
            $data1->{$key}=$data->{$key};    
    } 
     
     my $data2 ->{openldap1_suffix} = $data->{openldap1_suffix};   
     my $data3->{openldap1_port} = $data->{openldap1_port};
    
    
    # generation of /etc/ldap/slapd.conf
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/ldap/slapd.conf',
        template_dir  => '/templates/components/openldap',
        template_file => 'slapd.conf.tt',
        data          => $data1
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/ldap'
    );
                         
    # generation of /etc/ldap/ldap.conf
    $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/ldap/ldap.conf',
        template_dir  => '/templates/components/openldap',
        template_file => 'ldap.conf.tt',
        data          => $data2
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/ldap'
    );

    # generation of /etc/default/slapd
    $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/default/slapd',
        template_dir  => '/templates/components/openldap',
        template_file => 'default.slapd.conf.tt',
        data          => $data3
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/default'
    );

    $self->addInitScripts(
        mountpoint => $args{mount_point}, 
        scriptname => 'slapd'
    );
                                
}

sub removeNode {}

# Reload process
sub reload {
    my $self = shift;
    my %args = @_;   

    my $command = "/etc.init.d/slapd restart";
    my $result = $self->getEContext->execute(command => $command);
    return undef;
}
1;

