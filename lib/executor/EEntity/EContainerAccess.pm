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
    my ($cmd_res);

    General::checkParams(args => \%args, required => [ 'dest', 'econtext' ]);

    my $source_access = $self;
    my $dest_access   = $args{dest};

    $log->info('Try to connect to the source container...');
    my $source_device = $source_access->connect(econtext => $args{econtext});
    $log->info('Try to connect to the destination container...');
    my $dest_device = $dest_access->connect(econtext => $args{econtext});

    # If devices exists, copy contents with 'dd'
    if (defined $source_device and defined $dest_device) {
        # Copy the device
        my $dd_cmd = "dd if=$source_device of=$dest_device bs=1M";

        $log->debug($dd_cmd);
        $cmd_res = $args{econtext}->execute(command => $dd_cmd);

        if($cmd_res->{'stderr'}){
            $errmsg = "Error with copy of $source_device to $dest_device: " .
                      $cmd_res->{'stderr'};
            $log->error($errmsg);

            # 'dd' command weems to write informations messages on stderr.
            # throw Kanopya::Exception::Execution(error => $errmsg);
        }

        # Disconnect the containers.
        $source_access->disconnect(econtext => $args{econtext});
        $dest_access->disconnect(econtext => $args{econtext});
    }
    # One or both container access do not support device level (e.g. Nfs)
    else {
        # Mount the containers on the executor.
        my $source_name = $source_access->_getEntity->getContainer->getAttr(name => 'container_name');
        my $source_mountpoint = "/mnt/" . $source_name;

        my $dest_name = $dest_access->_getEntity->getContainer->getAttr(name => 'container_name');
        my $dest_mountpoint = "/mnt/" . $dest_name;

        $log->info('Mounting source container <' . $source_mountpoint . '>');
        $source_access->mount(mountpoint => $source_mountpoint, econtext => $args{econtext});

        $log->info('Mounting destination container <' . $dest_mountpoint . '>');
        $dest_access->mount(mountpoint => $dest_mountpoint, econtext => $args{econtext});

        # Copy the filesystem.
        my $copy_fs_cmd = "cp -R --preserve=all $source_mountpoint/. $dest_mountpoint/";

        $log->debug($copy_fs_cmd);
        $cmd_res = $args{econtext}->execute(command => $copy_fs_cmd);

        if($cmd_res->{'stderr'}){
            $errmsg = "Error with copy of $source_mountpoint to $dest_mountpoint: " .
                      $cmd_res->{'stderr'};
            $log->error($errmsg);
            throw Kanopya::Exception::Execution(error => $errmsg);
        }

        # Unmount the containers.
        $source_access->umount(mountpoint => $source_mountpoint, econtext => $args{econtext});
        $dest_access->umount(mountpoint => $dest_mountpoint, econtext => $args{econtext});
    }
}

=head2 resize

=cut

sub resize {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'size', 'econtext' ]);
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

    my $mount_cmd = "mount $device $args{mountpoint}";
    my $cmd_res   = $args{econtext}->execute(command => $mount_cmd);
    if($cmd_res->{'stderr'}){
        $errmsg = "Unable to mount $device on $args{mountpoint}: " .
                  $cmd_res->{'stderr'};
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }

    # TODO: insert an eroolback with umount method.

    $log->info("Device <$device> mounted on <$args{mountpoint}>.");
}

=head2 umount

    desc: Generic umount method. Umount, disconnect from the container access,
          and remove the mountpoint.

=cut

sub umount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    $log->info("Unmonting (<$args{mountpoint}>)");

    my $umount_cmd = "umount $args{mountpoint}";
    my $cmd_res    = $args{econtext}->execute(command => $umount_cmd);
    if($cmd_res->{'stderr'}){
        $errmsg = "Unable to umount $args{mountpoint}: " .
                  $cmd_res->{'stderr'};
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }

    # Disconnecting from container access.
    $self->disconnect(econtext => $args{econtext});

    my $mkdir_cmd = "rm -R $args{mountpoint}";
    $args{econtext}->execute(command => $mkdir_cmd);

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

1;

__END__

=head1 AUTHOR

Copyright (c) 2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
