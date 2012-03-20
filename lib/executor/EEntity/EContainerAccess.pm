# Copyright 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EContainerAccess;
use base "EEntity";

use strict;
use warnings;

use General;
use EFactory;

use Data::Dumper;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

our $VERSION = '1.00';

=head2 copy

    desc: Copy content of a source container access to dest.
          Try to copy at the device level, mount the both container and copy
          files instead.

=cut

sub copy {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'dest', 'econtext' ]);

    my $source_access = $self;
    my $dest_access   = $args{dest};

    $log->info('Try to connect to the source container...');
    my $source_device = $source_access->tryConnect(econtext => $args{econtext});
    $log->info('Try to connect to the destination container...');
    my $dest_device = $dest_access->tryConnect(econtext => $args{econtext});

    # If devices exists, copy contents with 'dd'
    if (defined $source_device and defined $dest_device) {
        # Copy the device
        $command = "dd conv=notrunc,fdatasync if=$source_device of=$dest_device bs=1M";
        $result  = $args{econtext}->execute(command => $command);

        if ($result->{stderr} and ($result->{exitcode} != 0)) {
            $errmsg = "Error with copy of $source_device to $dest_device: " .
                      $result->{stderr};
            throw Kanopya::Exception::Execution(error => $errmsg);
        }

        my $source_size = $self->_getEntity->getContainer->getAttr(name => 'container_size');
        my $dest_size   = $args{dest}->_getEntity->getContainer->getAttr(name => 'container_size');

        # Check if the destination container is higher thant the source one,
        # resize it to maximum.
        if ($dest_size > $source_size) {
            my $part_start = $args{dest}->getPartitionStart(econtext => $args{econtext});
            if ($part_start > 0) {
                $command = "parted -s $dest_device rm 1";
                $result  = $args{econtext}->execute(command => $command);

                $command = "parted -s -- $dest_device mkpart primary " . $part_start . "B -1s";
                $result  = $args{econtext}->execute(command => $command);
            }

            my $part_device = $self->tryConnectPartition(econtext => $args{econtext});

            # Finally resize2fs the partition
            $command = "e2fsck -y -f $part_device";
            $args{econtext}->execute(command => $command);
            $command = "resize2fs -F $part_device";
            $args{econtext}->execute(command => $command);

            $self->tryDisconnectPartition(econtext => $args{econtext});
        }

        # Disconnect the containers.
        $source_access->tryDisconnect(econtext => $args{econtext});
        $dest_access->tryDisconnect(econtext => $args{econtext});
    }
    # One or both container access do not support device level (e.g. Nfs)
    else {
        # Mount the containers on the executor.
        my $source_mountpoint = $source_access->_getEntity->getContainer->getMountPoint;
        my $dest_mountpoint   = $dest_access->_getEntity->getContainer->getMountPoint;

        $log->info('Mounting source container <' . $source_mountpoint . '>');
        $source_access->mount(mountpoint => $source_mountpoint, econtext => $args{econtext});

        $log->info('Mounting destination container <' . $dest_mountpoint . '>');
        $dest_access->mount(mountpoint => $dest_mountpoint, econtext => $args{econtext});

        # Copy the filesystem.
        $command = "cp -R --preserve=all $source_mountpoint/. $dest_mountpoint/";
        $result  = $args{econtext}->execute(command => $command);

        if ($result->{stderr}) {
            $errmsg = "Error with copy of $source_mountpoint to $dest_mountpoint: " .
                      $result->{stderr};
            $log->error($errmsg);
            throw Kanopya::Exception::Execution(error => $errmsg);
        }

        # Unmount the containers.
        $source_access->umount(mountpoint => $source_mountpoint, econtext => $args{econtext});
        $dest_access->umount(mountpoint => $dest_mountpoint, econtext => $args{econtext});
    }
}

=head2 mount

    desc: Generic mount method. Connect to the container_access,
          and mount the corresponding device on givven mountpoint.

=cut

sub mount {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    # Connecting to the container access.
    my $device = $self->tryConnectPartition(econtext => $args{econtext});

    $command = "mkdir -p $args{mountpoint}";
    $args{econtext}->execute(command => $command);

    $log->info("Mounting <$device> on <$args{mountpoint}>.");

    $command = "mount $device $args{mountpoint}";
    $result  = $args{econtext}->execute(command => $command);
    if($result->{stderr}){
        throw Kanopya::Exception::Execution(
                  error => "Unable to mount $device on $args{mountpoint}: " .
                           $result->{stderr}
              );
    }

    $log->info("Device <$device> mounted on <$args{mountpoint}>.");
}

=head2 umount

    desc: Generic umount method. Umount, disconnect from the container access,
          and remove the mountpoint.

=cut

sub umount {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    $log->info("Unmonting (<$args{mountpoint}>)");

    $command = "umount $args{mountpoint}";
    my $retry = 5;
    while ($retry > 0) {
        $result = $args{econtext}->execute(command => $command);
        if ($result->{exitcode} != 0) {
            $log->info("Unable to umount <$args{mountpoint}>, retrying in 1s...");
            $retry--;
            sleep 1;
            next;
        }
        last;
    }
    if (!$retry){
        throw Kanopya::Exception::Execution(
                  error => "Unable to umount $args{mountpoint}: " . $result->{stderr}
              );
    }

    # Disconnecting from container access.
    $self->tryDisconnectPartition(econtext => $args{econtext});
    $self->tryDisconnect(econtext => $args{econtext});

    $command = "rm -R $args{mountpoint}";
    $args{econtext}->execute(command => $command);

    # TODO: insert an eroolback with mount method ?
}

=head2 connect

    desc: Abstract method.

=cut

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    throw Kanopya::Exception::NotImplemented();
}

=head2 disconnect

    desc: Abstract method.

=cut

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    throw Kanopya::Exception::NotImplemented();
}

sub getPartitionStart {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->_getEntity->getAttr(name => 'device_connected');
    if (! $device) {
        my $msg = "A container access must be connected before getting partition start.";
        throw Kanopya::Exception::Execution(error => $msg);
    }

    $command = "parted -m -s $device u B print";
    $result = $args{econtext}->execute(command => $command);

    # Parse the parted output to get partition start.
    my $part_start = $result->{stdout};
    $part_start =~ s/.*\n.*\n1://g;
    $part_start =~ s/B.*$//g;
    chomp($part_start);

    return $part_start;
}

sub connectPartition {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->tryConnect(econtext => $args{econtext});
    my $part_start = $self->getPartitionStart(econtext => $args{econtext});

    if ($part_start > 0) {
        # Get a free loop device
        $command = "losetup -f";
        $result  = $args{econtext}->execute(command => $command);
        if ($result->{exitcode} != 0) {
            throw Kanopya::Exception::Execution(error => $result->{stderr});
        }
        chomp($result->{stdout});
        my $loop = $result->{stdout};

        $command = "losetup $loop $device -o $part_start";
        $result  = $args{econtext}->execute(command => $command);
        if ($result->{exitcode} != 0) {
            throw Kanopya::Exception::Execution(error => $result->{stderr});
        }

        $self->_getEntity->setAttr(name  => 'partition_connected',
                                   value => $loop);
        return $loop;
    }
    else {
        return $device;
    }
}

sub disconnectPartition {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    my $partition = $self->_getEntity->getAttr(name => 'partition_connected');

    $command = "losetup -d $partition";
    $result = $args{econtext}->execute(command => $command);
    if ($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stderr});
    }

    $self->_getEntity->setAttr(name  => 'partition_connected',
                               value => '');
}

sub tryConnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->_getEntity->getAttr(name => 'device_connected');
    if ($device) {
        $log->debug("Device already connected <$device>.");
        return $device;
    }
    return $self->connect(%args);
}

sub tryDisconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->_getEntity->getAttr(name => 'device_connected');
    if (! $device) {
        $log->debug('Device seems to be not connected, doing nothing.');
        return;
    }
    $self->disconnect(%args);
}

sub tryConnectPartition {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $partition = $self->_getEntity->getAttr(name => 'partition_connected');
    if ($partition) {
        $log->debug("Partition already connected <$partition>.");
        return $partition;
    }
    return $self->connectPartition(%args);
}

sub tryDisconnectPartition {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $partition = $self->_getEntity->getAttr(name => 'partition_connected');
    if (! $partition) {
        $log->debug('Partition seems to be not connected, doing nothing.');
        return;
    }
    $self->disconnectPartition(%args);
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
