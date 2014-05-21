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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package EEntity::EComponent::EOpenssh5;
use base "EEntity::EComponent";

use strict;
use warnings;

use Kanopya::Exceptions;

use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod

=begin classdoc

Check if host is up

@param host the target host to check

@return boolean

=end classdoc

=end

=cut

sub isUp {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    try {
        $args{host}->getEContext->execute(command => "uptime");
    }
    catch (Kanopya::Exception $err) {
        $log->info("Try to contact host <" . $args{host}->adminIp . ">, host not sshable");
        return 0;
    }
    catch ($err) {
        throw Kanopya::Exception(error => "$err");
    }

    return 1;
}

sub configureNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point' ]);

    my $privatedir = $self->_executor->private_directory;
    my $rsapubkey_cmd = "mkdir -m 600 -p $args{mount_point}/root/.ssh ; " .
                        "install -m 600 $privatedir/kanopya_rsa.pub " .
                        "$args{mount_point}/root/.ssh/authorized_keys";

    $self->_host->getEContext->execute(command => $rsapubkey_cmd);
}

1;
