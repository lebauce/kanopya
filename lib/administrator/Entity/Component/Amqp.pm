#    Copyright © 2013 Hedera Technology SAS
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

package Entity::Component::Amqp;
use base "Entity::Component";

use strict;
use warnings;

use constant ATTR_DEF => {
        cookie => {
            pattern        => '.*',
            is_mandatory   => 0,
            is_extended    => 0,
            is_editable    => 1
        },
};

sub getAttrDef { return ATTR_DEF };

sub new {
    my ($self, %args) = @_;

    $self  = $self->SUPER::new( %args );

    $self->cookie($self->_genCookie());

    return $self;
}

sub _genCookie {
  
    my @chars = ('A'..'Z');
    my $string;
    $string .= $chars[rand @chars] for 1..10;

    return $string;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my @nodes = $self->service_provider->nodes;
    my @nodes_hostnames = map {$_->node_hostname} @nodes;

    my $definitions = "class { 'kanopya::rabbitmq':
                           disk_nodes => ['" . join ("','", @nodes_hostnames) . "'],
                           cookie     => " . $self->cookie . ",
                       }\n";

    return $definitions;
}

sub getExecToTest {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    return {
        rabbitmq => {
            cmd         => 'rabbitmqctl cluster_status',
            answer      => 'running_nodes,\[.*,?rabbit@' .
                           $args{host}->node->node_hostname .
                           ',?.*\]}',
            return_code => 0
        }
    }
}

sub label {
    my $self = shift;

    return "RabbitMQ";
}

1;
