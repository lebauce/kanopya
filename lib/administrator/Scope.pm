#    Copyright © 2012 Hedera Technology SAS
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
package Scope;

use strict;
use warnings;
use base 'BaseDB';

use constant ATTR_DEF => {
    scope_name              =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }

sub getIdFromName{
    my ($class,%args) = @_;
    General::checkParams(args => \%args, required => [ 'scope_name' ]);
    my $scope_name = $args{scope_name};
    my $scope    = Scope->find(hash => {scope_name => $scope_name});
    return $scope->getAttr(name => 'scope_id');
}
1;