# Copyright © 2014 Hedera Technology SAS
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

Kanopya stack builder build many clusters that represent a stack
from a json infrastructure definition. 

=end classdoc
=cut

package Entity::Component::KanopyaStackBuilder;
use base Entity::Component;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        buildStack => {
            description => 'build a stack in function of the json infrastrucutre definition.',
        },
        endStack => {
            description => 'shutdown and disable a stack.',
        },
    };
}


sub buildStack {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'stack' ],
                         optional => { 'owner_id' => Kanopya::Database::currentUser });

    # TODO: Check existance of PimpMyStack policies
    my @services = Entity::ServiceTemplate->search(hash => { service_name => { 'LIKE' => 'PMS%' } });
    if (! scalar(@services)) {
        throw Kanopya::Exception::Internal(
                  error => 'Unable to find services and policies required for building stasks, ' .
                           'perhaps you forgot to load pimpmystack.json policies and servces.')

    }

    # Run the workflow BuildStack
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->run(
        name   => 'BuildStack',
        params => {
            context => {
                stack_builder => $self,
            },
            stack => $args{stack},
            owner_id => $args{owner_id}
        }
    );
}


sub endStack {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'stack' ]);

    # TODO: run workflow EndStack.
}


1;
