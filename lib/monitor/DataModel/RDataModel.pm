#    Copyright © 2013 Hedera Technology SAS
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

Abstract class representing a DataModel which uses R to perform a forecast. Most of the time, these DataModels
won't need a configuration step or any particular entry in the database because the only thing they do is
calling R and let him do the prediction.

=end classdoc

=cut

package Entity::DataModel::RDataModel;

use base 'Entity::DataModel';

use strict;
use warnings;

# Module for binding R into Perl
use Statistics::R;

# Module for R objects conversions
use Utils::R;

# Not necessary here
sub configure {
    
}

1;