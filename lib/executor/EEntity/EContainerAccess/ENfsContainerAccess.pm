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

package EEntity::EContainerAccess::ENfsContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Operation;

my $log = get_logger("executor");

sub mount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    my $target  = $self->_getEntity->getAttr(name => 'container_access_export');
    my $ip      = $self->_getEntity->getAttr(name => 'container_access_ip');
    my $port    = $self->_getEntity->getAttr(name => 'container_access_port');
    my $options = $self->_getEntity->getAttr(name => 'container_access_options');

    my $mkdir_cmd = "mkdir -p $args{mountpoint}";
    $args{econtext}->execute(command => $mkdir_cmd);

    my $mount_cmd = "mount.nfs $ip:$target $args{mountpoint} -o $options";
    $args{econtext}->execute(command => $mount_cmd);

    # TODO: insert an erollback with umount method.
    $log->info("NFS export $ip:$target mounted on <$args{mountpoint}>.");

    # TODO: insert an erollback to umount nfs volume
}

sub umount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    $log->info("Unmonting (<$args{mountpoint}>)");

    my $umount_cmd = "umount $args{mountpoint}";
    $args{econtext}->execute(command => $umount_cmd);
}

1;
