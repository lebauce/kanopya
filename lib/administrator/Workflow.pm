# Copyright © 2011-2012 Hedera Technology SAS
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

package Workflow;
use base 'BaseDB';

use strict;
use warnings;

use WorkflowDef;
use ParamPreset;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');
my $errmsg;

use constant ATTR_DEF => {
    workflow_name => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    state => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub run {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'name' ]);

    my $def = WorkflowDef->find(hash => { workflow_def_name => $args{name} });
    my $workflow = Workflow->new(workflow_name => $args{name});
    delete $args{name};

    my $steps = $def->{_dbix}->workflow_steps;
    while (my $step = $steps->next) {
        $workflow->enqueue(
            priority => 200,
            type     => $step->operationtype->get_column('operationtype_name'),
            %args
        );
        if (defined $args{params}) {
            delete $args{params};
        }
    }

    return $workflow;
}

sub enqueue {
    my $self = shift;
    my %args = @_;

    Operation->enqueue(
        workflow_id => $self->getAttr(name => 'workflow_id'),
        %args,
    );
}

sub getCurrentOperation {
    my $self = shift;
    my %args = @_;

    my $adm = Administrator->new();

    my $workflow_id = $self->getAttr(name => 'workflow_id');
    my $current = $adm->{db}->resultset('Operation')->search(
                      { workflow_id => $workflow_id, -not => { state => 'succeeded' } },
                      { order_by    => { -asc => 'execution_rank' }}
                  )->single();

    my $op;
    eval {
        $op = Operation->get(id => $current->get_column("operation_id"));
    };
    if ($@) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Not more operations within workflow <$workflow_id>"
              );
    }
    return $op;
}

sub cancel {
    my $self = shift;
    my %params;

    Operation->enqueue(
        priority => 1,
        type     => 'CancelWorkflow',
        params   => {
            workflow_id => $self->getAttr(name => 'workflow_id'),
        }
    );
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

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    $self->setAttr(name => 'state', value => $args{state});
    $self->save();
}

sub finish {
    my $self = shift;
    my %args = @_;

    my @operations = Operation->search(hash => {
                         workflow_id => $self->getAttr(name => 'workflow_id'),
                     });

    for my $operation (@operations) {
        $operation->delete();
    }
    $self->setState(state => 'done');
}

1;
