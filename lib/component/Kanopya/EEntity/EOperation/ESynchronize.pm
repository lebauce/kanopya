#    Copyright © 2012-2013 Hedera Technology SAS
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

package EEntity::EOperation::ESynchronize;
use base "EEntity::EOperation";

use strict;
use warnings;

use EEntity;
use Kanopya::Exceptions;

use Entity::ServiceProvider;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my ($self,%args) = @_;

    General::checkParams(args => $self->{context}, required => [ "entity" ]);
}

sub execute {
    my ($self, %args) = @_;

    $self->{context}->{entity}->synchronize(
        erollback => $self->{erollback},
        %{ $self->{params} },
    );
}

1;
