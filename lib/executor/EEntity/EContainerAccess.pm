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

=pod

=begin classdoc

Execution class for ContainerAccess. Provides methods for copy,
connect and mount container accesses. Some container access support connection,
i.e. we can access it as a device on the client host like Iscsi lun, and others
support the mount only like Nfs export.

@since    2012-Feb-29
@instance hash
@self     $self

=end classdoc

=cut

package EEntity::EContainerAccess;
use base "EEntity";

use strict;
use warnings;

use General;
use EEntity;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


=pod

=begin classdoc

Copy contents of the source container access ($self) to destination container access.
Try to copy at the device level by connecting both access as device on the executor,
mount the both container accesses and copy files instead if one the both do not 
support the device level.
After the copy, if the destionation container access is larger than the source one,
resizing the filesystem to fit to the total container length.

@param dest the destination container access
@param econtext the econtext object to execute commands

@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub copy {
    my ($self,%args) = @_;

    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'dest', 'econtext' ]);

    my $source_access = $self;
    my $dest_access   = $args{dest};

    $log->debug('Try to connect to the source container...');
    my $source_device = $source_access->tryConnect(econtext  => $args{econtext},
                                                   erollback => $args{erollback});
    $log->debug('Try to connect to the destination container...');
    my $dest_device = $dest_access->tryConnect(econtext  => $args{econtext},
                                               erollback => $args{erollback});

    # If devices exists, clone and resize the source disk using virt-resize
    if (defined $source_device and defined $dest_device) {
        my $source_size = $source_access->getContainer->getAttr(name => 'container_size');
        my $dest_size   = $dest_access->getContainer->getAttr(name => 'container_size');

        my $srcdev = `readlink -f $source_device`;
        my $dstdev = `readlink -f $dest_device`;
        $srcdev =~ s/^\s+|\s+$//g;
        $dstdev =~ s/^\s+|\s+$//g;

        $command = "virt-resize --expand /dev/sda1 $srcdev $dstdev";
        $result  = $args{econtext}->execute(command => $command);

        if ($result->{stderr} and ($result->{exitcode} != 0)) {
            $errmsg = "Error with copy of $source_device to $dest_device: " .
                      $result->{stderr};
            throw Kanopya::Exception::Execution(error => $errmsg);
        }

        $command = "sync";
        $args{econtext}->execute(command => $command);

        # Disconnect the containers.
        $log->debug('Try to disconnect from the source container...');
        $source_access->tryDisconnect(econtext  => $args{econtext},
                                      erollback => $args{erollback});

        $log->debug('Try to disconnect from the destination container...');
        $dest_access->tryDisconnect(econtext  => $args{econtext},
                                    erollback => $args{erollback});
    }
    # One or both container access do not support device level (e.g. Nfs)
    else {
        # Mount the containers on the executor.
        my $source_mountpoint = $source_access->getMountPoint;
        my $dest_mountpoint   = $dest_access->getMountPoint;

        $log->debug('Mounting source container <' . $source_mountpoint . '>');
        $source_access->mount(mountpoint => $source_mountpoint,
                              econtext   => $args{econtext},
                              erollback  => $args{erollback});

        $log->debug('Mounting destination container <' . $dest_mountpoint . '>');
        $dest_access->mount(mountpoint => $dest_mountpoint,
                            econtext   => $args{econtext},
                            erollback  => $args{erollback});

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
        
        $source_access->umount(mountpoint => $source_mountpoint,
                               econtext   => $args{econtext},
                               erollback  => $args{erollback});
        $dest_access->umount(mountpoint => $dest_mountpoint,
                             econtext   => $args{econtext},
                             erollback  => $args{erollback});
    }
}

=pod

=begin classdoc

Generic mount method. Connect to the container access, and mount the 
corresponding device on the given mountpoint.

@param mountpoint the path to use xhen monting the container access
@param econtext the econtext object to execute commands

@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub mount {
    my ($self,%args) = @_;

    my ($command, $result);

    General::checkParams(args     => \%args,
                         required => [ 'econtext' ],
                         optional => { 'mountpoint' => $self->getMountPoint } );

    # Connecting to the container access.
    my $device = $self->tryConnect(econtext  => $args{econtext},  
                                   erollback => $args{erollback});

    $command = "mkdir -p $args{mountpoint}";
    $args{econtext}->execute(command => $command);

    $log->debug("Mounting <$device> on <$args{mountpoint}>.");

    $command = "DEV=`readlink -f $device`; " .
               "guestmount -a \$DEV -m /dev/sda1 " . $args{mountpoint};
    $result  = $args{econtext}->execute(command => $command);

    if ($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(
                  error => "Unable to mount $device on $args{mountpoint}: " .
                           $result->{stderr}
              );
    }

    $log->debug("File <$device> mounted on <$args{mountpoint}>.");

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('umount'),
            parameters => [ $self, "mountpoint", $args{mountpoint}, "econtext", $args{econtext} ]
        );
    }
    return $args{mountpoint};
}

=pod

=begin classdoc

Generic umount method. Umount, disconnect from the container access, 
and remove the mountpoint.

@param mountpoint the path to use xhen monting the container access
@param econtext the econtext object to execute commands

@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub umount {
    my ($self,%args) = @_;

    my ($command, $result);

    General::checkParams(args     => \%args,
                         required => [ 'econtext' ],
                         optional => { 'mountpoint' => $self->getMountPoint } );

    $log->debug("Unmounting (<$args{mountpoint}>)");

    $command = "sync; echo 3 > /proc/sys/vm/drop_caches";
    $args{econtext}->execute(command => $command);

    # For some reason (a bug in libguestfs ?), some data are not 
    # written to disk when unmounting, so we wait a bit...
    sleep 5;

    my $counter = 5;
    while($counter != 0) {
        $command = "umount $args{mountpoint}";
        $result  = $args{econtext}->execute(command => $command);
        if($result->{exitcode} == 0) {
            last;
        }
        $counter--;
        sleep(1);
    }

    if ($result->{exitcode} != 0 ) {
        throw Kanopya::Exception::Execution(
                  error => "Unable to umount $args{mountpoint}: " .
                           $result->{stderr}
              );
    }

    # Disconnecting from container access.
    $self->tryDisconnect(econtext  => $args{econtext},
                         erollback => $args{erollback});

    $command = "rm -R $args{mountpoint}";
    $args{econtext}->execute(command => $command);

    # TODO: insert an eroolback with mount method ?
}


=pod

=begin classdoc

Abstract method for container access connection.

@param econtext the econtext object to execute commands
@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub connect {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod

=begin classdoc

Abstract method for container access disconnection.

@param econtext the econtext object to execute commands
@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub disconnect {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    throw Kanopya::Exception::NotImplemented();
}

=pod

=begin classdoc

Check if the container is already connected, connect it instead.

@param econtext the econtext object to execute commands

@return the device

=end classdoc

=cut

sub tryConnect {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->getAttr(name => 'device_connected');
    if ($device) {
        $log->debug("Device already connected <$device>.");
        return $device;
    }
    return $self->connect(%args);
}


=pod

=begin classdoc

Disconnect the container if connected, doing nothing instead.

@param econtext the econtext object to execute commands

=end classdoc

=cut

sub tryDisconnect {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->getAttr(name => 'device_connected');
    if (! $device) {
        $log->debug('Device seems to be not connected, doing nothing.');
        return;
    }
    $self->disconnect(%args);
}

1;
