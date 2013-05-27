# Copyright © 2011 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EWorkflow;
use base EEntity;

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Operation;
use EEntity::EOperation;
use EntityLock;

use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use vars qw ( $AUTOLOAD );

sub cancel {
    my ($self, %args) = @_;

    for my $operation (Entity::Operation->search(order_by => 'execution_rank DESC')) {
        if ($operation->state ne 'pending') {
            eval {
                $log->info("Cancelling operation <" . $operation->id . ">");
                EEntity::EOperation->new(operation => $operation, skip_not_found => 1)->cancel();
            };
            if ($@){
                $log->error("Error during operation cancel :\n$@");
            }
        }
        $operation->remove();
    }
    $self->setState(state => 'cancelled');
}

1;
