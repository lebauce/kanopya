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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EServiceProvider::EInside::ECluster::EClusterMock;
use base 'EEntity::EServiceProvider::EInside::ECluster';

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub checkComponents {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $log->info("Mock: return 1 to simulate all components up.");
    return 1;
}

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $log->info("Mock: doing nothing instead of calling postStartNode on cluster components.");
}

sub stopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $log->info("Mock: doing nothing instead of calling stopNode on cluster components.");
}

sub readyNodeRemoving {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $log->info("Mock: return 1 to simulate all components ready for node removal.");
    return 1;
}

sub postStopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    $log->info("Mock: doing nothing instead of calling postStopNode on cluster components.");
}

1;
