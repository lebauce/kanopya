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
    for my $component ($class->searchManagers(component_category => 'Storage')) {
        $providers->{$component->service_provider->id} = $component->service_provider->toJSON();
    }
    my @storageproviders = values %{$providers};

    my $policy_attrdef = clone($class->getPolicyAttrDef);
    $policy_attrdef->{storage_provider_id}->{options} = \@storageproviders;

    # Manually add the host_provider_id attr because it is not an
    # attribute in the policy pattern
    $policy_attrdef->{storage_provider_id} = {
        label        => 'Data store',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
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
        elsif (scalar @storageproviders) {
            $args{storage_provider_id} = $storageproviders[0]->{pk};
        }
    }

    # Build the list of disk manager of the storage provider
    my $manager_options = {};
    for my $component ($class->searchManagers(component_category  => 'Storage',
                                              service_provider_id => $args{storage_provider_id})) {
        $manager_options->{$component->id} = $component->toJSON();
        $manager_options->{$component->id}->{label} = $component->disk_type;
    }
    my @diskmanageroptions = values %{$manager_options};
    $attributes->{attributes}->{disk_manager_id}->{options} = \@diskmanageroptions;

    # If the manager id not defined or the defined value not in options
    # so use the first options as selected value.
    if (not defined $args{disk_manager_id} or not defined $manager_options->{$args{disk_manager_id}}) {
        $args{disk_manager_id} = $attributes->{attributes}->{disk_manager_id}->{options}[0]->{pk};
    }

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
    $manager_options = {};
    for my $component (@{ $diskmanager->getExportManagers }) {
        $manager_options->{$component->id} = $component->toJSON();
        $manager_options->{$component->id}->{label} = $component->export_type;
    }
    my @expmanageroptions = values %{$manager_options};
    $attributes->{attributes}->{export_manager_id}->{options} = \@expmanageroptions;

    # If the manager id not defined or the defined value not in options
    # so use the first options as selected value.
    if (not defined $args{export_manager_id} or not defined $manager_options->{$args{export_manager_id}}) {
        $args{export_manager_id} = $attributes->{attributes}->{export_manager_id}->{options}[0]->{pk};
    }

    # Get the export manager params from the selected export manager
    my $exportmanager = Entity->get(id => $args{export_manager_id});
    $managerparams = $exportmanager->getExportManagerParams();
    for my $attrname (keys %{$managerparams}) {
        $attributes->{attributes}->{$attrname} = $managerparams->{$attrname};
        push @{ $attributes->{displayed} }, $attrname;
    }

    $self->setValues(attributes          => $attributes,
                     values              => \%args,
                     set_mandatory       => delete $args{set_mandatory},
                     set_editable        => delete $args{set_editable},
                     set_params_editable => delete $args{set_params_editable});

    return $attributes;
}

sub getNonEditableAttributes {
    my ($self, %args) = @_;

    my $definition = $self->SUPER::getNonEditableAttributes();

    # Add the host_provider_id as a non editable attr if host_manager_id
    # defined as as a non editable attr.
    if (defined $definition->{disk_manager_id} or defined $definition->{export_manager_id}) {
        $definition->{storage_provider_id} = 1;
    }
    return $definition;
}

1;
