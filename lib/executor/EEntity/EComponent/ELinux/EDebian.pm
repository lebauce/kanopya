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

package EEntity::EComponent::ELinux::EDebian;
use base 'EEntity::EComponent::ELinux';

use strict;
use warnings;
use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

# generate configuration files on node
sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['cluster','host','mount_point']);

    $self->SUPER::addNode(%args);

    my $econtext = $self->getExecutorEContext;
    my $grep_result = $econtext->execute(
                         command => "grep \"NETDOWN=no\" $args{mount_point}/etc/default/halt"
                      );

    if (not $grep_result->{stdout}) {
        $econtext->execute(
            command => "echo \"NETDOWN=no\" >> $args{mount_point}/etc/default/halt"
        );
    }

    # adjust some requirements on the image
    my $data = $self->_getEntity()->getConf();
    my $automountnfs = 0;
    for my $mountdef (@{$data->{linuxes_mount}}) {
        my $mountpoint = $mountdef->{linux_mount_point};
        $econtext->execute(command => "mkdir -p $args{mount_point}/$mountpoint");
        
        if ($mountdef->{linux_mount_filesystem} eq 'nfs') {
            $automountnfs = 1;
        }
    }

    if ($automountnfs) {
        my $grep_result = $econtext->execute(
                              command => "grep \"ASYNCMOUNTNFS=no\" $args{mount_point}/etc/default/rcS"
                          );

        if (not $grep_result->{stdout}) {
            $econtext->execute(
                command => "echo \"ASYNCMOUNTNFS=no\" >> $args{mount_point}/etc/default/rcS"
            );
        }
    }

    # Disable network deconfiguration during halt
    unlink "$args{mount_point}/etc/rc0.d/S35networking";
}

sub _writeNetConf {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host', 'mount_point', 'ifaces' ]);

    #we ignore the slave interfaces in the case of bonding
    my @ifaces = @{ $args{ifaces} };

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/network/interfaces',
        template_dir  => '/templates/internal',
        template_file => 'network_interfaces.tt',
        data          => { interfaces => \@ifaces }
    );

    $args{econtext}->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/network'
    );
}

sub service {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'services', 'mount_point' ]);

    for my $service (@{$args{services}}) {
        if (defined ($args{command})) {
            system("chroot $args{mount_point} invoke-rc.d " . $service . " " . $args{command});
        }
        if (defined ($args{state})) {
            system("chroot $args{mount_point} /sbin/insserv -d $service");
        }
    }
}

1;

