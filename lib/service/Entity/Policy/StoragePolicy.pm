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

use Entity::Component;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use Clone qw(clone);

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

use constant POLICY_ATTR_DEF => {
    storage_manager_id => {
        label        => "Storage type",
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
    },
};

use constant POLICY_SELECTOR_ATTR_DEF => {};

use constant POLICY_SELECTOR_MAP => {};

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
    push @{ $args{attributes}->{displayed} }, 'storage_manager_id';

    # Build the list of storage managers
    my $manager_options = {};
    for my $component (Entity::Component->search(custom => { category => 'StorageManager' })) {
        $manager_options->{$component->id} = $component->toJSON;
        $manager_options->{$component->id}->{label} = $component->label;
    }
    my @manageroptions = values %{$manager_options};
    $args{attributes}->{attributes}->{storage_manager_id}->{options} = \@manageroptions;

    # If storage_manager_id defined but do not corresponding to a available value,
    # it is an old value, so delete it.
    if (not $manager_options->{$args{params}->{storage_manager_id}}) {
        delete $args{params}->{storage_manager_id};
    }
    # If no disk_manager_id defined and and attr is mandatory, use the first one as value
    if (! $args{params}->{storage_manager_id} && $args{set_mandatory}) {
        $self->setFirstSelected(name       => 'storage_manager_id',
                                attributes => $args{attributes}->{attributes},
                                params     => $args{params});
    }

    if ($args{params}->{storage_manager_id}) {
        # Get the storage manager params from the selected storage manager
        my $storagemanager = Entity->get(id => $args{params}->{storage_manager_id});
        my $managerparams = $storagemanager->getStorageManagerParams(params => $args{params});

        for my $attrname (keys %{ $managerparams }) {
            $args{attributes}->{attributes}->{$attrname} = $managerparams->{$attrname};
            # If no value defined in params, use the first one
            if (! $args{params}->{$attrname} && $args{set_mandatory}) {
                $self->setFirstSelected(name       => $attrname,
                                        attributes => $args{attributes}->{attributes},
                                        params     => $args{params});
            }

            # If the attribute is a manager, set it as reload trigger as
            # it probably hav specific params too
            if ($attrname =~ m/.*_manager_id/) {
                $args{attributes}->{attributes}->{$attrname}->{reload} = 1;
            }

            # Add the attribute to the displayed list
            push @{ $args{attributes}->{displayed} }, $attrname;
        }
    }
    # Remove possibly defined value of attributes that depends on disk_manager_id.
    # (It is probably a first implementation of the full generic version of
    # manager management in policies...)
    else {
        for my $dependency (@{ $self->getPolicySelectorMap->{storage_manager_id} }) {
            delete $args{params}->{$dependency};
        }
    }
    return $args{attributes};
}

1;
