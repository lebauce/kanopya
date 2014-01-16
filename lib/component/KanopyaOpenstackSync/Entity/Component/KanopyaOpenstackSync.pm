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

package Entity::Component::KanopyaOpenstackSync;
use base Entity::Component;
use base Manager::DaemonManager;

use strict;
use warnings;

use Kanopya::Database;
use Kanopya::Exceptions;
use Kanopya::Config;

use Hash::Merge qw(merge);

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    control_queue => {
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        registerNovaController => {
            description => 'register a nova controller to the openstack sync daemon.',
        },
        unregisterNovaController => {
            description => 'unregister a nova controller from the openstack sync daemon.',
        },
    };
}


=pod
=begin classdoc

Use the daemon control queue to register a nova controller to synchronize.
The daemon should run a new child instance to consume messages on the nova controller
notification queue.

@see <package>OpenstackSync</package>

@param nova_controller_id the nova controller id to register

=end classdoc
=cut

sub registerNovaController {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'nova_controller_id' ]);

    # Publish on the daemon control queue
    $self->controlDaemon(cbname             => 'novacontroller-' . $args{nova_controller_id},
                         control            => 'spawn',
                         nova_controller_id => $args{nova_controller_id});
}


=pod
=begin classdoc

Use the daemon control queue to unregister a nova controller.
The daemon should kill the child instance that consume messages on the nova controller
notification queue.

@see <package>OpenstackSync</package>

@param nova_controller_id the nova controller id to unregister

=end classdoc
=cut

sub unregisterNovaController {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'nova_controller_id' ]);

    # Publish on the daemon control queue
    $self->controlDaemon(cbname             => 'novacontroller-' . $args{nova_controller_id},
                         control            => 'kill',
                         nova_controller_id => $args{nova_controller_id});
}

1;
