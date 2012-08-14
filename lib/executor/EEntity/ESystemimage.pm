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

use Entity;
use Entity::Gp;
use EFactory;
use EEntity::EContainer::ELocalContainer;

use Log::Log4perl "get_logger";

use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub createFromMasterimage {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "masterimage", "disk_manager",
                                       "manager_params", "erollback" ]);

    my $master_container = EEntity::EContainer::ELocalContainer->new(
                               path => $args{masterimage}->getAttr(name => 'masterimage_file'),
                               size => $args{masterimage}->getAttr(name => 'masterimage_size'),
                               # TODO: get this value from masterimage attrs.
                               filesystem => 'ext3',
                           );

    # Instanciate a fake econtainer for the masterimage raw file.
    $self->create(
        src_container => $master_container,
        disk_manager  => $args{disk_manager},
        erollback     => $args{erollback},
        %{$args{manager_params}}
    );

    my $components = $args{masterimage}->getProvidedComponents();
    foreach my $comp (@$components) {
            $self->_getEntity->installedComponentLinkCreation(
                component_type_id => $comp->{component_type_id}
            );
    }
}

sub create {
    my $self = shift;
    my %args = @_;
    my $cmd_res;

    General::checkParams(args     => \%args,
                         required => [ "disk_manager", "src_container", "erollback" ]);

    General::checkParams(args     => \%args,
                         optional => { 'systemimage_size' => $args{src_container}->getAttr(name => 'container_size') });

    $log->info('Device creation for new systemimage');

    # Creation of the device based on distribution device
    my $container = $args{disk_manager}->createDisk(
                        name       => $self->getAttr(name => 'systemimage_name'),
                        size       => $args{systemimage_size},
                        filesystem => $args{src_container}->getAttr(name => 'container_filesystem'),
                        erollback  => $args{erollback},
                        %args
                    );

    # Copy of distribution data to systemimage devices
    $log->info('Fill the container with source data for new systemimage');

    $args{src_container}->copy(dest      => $container,
                               econtext  => $self->getExecutorEContext,
                               erollback => $args{erollback});

    $self->setAttr(name  => "container_id",
                   value => $container->getAttr(name => 'container_id'));

    $self->setAttr(name => "active", value => 0);
    $self->save();

    $log->info('System image <' . $self->getAttr(name => 'systemimage_name') . '> is added');

    return $self->getAttr(name => "systemimage_id");
}

sub generateAuthorizedKeys {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "export_manager" ]);

    # mount the root systemimage device
    my $container = EFactory::newEEntity(data => $self->getDevice());

    my $container_access = $args{export_manager}->createExport(
                               container   => $container,
                               export_name => $container->getAttr(name => 'container_name'),
                               erollback   => $args{erollback}
                           );

    my $mount_point = $container->getMountPoint;
    $container_access->mount(mountpoint => $mount_point,
                             econtext   => $self->getExecutorEContext,
                             erollback  => $args{erollback});

    my $rsapubkey_cmd = "mkdir -p $mount_point/root/.ssh ; cat /root/.ssh/kanopya_rsa.pub > $mount_point/root/.ssh/authorized_keys";
    $self->getExecutorEContext->execute(command => $rsapubkey_cmd);

    my $sync_cmd = "sync";
    $self->getExecutorEContext->execute(command => $sync_cmd);

    $container_access->umount(mountpoint => $mount_point,
                              econtext   => $self->getExecutorEContext,
                              erollback  => $args{erollback});

    $args{export_manager}->removeExport(
        container_access => $container_access,
        erollback        => $args{erollback}
    );
}

sub activate {
    my $self = shift;

    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "export_manager", "manager_params", "erollback" ]);

    my $container = EFactory::newEEntity(data => $self->getDevice());

    # Provide root rsa pub key to provide ssh key authentication
    $self->generateAuthorizedKeys(export_manager => $args{export_manager},
                                  erollback      => $args{erollback});

    # Get container export information
    my $export_name = $self->getAttr(name => 'systemimage_name');

    $args{export_manager}->createExport(container   => $container,
                                        export_name => $export_name,
                                        erollback   => $args{erollback},
                                        %{$args{manager_params}});

    # Set system image active in db
    $self->setAttr(name => 'active', value => 1);
    $self->save();

    $log->info("System image <" . $self->getAttr(name => "systemimage_name") .
               "> is now active");
}

sub deactivate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "erollback" ]);

    # Get instances of container accesses from systemimages root container
    $log->info("Remove all container accesses");
    eval {
        for my $container_access (@{ $self->_getEntity->getDevice->getAccesses }) {
            my $export_manager = EFactory::newEEntity(data => $container_access->getExportManager);
            $container_access  = EFactory::newEEntity(data => $container_access);

            $export_manager->removeExport(container_access => $container_access,
                                          erollback        => $args{erollback});
        }
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    # Set system image active in db
    $self->setAttr(name => 'active', value => 0);
    $self->save();

    $log->info("System image <" . $self->getAttr(name => "systemimage_name") . "> is now unactive");
}

sub remove {
    my $self = shift;
    my %args = @_;

    if ($self->getAttr(name => 'active')) {
        $self->deactivate(erollback => $args{erollback});
    }

    my $container;
    eval {
        $container = EFactory::newEEntity(data => $self->getDevice);

        # Remove system image container.
        $log->info("Systemimage container deletion");

        # Get the disk manager of the current container
        my $disk_manager = EFactory::newEEntity(data => $container->getDiskManager);
        $disk_manager->removeDisk(container => $container);
    };
    if($@) {
        $log->info("Unable to remove container while removing cluster:\n" . $@);
    }

    $self->delete();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
