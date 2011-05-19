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
package EEntity::EComponent::EWebserver::EApache2;

use strict;
use Template;
use String::Random;
use Data::Dumper;
use base "EEntity::EComponent::EWebserver";
use Log::Log4perl "get_logger";
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

sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext','motherboard','mount_point']);

    my $apache2_conf = $self->_getEntity()->getGeneralConf();    
    my $data = {};
    
    # generation of /etc/apache2/apache2.conf 
    $data->{serverroot} = $apache2_conf->{'apache2_serverroot'};
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/apache2",
                         input_file => "apache2.conf.tt", output => "/apache2/apache2.conf", data => $data);

    # generation of /etc/apache2/ports.conf
    $data = {};
    $data->{ports} = $apache2_conf->{apache2_ports};
    $data->{sslports} = $apache2_conf->{apache2_sslports};
    
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/apache2",
                         input_file => "ports.conf.tt", output => '/apache2/ports.conf', data => $data);
        
    # generation of /etc/apache2/sites-available/default
    $data = {};
    $data->{virtualhosts} = $self->_getEntity()->getVirtualhostConf();
    $data->{ports} =  $apache2_conf->{apache2_ports};
    $data->{sslports} = $apache2_conf->{apache2_sslports};
    
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/apache2",
                         input_file => "virtualhost.tt", output => '/apache2/sites-available/default', data => $data);

    # generation of /etc/apache2/mods-available/status.conf
    $data = {};
    $data->{monitor_server_ip} = 'all';
    
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/apache2",
                         input_file => "status.conf.tt", output => '/apache2/mods-enabled/status.conf', data => $data);
    
    
    
    $self->addInitScripts(    etc_mountpoint => $args{mount_point}, 
                                econtext => $args{econtext}, 
                                scriptname => 'apache2', 
                                startvalue => '91', 
                                stopvalue => '09');
    
}

sub removeNode {}

sub reload {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);

    my $command = "invoke-rc.d apache2 restart";
    my $result = $args{econtext}->execute(command => $command);
    return undef;
}

1;
