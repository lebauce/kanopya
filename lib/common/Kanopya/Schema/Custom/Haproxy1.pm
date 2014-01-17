#    Copyright © 2013 Hedera Technology SAS
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

Contain the custom relation definition for auto-generated schemas.

@since    2013-Nov-21
@instance hash
@self     $class

=end classdoc
=cut

use utf8;
package Kanopya::Schema::Custom::Haproxy1;

use strict;
use warnings;


# Custom relation defition for Haproxy1
use Kanopya::Schema::Result::Haproxy1;

Kanopya::Schema::Result::Haproxy1->has_many(
  "haproxy1_listens",
  "Kanopya::Schema::Result::Haproxy1Listen",
  { "foreign.haproxy1_id" => "self.haproxy1_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
