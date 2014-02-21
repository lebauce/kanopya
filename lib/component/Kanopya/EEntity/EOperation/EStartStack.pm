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

package EEntity::EOperation::EStartStack;
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

    General::checkParams(args => $self->{context}, required => [ "stack_builder" ]);

    General::checkParams(args => $self->{params}, required => [ "owner_id" ]);
}


=pod
=begin classdoc

Create all service required for a stack

=end classdoc
=cut

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    # Call the method on the corresponding component
    $self->{context}->{stack_builder}->startStack(
        owner_id => $self->{params}->{owner_id},
        # TODO: Let all EEntity access to the workflow that they related
        workflow => $self->workflow
    );
}

1;
