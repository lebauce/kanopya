#    Copyright © 2012 Hedera Technology SAS
#
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

package EEntity::EComponent::ELinux::ESuse;
use base 'EEntity::EComponent::ELinux';

use strict;
use warnings;
use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub _writeNetConf {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host', 'mount_point', 'interfaces', 'econtext' ]);

    for my $interface (@{$args{interfaces}}) {
        my $file = $self->generateNodeFile(
            cluster       => $args{cluster},
            host          => $args{host},
            file          => '/etc/sysconfig/network/ifcfg-' . $interface->interface_name,
            template_dir  => '/templates/components/suse',
            template_file => 'ifcfg.tt',
            data          => { interface => $interface }
        );

        $args{econtext}->send(
            src  => $file,
            dest => $args{mount_point} . '/etc/sysconfig/network/ifcfg-' . $interface->interface_name
        );
    }
}

sub service {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'services', 'mount_point' ]);

    for my $service (@{$args{services}}) {
        if (defined $args{command}) {
            system("chroot $args{mount_point} service " . $service . " " . $args{command});
        }
        if (defined $args{state}) {
            system("chroot $args{mount_point} chkconfig " . $service . " " . $args{state});
        }
    }
}

1;

