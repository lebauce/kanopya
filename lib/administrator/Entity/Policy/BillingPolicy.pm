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

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


=pod

=begin classdoc

Get the static policy attributes definition from the parent,
and merge with the policy type specific dynamic attributes
depending on attributes values given in parameters.

@return the dynamic attributes definition.

=end classdoc

=cut

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         optional => { 'params'              => {},
                                       'set_mandatory'       => 0,
                                       'set_editable'        => 1,
                                       'set_params_editable' => 0 });

    # Merge params wirh existing values
    $args{params} = $self->processParams(%args);

    # Complete the attributes with common ones
    my $attributes = $self->SUPER::getPolicyDef(%args);

    $attributes->{relations} = {
        billing_limits => {
            attrs    => { accessor => 'multi' },
            cond     => { 'foreign.policy_id' => 'self.policy_id' },
            resource => 'billing_limit'
        }
    };

    push @{ $attributes->{displayed} }, {
        'billing_limits' => [ 'start', 'ending', 'type',
                              'soft', 'value', 'repeats',
                              'repeat_start_time', 'repeat_end_time' ]
    };

    $self->setValues(attributes          => $attributes,
                     values              => $args{params},
                     set_mandatory       => delete $args{set_mandatory},
                     set_editable        => delete $args{set_editable},
                     set_params_editable => delete $args{set_params_editable});

    return $attributes;
}

=pod

=begin classdoc

Handle billing policy specific parameters to build
the policy pattern. Here, handle the list of billing limits
by transforming the limits array to a hash, indexed by unique
keys to allows to merge with another policies.

@return a policy pattern fragment

=end classdoc

=cut

sub getPatternFromParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    my $pattern = $self->SUPER::getPatternFromParams(params => $args{params});

    if (ref($args{params}->{billing_limits}) eq 'ARRAY') {
        my %limits = map { join('_',  values %{$_} ) => $_ } @{ delete $args{params}->{billing_limits} };
        $pattern->{billing_limits} = \%limits;
    }
    return $pattern;
}

1;
