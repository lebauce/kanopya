#    Copyright © 2014 Hedera Technology SAS
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

Provides the Kanopya version numbers.

@since 2014-Jun-13

=end classdoc
=cut

package Kanopya::Version;

use strict;
use warnings;

use version;


# The Kanopya version numbers fit the following convention:
# (Major version).(Minor version).(Iteration number)[.(Hotfix number)]

our $VERSION = version->declare("1.10.2");


=pod
=begin classdoc

Return the Kanopya version numbers.

=end classdoc
=cut

sub version {
    return version->parse($VERSION)->normal;
}

1;
