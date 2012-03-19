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

package EEntity::EContainer;
use base "EEntity";

use strict;
use warnings;

use General;
use EFactory;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

our $VERSION = '1.00';


=head2 copy

=cut

sub copy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'dest', 'econtext' ]);

    my $source_size = $self->_getEntity->getAttr(name => 'container_size');
    my $dest_size   = $args{dest}->_getEntity->getAttr(name => 'container_size');

    # Check if the destination container is not to small.
    if ($dest_size < $source_size) {
        throw Kanopya::Exception::Execution(
                  error => "Source container <$source_size> is larger than the dest container <$dest_size>."
              );
    }

    # Get a container access for this container via default method.
    my $source_access = $self->createDefaultExport(econtext  => $args{econtext},
                                                   erollback => $args{erollback});
    my $dest_access = $args{dest}->createDefaultExport(econtext  => $args{econtext},
                                                       erollback => $args{erollback});

    # Copy contents with container accesses specific protocols
    $source_access->copy(dest      => $dest_access,
                         econtext  => $args{econtext},
                         erollback => $args{erollback});

    # Check if the destination container is higher thant the source one,
    # resize it to maximum.
    if ($dest_size > $source_size) {
        $dest_access->resize();
    }

    # Remove temporary default exports
    $self->removeDefaultExport(container_access => $source_access,
                               econtext         => $args{econtext},
                               erollback        => $args{erollback});

    $args{dest}->removeDefaultExport(container_access => $dest_access,
                                     econtext         => $args{econtext},
                                     erollback        => $args{erollback});
}

=head2 createDefaultExport

=cut

sub createDefaultExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $storage_provider = $self->_getEntity->getServiceProvider;
    my $export_manager   = EFactory::newEEntity(
                               data => $self->getDefaultExportManager()
                           );

    $export_manager->{econtext} = EFactory::newEContext(
                                      ip_source      => $args{econtext}->getLocalIp,
                                      ip_destination => $storage_provider->getMasterNodeIp,
                                  );

    # Temporary export the containers to copy contents
    my $container_access = EFactory::newEEntity(data =>
                               $export_manager->createExport(
                                   container   => $self->_getEntity,
                                   export_name => $self->_getEntity->getAttr(name => 'container_name'),
                                   econtext    => $export_manager->{econtext},
                                   erollback   => $args{erollback}
                               )
                           );

    return $container_access;
}

=head2 removeDefaultExport

=cut

sub removeDefaultExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container_access', 'econtext' ]);

    my $storage_provider = $self->_getEntity->getServiceProvider;
    my $export_manager   = EFactory::newEEntity(
                               data => $self->getDefaultExportManager()
                           );

    $export_manager->{econtext} = EFactory::newEContext(
                                      ip_source      => $args{econtext}->getLocalIp,
                                      ip_destination => $storage_provider->getMasterNodeIp,
                                  );

    $export_manager->removeExport(container_access => $args{container_access}->_getEntity,
                                  econtext         => $export_manager->{econtext},
                                  erollback        => $args{erollback});

}

sub getDefaultExportManager {
    my $self = shift;
    my %args = @_;

    return $self->_getEntity->getServiceProvider->getDefaultManager(
               category => 'ExportManager'
           );
}

sub mount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    my $device = $self->_getEntity->getAttr(name => 'container_device');

    my $mkdir_cmd = "mkdir -p $args{mountpoint}; chmod 777 $args{mountpoint}";
    $args{econtext}->execute(command => $mkdir_cmd);

    # Check if nothing is mounted on directory
    my $command = "mount | grep $args{mountpoint}";
    my $result = $args{econtext}->execute(command => $command);
    if($result->{stdout}) {
        $errmsg = "$args{mountpoint} already used as mount point by \n($result->{stdout})";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    $log->info("Mounting <$device> on <$args{mountpoint}>.");

    $command = "kpartx -a $device";
    $result = $args{econtext}->execute(command => $command);

    # Check if gte device is partitioned
    $command = "kpartx -l $device";
    $result = $args{econtext}->execute(command => $command);
    if($result->{stdout}) {
        # The device is partitioned, mount the one (...)
        $device = $result->{stdout};

        # Cut the stdout after first ocurence of ' : ' to get the
        # device within /dev/mapper directory.
        $device =~ s/ :.*$//g;
        $device = '/dev/mapper/' . $device;
        chomp($device);
    }

    $log->info("mount $device $args{mountpoint}");

    my $mount_cmd = "mount $device $args{mountpoint}";
    $result = $args{econtext}->execute(command => $mount_cmd);
    if($result->{stderr}) {
        $errmsg = "Unable to mount $device on $args{mountpoint}\n($result->{stderr})";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    # TODO: insert an eroolback with umount method.

    $log->info("Device <$device> mounted on <$args{mountpoint}>.");
}

sub umount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    $log->info("Unmonting (<$args{mountpoint}>)");

    my $command = "kpartx -d " . $self->_getEntity->getAttr(name => 'container_device');;
    $args{econtext}->execute(command => $command);

    my $umount_cmd = "umount $args{mountpoint}";
    my $result = $args{econtext}->execute(command => $umount_cmd);
    if($result->{stderr}) {
        $errmsg = "Unable to unmount $args{mountpoint}\n($result->{stderr})";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    my $mkdir_cmd = "rm -R $args{mountpoint}";
    $args{econtext}->execute(command => $mkdir_cmd);

    # TODO: insert an eroolback with mount method ?
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
