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

use TryCatch;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'mount_point', 'host' ]);

    # Memcached run only on master node
    try {
        $self->getMasterNode;
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        # no masternode defined, this host becomes the masternode

        # Generation of memcached.conf
        my $data = { connection_port => $self->getConf()->{memcached1_port},
                     listening_address => $args{host}->adminIp };

        $self->generateNodeFile(
            host          => $args{host},
            file          => '/etc/memcached.conf',
            template_dir  => 'components/memcached',
            template_file => 'memcached.conf.tt',
            data          => $data,
            mount_point   => $args{mount_point}
        );

        $self->addInitScripts(mountpoint => $args{mount_point},
                              scriptname => 'memcached');
    }
    catch ($err) { $err->rethrow() }
}

1;
