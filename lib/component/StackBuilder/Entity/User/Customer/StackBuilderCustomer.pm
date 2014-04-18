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

The customer using the StackBuilder component. It is usefull to use this
type of customer while building stacks instead of regular users because
the notifation mails contains specifis information about stacks.

@since    2014-Apr-18
@instance hash
@self     $self

=end classdoc

=cut

package Entity::User::Customer::StackBuilderCustomer;
use base Entity::User::Customer;

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");


use constant ATTR_DEF => {};

sub getAttrDef{ return ATTR_DEF; }

1;
