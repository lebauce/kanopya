# ESystemimage.pm - Abstract class of ESystemimages object

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
# Created 14 july 2010

=head1 NAME

ESystemimage - execution class of systemimage entities

=head1 SYNOPSIS



=head1 DESCRIPTION

ESystemimage is the execution class of systemimage entities

=head1 METHODS

=cut
package EEntity::ESystemimage;
use base "EEntity";

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

sub create {
    my $self = shift;
    my %args = @_;
    my $cmd_res;

    General::checkParams(args     => \%args,
                         required => [ "edisk_manager", "eexport_manager",
                                       "devs", "erollback", "econtext" ]);

    for my $disk_type ("etc", "root") {
        my $disk_name = $disk_type . '_' . $self->_getEntity()->getAttr(name => 'systemimage_name');

        # Creation of the device based on distribution device
        $log->info($disk_type . ' device creation for new systemimage');

        my $source_name = $args{devs}->{$disk_type}->getAttr(name => 'container_name');
        my $source_size = $args{devs}->{$disk_type}->getAttr(name => 'container_size');
        my $source_filesystem = $args{devs}->{$disk_type}->getAttr(name => 'container_filesystem');

        my $container = $args{edisk_manager}->createDisk(
                            name       => $disk_name,
                            size       => $source_size . "B",
                            filesystem => $source_filesystem,
                            econtext   => $args{edisk_manager}->{econtext},
                            erollback  => $args{erollback}
                        );

        # Copy of distribution data to systemimage devices
        $log->info('Fill ' . $disk_type . ' device with distribution data for new systemimage');

		# Temporary export the containers to copy contents
        my $source_access = $args{eexport_manager}->createExport(
                                container   => $args{devs}->{$disk_type},
                                export_name => $source_name,
                                econtext    => $args{eexport_manager}->{econtext},
                                erollback   => $args{erollback}
                            );
        my $dest_access = $args{eexport_manager}->createExport(
                              container   => $container,
                              export_name => $container->getAttr(name => 'container_name'),
                              econtext    => $args{eexport_manager}->{econtext},
                              erollback   => $args{erollback}
                          );

		# Mount the containers on the executor.
        my $source_mountpoint = "/mnt/" . $source_name;
        my $dest_mountpoint   = "/mnt/" . $container->getAttr(name => 'container_name');

        # Get the corresponding EContainerAccess
        my $esource_access = EFactory::newEEntity(data => $source_access);
        my $edest_access   = EFactory::newEEntity(data => $dest_access);

        $log->info('Mounting source container <' . $source_mountpoint . '>');
		$esource_access->mount(mountpoint => $source_mountpoint, econtext => $args{econtext});

        $log->info('Mounting destination container <' . $dest_mountpoint . '>');
		$edest_access->mount(mountpoint => $dest_mountpoint, econtext => $args{econtext});

        # Copy the filesystem.
        my $copy_fs_cmd = "cp -R --preserve=all $source_mountpoint/. $dest_mountpoint/";

        $log->debug($copy_fs_cmd);
        $cmd_res = $args{econtext}->execute(command => $copy_fs_cmd);

        if($cmd_res->{'stderr'}){
            $errmsg = "Error with copy of $source_mountpoint to $dest_mountpoint: " .
                      $cmd_res->{'stderr'};
            $log->error($errmsg);
            Kanopya::Exception::Execution(error => $errmsg);
        }

        $self->_getEntity()->setAttr(name  => $disk_type . "_container_id",
                                     value => $container->getAttr(name => 'container_id'));

        # Unmount the containers, and remove the temporary exports.
        $esource_access->umount(mountpoint => $source_mountpoint, econtext => $args{econtext});
        $edest_access->umount(mountpoint => $dest_mountpoint, econtext => $args{econtext});

        $args{eexport_manager}->removeExport(container_access => $source_access,
                                             econtext         => $args{eexport_manager}->{econtext},
                                             erollback        => $args{erollback});
        $args{eexport_manager}->removeExport(container_access => $dest_access,
                                             econtext         => $args{eexport_manager}->{econtext},
                                             erollback        => $args{erollback});
    }

    $self->_getEntity()->setAttr(name => "active", value => 0);
    $self->_getEntity()->save();

    $log->info('System image <'. $self->_getEntity()->getAttr(name => 'systemimage_name') . '> is added');

    return $self->_getEntity()->getAttr(name => "systemimage_id");
}

sub generateAuthorizedKeys{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "eexport_manager", "econtext" ]);

    # mount the root systemimage device
    my $si_devices = $self->_getEntity()->getDevices();

    my $container_access = $args{eexport_manager}->createExport(
                               container   => $si_devices->{root},
                               export_name => $si_devices->{root}->getAttr(name => 'container_name'),
                               econtext    => $args{eexport_manager}->{econtext},
                               erollback   => $args{erollback}
                            );

    # Get the corresponding EContainerAccess
    my $econtainer_access = EFactory::newEEntity(data => $container_access);

    my $mount_point = "/mnt/" . $si_devices->{root}->getAttr(name => 'container_name');
    $econtainer_access->mount(mountpoint => $mount_point, econtext => $args{econtext});

    my $rsapubkey_cmd = "cat /root/.ssh/kanopya_rsa.pub > $mount_point/root/.ssh/authorized_keys";
    $args{econtext}->execute(command => $rsapubkey_cmd);

    my $sync_cmd = "sync";
    $args{econtext}->execute(command => $sync_cmd);

    $econtainer_access->umount(mountpoint => $mount_point, econtext => $args{econtext});

    $args{eexport_manager}->removeExport(
        container_access => $container_access,
        econtext         => $args{eexport_manager}->{econtext},
        erollback        => $args{erollback}
    );
}

sub activate {
    my $self = shift;

    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "econtext", "eexport_manager", "erollback" ]);

    my $sysimg_dev = $self->_getEntity()->getDevices();

    # Provide root rsa pub key to provide ssh key authentication
    $self->generateAuthorizedKeys(eexport_manager => $args{eexport_manager},
                                  econtext        => $args{econtext},
                                  erollback       => $args{erollback});

    # Get etc acontainer export information
    my $si_access_mode = $self->_getEntity()->getAttr(name => 'systemimage_dedicated') ? 'wb' : 'ro';
    my $export_name    = 'root_'.$self->_getEntity()->getAttr(name => 'systemimage_name');

    $args{eexport_manager}->createExport(container   => $sysimg_dev->{root},
                                         export_name => $export_name,
                                         typeio      => "fileio",
                                         iomode      => $si_access_mode,
                                         econtext    => $args{eexport_manager}->{econtext},
                                         erollback   => $args{erollback});

    # Set system image active in db
    $self->_getEntity()->setAttr(name => 'active', value => 1);
    $self->_getEntity()->save();

    $log->info("System image <" . $self->_getEntity()->getAttr(name=>"systemimage_name") . "> is now active");
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
