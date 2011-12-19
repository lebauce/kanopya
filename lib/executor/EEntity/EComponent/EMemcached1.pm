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
package EEntity::EComponent::EMemcached1;

use strict;
use Template;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";

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

    my $conf = $self->_getEntity()->getConf();

    # Generation of memcached.conf
    my $data = { 
                connection_port => $conf->{memcached1_port},
                listening_address => $args{host}->getInternalIP()->{ipv4_internal_address},
                };
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/memcached",
                         input_file => "memcached.conf.tt", output => "/memcached.conf", data => $data);

}

sub addNode {
    my $self = shift;
    my %args = @_;

    my $masternodeip = $args{cluster}->getMasterNodeIp();
    
    # Memcached run only on master node
    if(not defined $masternodeip) {
        # no masternode defined, this host becomes the masternode
            
        $self->configureNode(%args);
        
        $self->addInitScripts(    etc_mountpoint => $args{mount_point}, 
                                econtext => $args{econtext}, 
                                scriptname => 'memcached', 
                                startvalue => 20, 
                                stopvalue => 20);
    }

}


1;
