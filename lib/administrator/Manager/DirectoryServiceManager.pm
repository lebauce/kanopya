# DirectoryServiceManager.pm - Object class of DirectoryService Manager included in Administrator

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
# Created 29 June 2012

package Manager::DirectoryServiceManager;
use base "Manager";

use strict;
use warnings;
use Kanopya::Exceptions;
use General;
use Hash::Merge;

use Log::Log4perl "get_logger";
my $log = get_logger("");
use Data::Dumper;

sub methods {
    return {
        getDirectoryTree  => {
            description   => 'getDirectoryTree',
        },
        searchDirectory  => {
            description   => 'searchDirectory',
        }
    };
}

=head2

=cut

sub getManagerParamsDef {
    return [
        'ad_nodes_base_dn'
      ];
}

sub getNodes {
    throw Kanopya::Exceptions::NotImplemented();
}

sub getDirectoryTree {
    throw Kanopya::Exceptions::NotImplemented();
}

sub searchDirectory {
    throw Kanopya::Exceptions::NotImplemented();
}

1;
