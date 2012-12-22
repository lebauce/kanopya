# Copyright © 2012 Hedera Technology SAS
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
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Kanopya module to handle operation and workflow execution 

@since 12/12/12
@instance hash
@self $self

=end classdoc

=cut

package Kanopya::Tools::Execution;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Pod;

use Kanopya::Exceptions;
use General;
use Executor;

my @args = ();
my $executor = Executor->new();

=pod

=begin classdoc

Manage operation and workflow execution
Check if all the operations of a workflow have been executed, and if not trigger oneRuns


=end classdoc

=cut

sub execute {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'entity' ]);

    my $workflow;

    if (ref $args{entity} eq 'Entity::Operation') {
        $workflow = $args{entity}->workflow;
    }
    elsif (ref $args{entity} eq 'Entity::Workflow') {
        $workflow = $args{entity};
    }
    else {
        throw Kanopya::Exception::Internal(
            error => 'wrong type of entity given to execute'
        );
    }

    WORKFLOW:
    while(1) {
        $executor->oneRun;

        my $current;
        eval {
          $current = $workflow->getCurrentOperation;
        };

        # refresh workflow view
        $workflow = Entity::Workflow->find(hash => {workflow_id => $workflow->id});

        my $state = $workflow->state;
        if ($state eq 'running') {
            sleep(5);
            next WORKFLOW;
        }
        elsif ($state eq 'done') {
            diag('Workflow ' . $workflow->id . ' done');
            last WORKFLOW;
        }
        elsif ($state eq 'failed') {
            diag('Workflow ' . $workflow->id . ' failed');
            throw Kanopya::Exception::Internal(error => 'Execution of workflow ' . $workflow->workflow_name . ' (' .$workflow->id . ') failed');
        }
        elsif ($state eq 'cancelled') {
            diag('Workflow ' . $workflow->id . ' cancelled');
            throw Kanopya::Exception::Internal(error => 'Execution of workflow ' . $workflow->workflow_name . ' (' .$workflow->id . ') cancelled');
        }
    }

}

1;
