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

The storage policy defines the parameters describing how
a service provider create/remove disks, export disk as root
filesystem to it's hosts.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::StoragePolicy;
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
    disk_manager_id => {
        label        => "Storage type",
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
    },
    export_manager_id => {
        label        => "Access protocol",
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
    }
};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


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

    # Build the storage provider list
    my $providers = {};
    for my $component ($class->searchManagers(component_category => 'DiskManager')) {
        $providers->{$component->service_provider->id} = $component->service_provider->toJSON();
    }
    my @storageproviders = values %{$providers};

    my $policy_attrdef = clone($class->getPolicyAttrDef);

    # Manually add the storage_provider_id attr because it is not an
    # attribute in the policy pattern
    $policy_attrdef->{storage_provider_id} = {
        label        => 'Data store',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
        options      => \@storageproviders
    };

    my $attributes = {
        displayed  => [ 'storage_provider_id', 'disk_manager_id' ],
        attributes => $policy_attrdef,
    };

    # Complete the attributes with common ones
    $attributes = $merge->merge($self->SUPER::getPolicyDef(%args), $attributes);

    # If storage_provider_id not defined, select it from the disk manager or
    # select the first one.
    if (not defined $args{storage_provider_id}) {
        if (defined $args{disk_manager_id}) {
            $args{storage_provider_id} = Entity->get(id => $args{disk_manager_id})->service_provider->id;
        }
        elsif ($args{set_mandatory} and scalar (@storageproviders) > 0) {
            $args{storage_provider_id} = $storageproviders[0]->{pk};
        }
    }

    # Build the list of disk manager of the storage provider
    if (defined $args{storage_provider_id}) {
        my $manager_options = {};
        for my $component ($class->searchManagers(component_category  => 'DiskManager',
                                                  service_provider_id => $args{storage_provider_id})) {
            $manager_options->{$component->id} = $component->toJSON();
            $manager_options->{$component->id}->{label} = $component->disk_type;
        }
        my @diskmanageroptions = values %{$manager_options};
        $attributes->{attributes}->{disk_manager_id}->{options} = \@diskmanageroptions;

        # If disk_manager_id defined but do not corresponding to a available value,
        # it is an old value, so delete it.
        if (not defined $manager_options->{$args{disk_manager_id}}) {
            delete $args{disk_manager_id};
        }
        # If no disk_manager_id defined and and attr is mandatory, use the first one as value
        if (not defined $args{disk_manager_id} and $args{set_mandatory} and scalar (@diskmanageroptions) > 0) {
            $args{disk_manager_id} = $diskmanageroptions[0]->{pk};
        }
    }

    if (defined $args{disk_manager_id}) {
        # Get the disk manager params from the selected disk manager
        my $diskmanager = Entity->get(id => $args{disk_manager_id});
        my $managerparams = $diskmanager->getDiskManagerParams();
        for my $attrname (keys %{$managerparams}) {
            $attributes->{attributes}->{$attrname} = $managerparams->{$attrname};
            push @{ $attributes->{displayed} }, $attrname;
        }

        # Once the disk manager parameters added, handle the export manager and its params
        push @{ $attributes->{displayed} }, 'export_manager_id';

        # Build the list of export manager usable for the disk manager
        my $manager_options = {};
        for my $component (@{ $diskmanager->getExportManagers }) {
            $manager_options->{$component->id} = $component->toJSON();
            $manager_options->{$component->id}->{label} = $component->export_type;
        }
        my @expmanageroptions = values %{$manager_options};
        $attributes->{attributes}->{export_manager_id}->{options} = \@expmanageroptions;

        # TODO: factorize the code that handle the export manager as it is
        #       the as the disk manager one.

        # If export_manager_id defined but do not corresponding to a available value,
        # it is an old value, so delete it.
        if (not defined $manager_options->{$args{export_manager_id}}) {
            delete $args{export_manager_id};
        }
        # If no export_manager_id defined and and attr is mandatory, use the first one as value
        if (not defined $args{export_manager_id} and $args{set_mandatory} and scalar (@expmanageroptions) > 0) {
            $args{export_manager_id} = $expmanageroptions[0]->{pk};
        }

        if (defined $args{export_manager_id}) {
            # Get the export manager params from the selected export manager
            my $exportmanager = Entity->get(id => $args{export_manager_id});
            $managerparams = $exportmanager->getExportManagerParams();
            for my $attrname (keys %{$managerparams}) {
                $attributes->{attributes}->{$attrname} = $managerparams->{$attrname};
                push @{ $attributes->{displayed} }, $attrname;
            }
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

For the network policy, the attribute storage_provider_id is
added to the non editable attrs because it is never stored in
the params preset of the policy.

@return the non editable params list

=end classdoc

=cut

sub getNonEditableAttributes {
    my ($self, %args) = @_;

    my $definition = $self->SUPER::getNonEditableAttributes();

    # Add the storage_provider_id as a non editable attr if disk_manager_id
    # or export_manager_id defined as as a non editable attr.
    if (defined $definition->{disk_manager_id} or defined $definition->{export_manager_id}) {
        $definition->{storage_provider_id} = 1;
    }
    return $definition;
}

1;
