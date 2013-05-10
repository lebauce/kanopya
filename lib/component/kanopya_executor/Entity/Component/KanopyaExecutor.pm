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

package Entity::Component::KanopyaExecutor;
use base Entity::Component;
use base MessageQueuing::RabbitMQ::Sender;

use strict;
use warnings;

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
            description => 'Produce an operation execution result',
            message_queuing => {
                channel => 'operation_result'
            }
        },
    };
}


sub execute {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'type', 'params' ],
                         optional => { 'priority' => 200 });

    my $operation = Entity::Operation->enqueue(priority => $args{priority},
                                               type     => $args{type},
                                               params   => $args{params});

    # Transmit the created operation id for instance.
    $self->SUPER::execute(operation_id => $operation->id);

    return $operation;
}

sub getPuppetDefinition {
    return "class { 'kanopya::executor':\n" .
           "    password => 'K4n0pY4',\n" .
           "}\n";
}

1;
