# ESystemimage.pm - Abstract class of ESystemimages object

#    Copyright © 2010-2012 Hedera Technology SAS
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
                         required => [ "edisk_manager", "esrc_container",
                                       "erollback", "econtext" ]);

    $log->info('Device creation for new systemimage');

    my $edisk_manager = $args{edisk_manager};
    delete $args{edisk_manager};

    my $esource_container = $args{esrc_container};
    delete $args{esrc_container};

    my $erollback = $args{erollback};
    delete $args{erollback};

    my $econtext = $args{econtext};
    delete $args{econtext};

    my $systemimage_size;
    if (defined $args{systemimage_size}) {
        $systemimage_size = $args{systemimage_size};
        delete $args{systemimage_size};
    }
    else {
        $systemimage_size = $esource_container->_getEntity->getAttr(name => 'container_size');
    }

    # Creation of the device based on distribution device
    my $container = $edisk_manager->createDisk(
                        name       => $self->_getEntity->getAttr(name => 'systemimage_name'),
                        size       => $systemimage_size . 'B',
                        filesystem => $esource_container->_getEntity->getAttr(name => 'container_filesystem'),
                        econtext   => $edisk_manager->{econtext},
                        erollback  => $erollback,
                        %args
                    );

    # Copy of distribution data to systemimage devices
    $log->info('Fill the container with source data for new systemimage');

    # Get the corresponding EContainer
    my $edest_container = EFactory::newEEntity(data => $container);

    $esource_container->copy(dest      => $edest_container,
                             econtext  => $econtext,
                             erollback => $erollback);

    $self->_getEntity()->setAttr(name  => "container_id",
                                 value => $container->getAttr(name => 'container_id'));

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
    my $container = $self->_getEntity()->getDevice();

    my $container_access = $args{eexport_manager}->createExport(
                               container   => $container,
                               export_name => $container->getAttr(name => 'container_name'),
                               econtext    => $args{eexport_manager}->{econtext},
                               erollback   => $args{erollback}
                            );

    # Get the corresponding EContainerAccess
    my $econtainer_access = EFactory::newEEntity(data => $container_access);

    my $mount_point = "/mnt/" . $container->getAttr(name => 'container_name');
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

    my $container = $self->_getEntity()->getDevice();

    # Provide root rsa pub key to provide ssh key authentication
    $self->generateAuthorizedKeys(eexport_manager => $args{eexport_manager},
                                  econtext        => $args{econtext},
                                  erollback       => $args{erollback});

    # Get acontainer export information
    my $si_access_mode = $self->_getEntity()->getAttr(name => 'systemimage_dedicated') ? 'wb' : 'ro';
    my $export_name    = 'root_' . $self->_getEntity()->getAttr(name => 'systemimage_name');

    $args{eexport_manager}->createExport(container   => $container,
                                         export_name => $export_name,
                                         typeio      => "fileio",
                                         iomode      => $si_access_mode,
                                         econtext    => $args{eexport_manager}->{econtext},
                                         erollback   => $args{erollback});

    # Set system image active in db
    $self->_getEntity()->setAttr(name => 'active', value => 1);
    $self->_getEntity()->save();

    $log->info("System image <" . $self->_getEntity()->getAttr(name => "systemimage_name") .
               "> is now active");
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
