#    Copyright © 2011 Hedera Technology SAS
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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package Entity::User::Customer;
use base "Entity::User";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef{ return ATTR_DEF; }


=pod

=begin classdoc

@constructor

Override the Entity constructor to insert customers in
the User group in addition of the automatically associated
group Customer.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    # Automattically add the user to the Customer profile
    $self->setProfiles(profile_names => [ 'Customer' ]);

    return $self;
}

1;
