# Copyright © 2013 Hedera Technology SAS
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

=pod
=begin classdoc

Kanopya executor runs workflows and operations

=end classdoc
=cut

package Entity::Component::KanopyaExecutor;
use base Entity::Component;
use base MessageQueuing::RabbitMQ::Sender;

use strict;
use warnings;

use Entity::Workflow;
use Entity::Operation;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");

use constant ATTR_DEF => {
    time_step => {
        label        => 'Workflow pooling frequency',
        #type         => 'time',
        type         => 'integer',
        pattern      => '^\d+$',
        default      => 5,
        is_mandatory => 1,
        is_editable  => 1
    },
    masterimages_directory => {
        label        => 'Master images directory',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    clusters_directory => {
        label        => 'Clusters data directory',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        run => {
            description => 'Produce a workflow to run.',
            message_queuing => {
                channel => 'workflow'
            }
        },
        execute => {
            description => 'Produce an operation to execute',
            message_queuing => {
                channel => 'operation'
            }
        },
        terminate => {
            description => 'Produce an operation execution result.',
            message_queuing => {
                channel => 'operation_result'
            }
        },
    };
}


sub enqueue {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'type' ],
                         optional => { 'params'   => {},
                                       'priority' => 200 });

    my $operation = Entity::Operation->enqueue(%args);

    # Publish on the 'workflow' channel
    eval {
        MessageQueuing::RabbitMQ::Sender::run($self,
                                              workflow_id => $operation->workflow->id,
                                              %{ $self->_adm->{config}->{amqp} });
    };
    if ($@) {
        my $err = $@;
        $log->error("Unbale to run workflow <" . $operation->workflow->id . ">, removing it: $err");
        $operation->workflow->remove();

        $err->rethrow();
    }
    return $operation;
}


sub execute {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'operation_id' ]);

    # Publish on the 'operation' channel
    MessageQueuing::RabbitMQ::Sender::execute($self,
                                              operation_id => $args{operation_id},
                                              %{ $self->_adm->{config}->{amqp} });
}


sub terminate {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'operation_id', 'status' ],
                         optional => { 'exception' => undef });

    # Publish on the 'operation_result' channel
    MessageQueuing::RabbitMQ::Sender::terminate($self, %args);
}


sub run {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'name' ],
                         optional => { 'params'     => undef,
                                       'related_id' => undef,
                                       'rule_id'    => undef });

    my $workflow = Entity::Workflow->run(%args);

    # Publish on the 'workflow' channel
    eval {
        MessageQueuing::RabbitMQ::Sender::run($self,
                                              workflow_id => $workflow->id,
                                              %{ $self->_adm->{config}->{amqp} });
    };
    if ($@) {
        my $err = $@;
        $log->error("Unable to run workflow <" . $workflow->id . ">, removing it: $err");
        $workflow->remove();

        $err->rethrow();
    }
    return $workflow;
}


=pod
=begin classdoc

Generic method for sending messages.
Should be not impemeted and the call handled by the AUTOLOAD in
MessageQueuing::RabbitMQ::Sender, but we need to fix amultiautoload confilct.

=end classdoc
=cut

sub send {
    my ($self, %args) = @_;

    MessageQueuing::RabbitMQ::Sender::send($self, %args);
}

1;
