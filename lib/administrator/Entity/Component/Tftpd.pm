# Tftpd.pm TFTP server (trivial ftp, part of pxe) component (Adminstrator side)
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
# Created 24 july 2010

package Entity::Component::Tftpd;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Hash::Merge qw(merge);

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    tftpd_repository => {
        label        => 'Repository path',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    return {
        tftp => {
            port => 69,
            protocols => ['udp']
        }
    }
};

sub getExecToTest {
    return {
        tftp => {
            cmd => 'netstat -lnpu | grep 69',
            answer => '.+$',
            return_code => '0'
        }
    };
}

sub getBaseConfiguration {
    return {
        tftpd_repository => '/var/lib/kanopya/tftp',
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        tftpd => {
            manifest => $self->instanciatePuppetResource(
                            name => "kanopya::tftpd",
                            params => {
                                tftpdir => $self->tftpd_repository
                            }
                        )
        }
    } );
}

sub getTftpDirectory {
    my ($self, %args) = @_;

    return $self->tftpd_repository;
}

1;
