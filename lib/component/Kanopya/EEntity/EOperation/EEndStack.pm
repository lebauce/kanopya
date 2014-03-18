#    Copyright © 2009-2014 Hedera Technology SAS
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

=pod
=begin classdoc

Create all service required for a stack

@since    2014-Feb-2014
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EEndStack;
use base "EEntity::EOperation";

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl "get_logger";
use Date::Simple (':all');

my $log = get_logger("");


=pod
=begin classdoc

@param stack_builder the stack builder component

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "stack_builder", "user" ]);

    General::checkParams(args => $self->{params}, required => [ "stack_id" ]);
}


=pod
=begin classdoc

Stop all services started for a stack

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    # Call the method on the corresponding component
    $self->{context}->{stack_builder}->endStack(
        stack_id  => $self->{params}->{stack_id},
        user      => $self->{context}->{user},
        # TODO: Let all EEntity access to the workflow that they related
        workflow  => $self->workflow,
        erollback => $self->{erollback}
    );
}


=pod
=begin classdoc

Handle fail of end stack, probably force stop clusters.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;

    $self->{context}->{stack_builder}->cancelEndStack(
        user => $self->{context}->{user},
    );
}

1;
