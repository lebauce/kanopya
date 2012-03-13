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

package EEntity::EContainerAccess::ELocalContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Operation;

my $log = get_logger("executor");
use Data::Dumper;

sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'container' ]);

    $args{data} = { container => $args{container} };

    bless $args{data}, $class;

    my $self = $class->SUPER::new(%args);

    bless $self, $class;
    return $self;
}

sub getContainer {
    my $self = shift;

    return $self->{container}->_getEntity;
}

sub getAttr {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'name' ]);

    return $self->{$args{name}};
}

=head2 mount

    desc: Generic mount method. Connect to the container_access,
          and mount the corresponding device on givven mountpoint.

=cut

sub mount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    # Connecting to the container access.
    my $device = $self->connect(econtext => $args{econtext});

    my $mkdir_cmd = "mkdir -p $args{mountpoint}";
    $args{econtext}->execute(command => $mkdir_cmd);

    $log->info("Device found (<$device>), mounting on <$args{mountpoint}>.");

    my $command = "kpartx -a $device";
    $args{econtext}->execute(command => $command);

    # Check if the device is partitioned
    $command = "kpartx -l $device";
    my $result = $args{econtext}->execute(command => $command);
    if($result->{stdout}) {
        # The device is partitioned, mount the one (...)
        $device = $result->{stdout};

        # Cut the stdout after first ocurence of ' : ' to get the
        # device within /dev/mapper directory.
        $device =~ s/ :.*$//g;
        $device = '/dev/mapper/' . $device;
        chomp($device);
    }

    my $mount_cmd = "mount -o loop $device $args{mountpoint}";
    my $cmd_res   = $args{econtext}->execute(command => $mount_cmd);
    if($cmd_res->{'stderr'}){
        throw Kanopya::Exception::Execution(
                  error => "Unable to mount $device on $args{mountpoint}: " .
                           $cmd_res->{'stderr'}
              );
    }

    $log->info("Device <$device> mounted on <$args{mountpoint}>.");
}

=head2 connect

=cut

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->_getEntity->{container}->_getEntity->getAttr(name => 'container_device');

    $log->info("Return file path (<$device>).");
    return $device;
}

=head2 disconnect

=cut

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);
}

1;
