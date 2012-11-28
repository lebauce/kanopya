#    Copyright © 2011 Hedera Technology SAS
#
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

package EEntity::EComponent::EPuppetmaster2::EPuppetmaster2Mock;
use base 'EEntity::EComponent::EPuppetmaster2';

use strict;
use warnings;

use Log::Log4perl 'get_logger';
my $log = get_logger("");
my $errmsg;

sub createHostCertificate {
    my ($self, %args) = @_;
 
    General::checkParams(args => \%args, required => [ 'mount_point', 'host_fqdn' ]);

    $log->info("Mock: doing nothing instead of creating the host certificate.");
}

sub createHostManifest {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'puppet_definitions', 'host_fqdn' ]);

    $log->info("Mock: doing nothing instead of creating the host manifest.");
}

1;
