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

package EEntity::EOperation::ESelectDataModel;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use DataModelSelector;

my $log = get_logger("");
my $errmsg;


=head2 check

=cut

sub check {
    my $self = shift;
    my %args = @_;
    General::checkParams(args => $self->{context}, required => [ "combination"]);
}

sub execute {
    my $self = shift;

    DataModelSelector->selectDataModel(
        combination => $self->{context}->{combination},
        start_time  => $self->{params}->{start_time},
        end_time    => $self->{params}->{end_time},
        node_id     => $self->{params}->{node_id}, # undef if not defined
    );
}
1;