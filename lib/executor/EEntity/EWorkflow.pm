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
use base 'EEntity';

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
    General::checkParams(args => \%args, required => ['state']);

    # TODO: filter on states to get operation to cancel only.
    my @operations = Entity::Operation->search(hash => {
                         workflow_id => $self->getAttr(name => 'workflow_id'),
                     });

    for my $operation (@operations) {
        if ($operation->getAttr(name => 'state') ne 'pending') {
            eval {
                $operation->unlockContext();
                EEntity::EOperation->new(op => $operation)->cancel();
            };
            if ($@){
                $log->error("Error during operation cancel :\n$@");
            }
        }
        $operation->remove();
    }

    # Remove here possible resilient locks due to contexts params overriding
    # TODO: Be sure no resilient locks occurs
    for my $lock (EntityLock->search(hash => { consumer_id => $self->id })) {
        $lock->remove();
    }
    $self->setState(state => $args{state});
}

sub pepareNextOp {
    my $self = shift;
    my %args = @_;

    $self->getCurrentOperation->setState(state => 'succeeded');

    if(not $args{params}) {
        $args{params} = {};
    }

    my $next;
    eval {
        $next = $self->getCurrentOperation();
    };
    if ($@) {
        $self->finish();
    }
    else {
        # Update the context with the last operation output context
        $args{params}->{context} = $args{context};
        $next->setParams(params => $args{params});

        $next->lockContext();
        $next->setState(state => 'ready');
    }
}

1;
