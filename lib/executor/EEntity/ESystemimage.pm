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

my $log = get_logger("executor");
my $errmsg;

sub createFromMasterimage {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "masterimage", "edisk_manager",
                                       "manager_params", "erollback", "econtext" ]);
    
    my $emaster_container = EEntity::EContainer::ELocalContainer->new(
                                path => $args{masterimage}->getAttr(name => 'masterimage_file'),
                                size => $args{masterimage}->getAttr(name => 'masterimage_size'),
                                # TODO: get this value from masterimage attrs.
                                filesystem => 'ext3',
                            );

    # Instance a fake econtainer for the masterimage raw file.
    $self->create(
        esrc_container => $emaster_container,
        edisk_manager  => $args{edisk_manager},
        econtext       => $args{econtext},
        erollback      => $args{erollback},
        %{$args{manager_params}}
    );

    my @group = Entity::Gp->getGroups(hash => { gp_name => 'SystemImage' });
    $group[0]->appendEntity(entity => $self->_getEntity);

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
                         required => [ "edisk_manager", "esrc_container",
                                       "erollback", "econtext" ]);

    $log->info('Device creation for new systemimage');

    my $edisk_manager     = General::checkParam(args => \%args, name => 'edisk_manager');
    my $esource_container = General::checkParam(args => \%args, name => 'esrc_container');
    my $erollback         = General::checkParam(args => \%args, name => 'erollback');
    my $econtext          = General::checkParam(args => \%args, name => 'econtext');
    my $systemimage_size  = General::checkParam(
                               args    => \%args,
                               name    => 'systemimage_size',
                               default => $esource_container->_getEntity->getAttr(
                                              name => 'container_size'
                                          )
                           );

    my $storage_provider = Entity->get(id => $edisk_manager->_getEntity->getAttr(name => 'service_provider_id'));
    my $disk_manager_econtext
        = EFactory::newEContext(ip_source      => $econtext->getLocalIp,
                                ip_destination => $storage_provider->getMasterNodeIp);

    # Creation of the device based on distribution device
    my $container = $edisk_manager->createDisk(
                        name       => $self->_getEntity->getAttr(name => 'systemimage_name'),
                        size       => $systemimage_size,
                        filesystem => $esource_container->_getEntity->getAttr(name => 'container_filesystem'),
                        econtext   => $disk_manager_econtext,
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

sub generateAuthorizedKeys {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "eexport_manager", "econtext" ]);

    # mount the root systemimage device
    my $container = $self->_getEntity()->getDevice();

    my $storage_provider = Entity->get(id => $args{eexport_manager}->_getEntity->getAttr(name => 'service_provider_id'));
    my $export_manager_econtext
        = EFactory::newEContext(ip_source      => $args{econtext}->getLocalIp,
                                ip_destination => $storage_provider->getMasterNodeIp());

    my $container_access = $args{eexport_manager}->createExport(
                               container   => $container,
                               export_name => $container->getAttr(name => 'container_name'),
                               econtext    => $export_manager_econtext,
                               erollback   => $args{erollback}
                           );

    # Get the corresponding EContainerAccess
    my $econtainer_access = EFactory::newEEntity(data => $container_access);

    my $mount_point = $container->getMountPoint;
    $econtainer_access->mount(mountpoint => $mount_point, econtext => $args{econtext});

    my $rsapubkey_cmd = "cat /root/.ssh/kanopya_rsa.pub > $mount_point/root/.ssh/authorized_keys";
    $args{econtext}->execute(command => $rsapubkey_cmd);

    my $sync_cmd = "sync";
    $args{econtext}->execute(command => $sync_cmd);

    $econtainer_access->umount(mountpoint => $mount_point, econtext => $args{econtext});

    $args{eexport_manager}->removeExport(
        container_access => $container_access,
        econtext         => $export_manager_econtext,
        erollback        => $args{erollback}
    );
}

sub activate {
    my $self = shift;

    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "eexport_manager", "manager_params", "econtext", "erollback" ]);

    my $container = $self->_getEntity()->getDevice();

    my $storage_provider = Entity->get(id => $args{eexport_manager}->_getEntity->getAttr(name => 'service_provider_id'));
    my $export_manager_econtext
        = EFactory::newEContext(ip_source      => $args{econtext}->getLocalIp,
                                ip_destination => $storage_provider->getMasterNodeIp());

    # Provide root rsa pub key to provide ssh key authentication
    $self->generateAuthorizedKeys(eexport_manager => $args{eexport_manager},
                                  econtext        => $args{econtext},
                                  erollback       => $args{erollback});

    # Get container export information
    my $export_name = $self->_getEntity()->getAttr(name => 'systemimage_name');

    my $export = $args{eexport_manager}->createExport(container   => $container,
                                                      export_name => $export_name,
                                                      econtext    => $export_manager_econtext,
                                                      erollback   => $args{erollback},
                                                      %{$args{manager_params}});

    # Set system image active in db
    $self->_getEntity()->setAttr(name => 'active', value => 1);
    $self->_getEntity()->save();

    $log->info("System image <" . $self->_getEntity()->getAttr(name => "systemimage_name") .
               "> is now active");
}

sub deactivate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "econtext" ]);

    # Get instances of container accesses from systemimages root container
    $log->info("Remove all container accesses");
    eval {
        for my $container_access (@{ $self->_getEntity->getDevice->getAccesses }) {
            my $eexport_manager  = EFactory::newEEntity(data => $container_access->getExportManager);
            my $storage_provider = $container_access->getServiceProvider;
            my $econtext = EFactory::newEContext(ip_source      => $args{econtext}->getLocalIp,
                                                 ip_destination => $storage_provider->getMasterNodeIp);

            $eexport_manager->removeExport(container_access => $container_access,
                                           econtext         => $econtext,
                                           erollback        => $self->{erollback});
        }
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }
            
    # Set system image active in db
    $self->_getEntity->setAttr(name => 'active', value => 0);
    $self->_getEntity->save();

    $log->info("System image <" . $self->_getEntity()->getAttr(name => "systemimage_name") .
               "> is now unactive");
}

sub remove {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "econtext" ]);

    if ($self->_getEntity->getAttr(name => 'active')) {
        $self->deactivate(econtext  => $args{econtext},
                          erollback => $args{erollback});
    }
    
    my $container;
    eval {
        $container = $self->_getEntity->getDevice;

        # Remove system image container.
        $log->info("Systemimage container deletion");

        # Get the disk manager of the current container
        my $edisk_manager = EFactory::newEEntity(data => $container->getDiskManager);
        my $econtext = EFactory::newEContext(
                           ip_source      => $args{econtext}->getLocalIp(),
                           ip_destination => $container->getServiceProvider->getMasterNodeIp()
                       );

        $edisk_manager->removeDisk(container => $container, econtext => $econtext);
    };
    if($@) {
        $log->info("Unable to remove container while removing cluster:\n" . $@);
    }

    $self->_getEntity->delete();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
