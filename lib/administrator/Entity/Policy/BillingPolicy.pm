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

package Entity::Policy::BillingPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, optional => { 'set_mandatory' => 0 });

    %args = %{ $self->mergeValues(values => \%args) };

    my $attributes = {
        displayed  => [],
        attributes =>  {
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
                        limit_start => {
                            label        => 'Start',
                            type         => 'date',
                            is_mandatory => 1,
                            is_editable  => 1,
                        },
                        limit_ending => {
                            label        => 'End',
                            type         => 'date',
                            is_mandatory => 1,
                            is_editable  => 1,
                        },
                        limit_type => {
                            label   => 'Type',
                            type    => 'enum',
                            options => [ 'ram', 'cpu' ],
                            # Add a mechanism to have mutliple units in function of the option.
                            is_editable  => 1,
                        },
                        limit_soft => {
                            label        => 'Soft limit ?',
                            type         => 'boolean',
                            is_mandatory => 1,
                            is_editable  => 1,
                        },
                        limit_value => {
                            label   => 'Value',
                            type    => 'string',
                            pattern => '^[0-9.]+$',
                            is_editable  => 1,
                        },
                        limit_repeats => {
                            label   => 'Repeat',
                            type    => 'enum',
                            options => ['Daily'],
                            is_editable  => 1,
                        },
                        limit_repeat_start_time => {
                            label   => 'Repeat start',
                            type    => 'time',
                            is_editable  => 1,
                        },
                        limit_repeat_end_time => {
                            label   => 'Repeat end',
                            type    => 'time',
                            is_editable  => 1,
                        },
                    },
                },
            },
        },
        relations => {
            billing_limits => {
                attrs    => { accessor => 'multi' },
                cond     => { 'foreign.policy_id' => 'self.policy_id' },
                resource => 'billing_limit'
            },
        }
    };
    

    push @{ $attributes->{displayed} }, {
        'billing_limits' => [ 'limit_start', 'limit_ending', 'limit_type',
                              'limit_soft', 'limit_value', 'limit_repeats',
                              'limit_repeat_start_time', 'limit_repeat_end_time' ]
    };

    # Complete the attributes with common ones
    $attributes = $merge->merge($self->SUPER::getPolicyDef(%args), $attributes);

    $self->setValues(attributes => $attributes, values => \%args);
    return $attributes;
}

1;
