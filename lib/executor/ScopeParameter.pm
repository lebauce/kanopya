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

=pod
=begin classdoc

A ScopeParameter is a parameter associated to a Workflow.
It will be defined either during WorlflowDef instanciation (Specific ones) or during corresponding
rule triggering (Automatic ones)

=end classdoc
=cut

package ScopeParameter;
use base 'BaseDB';

use strict;
use warnings;

use constant ATTR_DEF => {
    scope_parameter_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    scope_id => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
};

=pod
=begin classdoc

Get the list of the names of scope parameters

@param scope_id the scope id

@return arrayref parameter names

=end classdoc
=cut



sub getNames {
    my ($class,%args) = @_;

    General::checkParams(args => \%args, required => [ 'scope_id' ]);

    my @scopeParameterList = $class->search(
                                hash => {scope_id => $args{scope_id}}
                             );
    my @scope_params = map {$_->scope_parameter_name} @scopeParameterList;

    return \@scope_params;
}

sub getAttrDef { return ATTR_DEF; }
1;