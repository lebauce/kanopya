# Copyright © 2011-2012 Hedera Technology SAS
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

=pod

=begin classdoc

The billing policy defines the billing parameters describing how
a service provider establish the billing for the owner of the service.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::BillingPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use Clone qw(clone);

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

use constant POLICY_ATTR_DEF => {
    billing_limits => {
        label       => 'Limits',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
        attributes  => {
            attributes => {
                policy_id => {
                    type     => 'relation',
                    relation => 'single',
                },
                start => {
                    label        => 'Start',
                    type         => 'date',
                    is_mandatory => 1,
                    is_editable  => 1,
                },
                ending => {
                    label        => 'End',
                    type         => 'date',
                    is_mandatory => 1,
                    is_editable  => 1,
                },
                type => {
                    label   => 'Type',
                    type    => 'enum',
                    options => [ 'ram', 'cpu' ],
                    # Add a mechanism to have mutliple units in function of the option.
                    is_editable  => 1,
                    is_mandatory => 1,
                },
                soft => {
                    label        => 'Soft limit ?',
                    type         => 'boolean',
                    is_mandatory => 1,
                    is_editable  => 1,
                },
                value => {
                    label   => 'Value',
                    type    => 'string',
                    pattern => '^[0-9.]+$',
                    is_editable  => 1,
                },
                repeats => {
                    label   => 'Repeat',
                    type    => 'enum',
                    options => {1 => 'Daily'},
                    is_editable  => 1,
                },
                repeat_start_time => {
                    label   => 'Repeat start',
                    type    => 'time',
                    is_editable  => 1,
                },
                repeat_end_time => {
                    label   => 'Repeat end',
                    type    => 'time',
                    is_editable  => 1,
                },
            },
        },
    },
};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }

1;
