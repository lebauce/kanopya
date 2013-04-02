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

package EEntity::EOperation::ECancelWorkflow;
use base "EEntity::EOperation";

use Kanopya::Exceptions;
use EEntity;
use Entity::Workflow;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{params}, required => [ "workflow_id" ]);
}

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    # Workflow is not an entity...
    my $workflow = Entity::Workflow->get(id => $self->{params}->{workflow_id});
    $self->{context}->{workflow} = EEntity->new(data => $workflow);

    # Check if the workflow is 'running'
    if ($self->{context}->{workflow}->state ne 'running') {
        $errmsg = "Workflow <" . $self->{context}->{workflow}->id . "> is not active";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    $self->{context}->{workflow}->cancel(state => 'cancelled');
}

sub finish {
    my $self = shift;

    delete $self->{context}->{workflow};
}

1;
