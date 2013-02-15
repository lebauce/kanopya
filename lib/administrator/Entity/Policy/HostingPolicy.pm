# Copyright © 2011-2013 Hedera Technology SAS
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

The hosting policy defines the hosting parameters describing how
a service provider find free hosts and manage them during all
the service life cycle.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::HostingPolicy;
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
    host_manager_id => {
        label        => "Host type",
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 1,
        reload       => 1,
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
                         optional => { 'set_mandatory'       => 0,
                                       'set_editable'        => 1,
                                       'set_params_editable' => 0 });

    %args = %{ $self->mergeValues(values => \%args) };

    # Build the host provider list
    my $providers = {};
    for my $component ($class->searchManagers(component_category => 'HostManager')) {
        $providers->{$component->service_provider->id} = $component->service_provider->toJSON();
    }
    my @hostproviders = values %{$providers};

    my $policy_attrdef = clone($class->getPolicyAttrDef);

    # Manually add the host_provider_id attr because it is not an
    # attribute in the policy pattern
    $policy_attrdef->{host_provider_id} = {
        label        => 'Host provider',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 1,
        reload       => 1,
    };

    $policy_attrdef->{host_provider_id}->{options} = \@hostproviders;

    my $attributes = {
        displayed  => [ 'host_provider_id', 'host_manager_id' ],
        attributes => $policy_attrdef,
    };

    # Complete the attributes with common ones
    $attributes = $merge->merge($self->SUPER::getPolicyDef(%args), $attributes);

    # If host_provider_id not defined, select it from host manager if defined
    if (not defined $args{host_provider_id}) {
        if (defined $args{host_manager_id}) {
            $args{host_provider_id} = Entity->get(id => $args{host_manager_id})->service_provider->id;
        }
        elsif ($args{set_mandatory} and scalar (@hostproviders) > 0) {
            $args{host_provider_id} = $hostproviders[0]->{pk};
        }
    }

    # Build the list of host manager of the host provider if defined
    if (defined $args{host_provider_id}) {
        my $manager_options = {};
        for my $component ($class->searchManagers(component_category  => 'HostManager',
                                                  service_provider_id => $args{host_provider_id})) {
            $manager_options->{$component->id} = $component->toJSON();
            $manager_options->{$component->id}->{label} = $component->host_type;
        }
        my @options = values %{$manager_options};
        $attributes->{attributes}->{host_manager_id}->{options} = \@options;

        # If host_manager_id defined but do not corresponding to a available value,
        # it is an old value, so delete it.
        if (not defined $manager_options->{$args{host_manager_id}}) {
            delete $args{host_manager_id};
        }
        # If no host_manager_id defined and and attr is mandatory, use the first one as value
        if (not defined $args{host_manager_id} and $args{set_mandatory} and scalar (@options) > 0) {
            $args{host_manager_id} = $options[0]->{pk};
        }
    }

    if (defined $args{host_manager_id}) {
        # Get the host manager params from the selected host manager
        my $hostmanager = Entity->get(id => $args{host_manager_id});
        my $managerparams = $hostmanager->getHostManagerParams();
        for my $attrname (keys %{$managerparams}) {
            $attributes->{attributes}->{$attrname} = $managerparams->{$attrname};
            push @{ $attributes->{displayed} }, $attrname;
        }
    }

    $self->setValues(attributes          => $attributes,
                     values              => \%args,
                     set_mandatory       => delete $args{set_mandatory},
                     set_editable        => delete $args{set_editable},
                     set_params_editable => delete $args{set_params_editable});

    return $attributes;
}


=pod

=begin classdoc

For the hosting policy, the attribute host_manager_id is
added to the non editable attrs because it is never stored in
the params preset of the policy.

@return the non editable params list

=end classdoc

=cut

sub getNonEditableAttributes {
    my ($self, %args) = @_;

    my $definition = $self->SUPER::getNonEditableAttributes();

    # Add the host_provider_id as a non editable attr if host_manager_id
    # defined as as a non editable attr.
    if (defined $definition->{host_manager_id}) {
        $definition->{host_provider_id} = 1;
    }
    return $definition;
}


=pod

=begin classdoc

Remove possibly defined host_provider_id from params, as it is a
field convenient for manager selection only.

@return a policy pattern fragment

=end classdoc

=cut

sub getPatternFromParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    delete $args{params}->{host_provider_id};

    return $self->SUPER::getPatternFromParams(params => $args{params});
}

1;
