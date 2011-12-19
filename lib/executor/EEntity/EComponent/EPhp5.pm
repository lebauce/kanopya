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
package EEntity::EComponent::EPhp5;

use strict;
use Template;
use String::Random;
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

    # Generation of php.ini
    my $data = { 
                session_handler => $conf->{php5_session_handler},
                session_path => $conf->{php5_session_path},
                };
    if ( $data->{session_handler} eq "memcache" ) { # This handler needs specific configuration (depending on master node)
        my $masternodeip =     $args{cluster}->getMasterNodeIp() ||
                            $args{host}->getInternalIP()->{ipv4_internal_address}; # current node is the master node
        my $port = '11211'; # default port of memcached TODO: retrieve memcached port using component
        $data->{session_path} = "tcp://$masternodeip:$port";
    }
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/php5",
                         input_file => "php.ini.tt", output => "/php5/apache2/php.ini", data => $data);
}

sub addNode {
    my $self = shift;
    my %args = @_;
        
    $self->configureNode(%args);
}


1;
