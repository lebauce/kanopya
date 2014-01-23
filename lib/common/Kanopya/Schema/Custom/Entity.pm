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
package Kanopya::Schema::Custom::Entity;

use strict;
use warnings;


# Custom relation defition for Entity
use Kanopya::Schema::Result::Entity;

Kanopya::Schema::Result::Entity->many_to_many("time_periods", "entity_time_periods", "time_period");

Kanopya::Schema::Result::Entity->might_have(
  "workflow",
  "Kanopya::Schema::Result::Workflow",
  { "foreign.workflow_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

Kanopya::Schema::Result::Entity->has_many(
  "entity_states",
  "Kanopya::Schema::Result::EntityState",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

Kanopya::Schema::Result::Entity->has_many(
  "alerts",
  "Kanopya::Schema::Result::Alert",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
