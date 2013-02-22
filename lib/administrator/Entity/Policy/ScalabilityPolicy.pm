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

The scalability policy defines the parameters describing how a service
manage it scalability.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::ScalabilityPolicy;
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
    cluster_min_node => {
        label        => 'Minimum node number',
        type         => 'integer',
        pattern      => '^[1-9][0-9]*$',
        is_mandatory => 1
    },
    cluster_max_node => {
        label        => 'Maximum node number',
        type         => 'integer',
        pattern      => '^[1-9][0-9]*$',
        is_mandatory => 1
    },
    cluster_priority => {
        label        => 'Cluster priority',
        type         => 'integer',
        pattern      => '^[1-9][0-9]*$',
        is_mandatory => 1
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

    my $displayed = [ 'cluster_min_node', 'cluster_max_node', 'cluster_priority' ];
    $attributes = $merge->merge($attributes, { displayed => $displayed });

    $self->setValues(attributes          => $attributes,
                     values              => $args{params},
                     set_mandatory       => delete $args{set_mandatory},
                     set_editable        => delete $args{set_editable},
                     set_params_editable => delete $args{set_params_editable});

    return $attributes;
}

1;
