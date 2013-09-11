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

use constant POLICY_SELECTOR_ATTR_DEF => {
    storage_provider_id => {
        label        => 'Data store',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
    },
};

use constant POLICY_SELECTOR_MAP => {
    storage_provider_id => [ 'disk_manager_id' ],
    disk_manager_id     => [ 'export_manager_id' ]
};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }
sub getPolicySelectorAttrDef { return POLICY_SELECTOR_ATTR_DEF; }
sub getPolicySelectorMap { return POLICY_SELECTOR_MAP; }

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod
=begin classdoc

Build the dynamic attributes definition depending on attributes
values given in parameters.

@return the dynamic attributes definition.

=end classdoc
=cut

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attributes' ],
                         optional => { 'params' => {}, 'trigger' => undef });

    # Add the dynamic attributes to displayed
    push @{ $args{attributes}->{displayed} }, 'storage_provider_id';
    push @{ $args{attributes}->{displayed} }, 'disk_manager_id';

    # Build the storage provider list
    my $providers = {};
    for my $component ($class->searchManagers(component_category => 'DiskManager')) {
        $providers->{$component->service_provider->id} = $component->service_provider->toJSON;
    }
    my @storageproviders = values %{$providers};
    $args{attributes}->{attributes}->{storage_provider_id}->{options} = \@storageproviders;

    # If storage_provider_id not defined, select it from the disk manager or
    # select the first one.
    if (! $args{params}->{storage_provider_id}) {
        if ($args{params}->{disk_manager_id}) {
            $args{params}->{storage_provider_id}
                = Entity->get(id => $args{params}->{disk_manager_id})->service_provider->id;
        }
        elsif ($args{set_mandatory}) {
            $self->setFirstSelected(name       => 'storage_provider_id',
                                    attributes => $args{attributes}->{attributes},
                                    params     => $args{params});
        }
    }

    # Build the list of disk manager of the storage provider
    if ($args{params}->{storage_provider_id}) {
        my $manager_options = {};
        my @managers = $class->searchManagers(component_category  => 'DiskManager',
                                              service_provider_id => $args{params}->{storage_provider_id});

        for my $component (@managers) {
            $manager_options->{$component->id} = $component->toJSON;
            $manager_options->{$component->id}->{label} = $component->disk_type;
        }
        my @diskmanageroptions = values %{$manager_options};
        $args{attributes}->{attributes}->{disk_manager_id}->{options} = \@diskmanageroptions;

        # If disk_manager_id defined but do not corresponding to a available value,
        # it is an old value, so delete it.
        if (not $manager_options->{$args{params}->{disk_manager_id}}) {
            delete $args{params}->{disk_manager_id};
        }
        # If no disk_manager_id defined and and attr is mandatory, use the first one as value
        if (! $args{params}->{disk_manager_id} && $args{set_mandatory}) {
            $self->setFirstSelected(name       => 'disk_manager_id',
                                    attributes => $args{attributes}->{attributes},
                                    params     => $args{params});
        }
    }

    if ($args{params}->{disk_manager_id}) {
        # Get the disk manager params from the selected disk manager
        my $diskmanager = Entity->get(id => $args{params}->{disk_manager_id});
        my $managerparams = $diskmanager->getDiskManagerParams();
        for my $attrname (keys %{$managerparams}) {
            $args{attributes}->{attributes}->{$attrname} = $managerparams->{$attrname};
            # If no value defined in params, use the first one
            if (! $args{params}->{$attrname} && $args{set_mandatory}) {
                $self->setFirstSelected(name       => $attrname,
                                        attributes => $args{attributes}->{attributes},
                                        params     => $args{params});
            }
            push @{ $args{attributes}->{displayed} }, $attrname;
        }

        # Once the disk manager parameters added, handle the export manager and its params
        push @{ $args{attributes}->{displayed} }, 'export_manager_id';

        # Build the list of export manager usable for the disk manager
        my $manager_options = {};
        for my $component (@{ $diskmanager->getExportManagers }) {
            $manager_options->{$component->id} = $component->toJSON;
            $manager_options->{$component->id}->{label} = $component->export_type;
        }
        my @expmanageroptions = values %{$manager_options};
        $args{attributes}->{attributes}->{export_manager_id}->{options} = \@expmanageroptions;

        # TODO: factorize the code that handle the export manager as it is
        #       the as the disk manager one.

        # If export_manager_id defined but do not corresponding to a available value,
        # it is an old value, so delete it.
        if (not $manager_options->{$args{params}->{export_manager_id}}) {
            delete $args{params}->{export_manager_id};
        }
        # If no export_manager_id defined and and attr is mandatory, use the first one as value
        if (! $args{params}->{export_manager_id} and $args{set_mandatory}) {
            $self->setFirstSelected(name       => 'export_manager_id',
                                    attributes => $args{attributes}->{attributes},
                                    params     => $args{params});
        }

        if ($args{params}->{export_manager_id}) {
            # Get the export manager params from the selected export manager
            my $exportmanager = Entity->get(id => $args{params}->{export_manager_id});
            $managerparams = $exportmanager->getExportManagerParams(params => $args{params});
            for my $attrname (keys %{$managerparams}) {
                $args{attributes}->{attributes}->{$attrname} = $managerparams->{$attrname};
                # If no value defined in params, use the first one
                if (! $args{params}->{$attrname} && $args{set_mandatory}) {
                    $self->setFirstSelected(name       => $attrname,
                                            attributes => $args{attributes}->{attributes},
                                            params     => $args{params});
                }
                push @{ $args{attributes}->{displayed} }, $attrname;
            }
        }
    }
    # Remove possibly defined value of attributes that depends on disk_manager_id.
    # (It is probably a first implementation of the full generic version of
    # manager management in policies...)
    else {
        for my $dependency (@{ $self->getPolicySelectorMap->{disk_manager_id} }) {
            delete $args{params}->{$dependency};
        }
    }

    return $args{attributes};
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
    # or export_manager_id defined as a non editable attr.
    if (defined $definition->{disk_manager_id} or defined $definition->{export_manager_id}) {
        $definition->{storage_provider_id} = 1;
    }
    return $definition;
}

=pod

=begin classdoc

Remove possibly defined storage_provider_id from params, as it is a
field convenient for manager selection only.

@return a policy pattern fragment

=end classdoc

=cut

sub getPatternFromParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    delete $args{params}->{storage_provider_id};

    return $self->SUPER::getPatternFromParams(params => $args{params});
}

1;
