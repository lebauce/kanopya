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

EIscsiContainerAccess - execution class of iscsi container access entities.

=head1 SYNOPSIS


=head1 DESCRIPTION

EContainerAccess::EIscsiContainerAccess is the execution class for iscsi container access entities.

=head1 METHODS

=cut

package EEntity::EContainerAccess::EIscsiContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Operation;

my $log = get_logger("executor");

=head2 connect

    desc: Creating open-iscsi node, and wait for the device appeared.

=cut

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $target = $self->_getEntity->getAttr(name => 'container_access_export');
    my $ip     = $self->_getEntity->getAttr(name => 'container_access_ip');
    my $port   = $self->_getEntity->getAttr(name => 'container_access_port');
    my $lun    = $self->_getEntity->getAttr(name => 'container_lun_name');

    $log->info("Creating open iscsi node <$target> from <$ip:$port>.");

    my $create_node_cmd = "iscsiadm -m node -T $target -p $ip:$port -o new";
    $args{econtext}->execute(command => $create_node_cmd);

    $log->info("Loging in node <$target> (<$ip:$port>).");

    my $login_node_cmd = "iscsiadm -m node -T $target -p $ip:$port -l";
    $args{econtext}->execute(command => $login_node_cmd);

    my $device = '/dev/disk/by-path/ip-' . $ip . ':' . $port . '-iscsi-' . $target . '-' . $lun;

    my $retry = 10;
    while (! -e $device) {
        if ($retry <= 0) {
            my $errmsg = "IsciContainer->mount: unable to find waited device<$device>";
            $log->error($errmsg);

            throw Kanopya::Exception::Execution($errmsg);
        }
        $retry -= 1;

        $log->info("Device not found yet (<$device>), sleeping 1s and retry.");
        sleep 1;
    }

    $log->info("Device found (<$device>).");
    $self->_getEntity->setAttr(name  => 'device_connected',
                               value => $device);
    return $device;
}

=head2 disconnect

    desc: Deleting open-iscsi node.

=cut

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $target = $self->_getEntity->getAttr(name => 'container_access_export');
    my $ip     = $self->_getEntity->getAttr(name => 'container_access_ip');
    my $port   = $self->_getEntity->getAttr(name => 'container_access_port');

    $log->info("Logout from node <$target>");

    my $logout_cmd = "iscsiadm -m node -U manual";
    $args{econtext}->execute(command => $logout_cmd);

    $log->info("Deleting node <$target> (<$ip:$port>).");

    my $delete_node_cmd = "iscsiadm -m node -T $target -p $ip:$port -o delete";
    $args{econtext}->execute(command => $delete_node_cmd);

    $self->_getEntity->setAttr(name  => 'device_connected',
                               value => '');

    # TODO: insert an eroolback with mount method ?
}

1;
