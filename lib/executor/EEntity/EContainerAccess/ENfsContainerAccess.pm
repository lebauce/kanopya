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
use Data::Dumper;

my $log = get_logger("executor");

=head2 mount

    desc: Mount the remote container acces with mount.nfs.

=cut

sub mount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    my $target = $self->_getEntity->getAttr(name => 'container_access_export');
    my $ip     = $self->_getEntity->getAttr(name => 'container_access_ip');
    my $port   = $self->_getEntity->getAttr(name => 'container_access_port');

    # Useless ? When mounting on client, server side options are automatically applyed.
    my $options = $self->_getEntity->getAttr(name => 'container_access_options');

    my $mkdir_cmd = "mkdir -p $args{mountpoint}; chmod 777 $args{mountpoint}";
    $args{econtext}->execute(command => $mkdir_cmd);

    my $mount_cmd = "mount.nfs $ip:$target $args{mountpoint} -o vers=3";
    my $cmd_res   = $args{econtext}->execute(command => $mount_cmd);

    # exitcode 8192: mount.nfs: mountpoint is busy or already mounted
    if ($cmd_res->{'stderr'}) { #and ($cmd_res->{'exitcode'} != 8192)){
        throw Kanopya::Exception::Execution(
                  error => "Unable to mount $ip:$target on $args{mountpoint}: " .
                           $cmd_res->{'stderr'}
              );
    }
    $log->info("NFS export $ip:$target mounted on <$args{mountpoint}>.");

    # TODO: insert an erollback to umount nfs volume
}

=head2 connect

    desc: Not supported, returning undef.

=cut

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    $self->{device} = '';
    return undef;
}

=head2 disconnect

    desc: Not supported, doing nothing.

=cut

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    $self->{device} = '';
    return undef;
}

1;
