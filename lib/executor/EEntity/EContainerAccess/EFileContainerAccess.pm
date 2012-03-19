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

=head1 NAME

ENfsContainerAccess - execution class of iscsi container access entities.

=head1 SYNOPSIS


=head1 DESCRIPTION

EContainerAccess::ENfsContainerAccess is the execution class for iscsi container access entities.

=head1 METHODS

=cut

package EEntity::EContainerAccess::EFileContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Operation;
use EFactory;
use Entity::ContainerAccess;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");

sub getMountOpts {
    my $self = shift;
    my %args = @_;

    return '-o loop';
}

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $underlying_access_id = $self->_getEntity->getContainer->getAttr(
                                   name => 'container_access_id'
                               );

    my $eunderlying_access = EFactory::newEEntity(
                                 data => Entity::ContainerAccess->get(id => $underlying_access_id)
                             );

    my $mountpoint = $self->buildMountpoint(eunderlying_access => $eunderlying_access);
    $eunderlying_access->mount(mountpoint => $mountpoint,
                               econtext   => $args{econtext});

    $self->{device} = $mountpoint . '/' . $self->_getEntity->getContainer->getAttr(
                          name => 'container_device'
                      );
    return $self->{device};
}

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $underlying_access_id = $self->_getEntity->getContainer->getAttr(
                                   name => 'container_access_id'
                               );

    my $eunderlying_access = EFactory::newEEntity(
                                 data => Entity::ContainerAccess->get(id => $underlying_access_id)
                             );

    my $mountpoint = $self->buildMountpoint(eunderlying_access => $eunderlying_access);
    $eunderlying_access->umount(mountpoint => $mountpoint,
                                econtext   => $args{econtext});
    $self->{device} = '';
}

sub buildMountpoint {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'eunderlying_access' ]);

    my $underlying_name = $args{eunderlying_access}->_getEntity->getContainer->getAttr(
                              name => 'container_name'
                          );
    my $file_name = $self->_getEntity->getContainer->getAttr(
                        name => 'container_device'
                    );

    return "/mnt/" . $underlying_name . "_connect_" . $file_name;
}
1;
