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

package EOperation::ECancelWorkflow;
use base "EOperation";

use Kanopya::Exceptions;
use EFactory;
use Workflow;
use EWorkflow;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
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
    my $workflow = Workflow->get(id => $self->{params}->{workflow_id});
    $self->{context}->{workflow} = EWorkflow->new(data => $workflow, config => $self->{config});

    # Check if the workflow is 'running'
    if ($self->{context}->{workflow}->getAttr(name => 'state') ne 'running') {
        $errmsg = "Workflow <" . $self->{context}->{workflow}->getAttr(name => 'workflow_id') . "> is not active";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    $self->{context}->{workflow}->cancel(config => $self->{config});
}

sub finish {
    my $self = shift;

    delete $self->{context}->{workflow};
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
