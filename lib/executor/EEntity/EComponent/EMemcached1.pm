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
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my ($self, %args) = @_;

    my $conf = $self->_getEntity()->getConf();
    my $cluster = $self->_getEntity->getServiceProvider;

    # Generation of memcached.conf
    my $data = { connection_port => $conf->{memcached1_port},
                 listening_address => $args{host}->getAdminIp };

    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/memcached.conf',
        template_dir  => '/templates/components/memcached',
        template_file => 'memcached.conf.tt',
        data          => $data 
    );
    
     $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc'
    );
    
}

sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['cluster','mount_point', 'host']);

    my $masternodeip = $args{cluster}->getMasterNodeIp();
    
    # Memcached run only on master node
    if(not defined $masternodeip) {
        # no masternode defined, this host becomes the masternode
            
        $self->configureNode(%args);
        
        $self->addInitScripts(    
            mountpoint => $args{mount_point},
            scriptname => 'memcached', 
        );
    }
}


1;
