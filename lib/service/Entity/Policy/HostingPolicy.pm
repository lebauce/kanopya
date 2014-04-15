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

use Entity::Component;

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

use constant POLICY_SELECTOR_ATTR_DEF => {};

use constant POLICY_SELECTOR_MAP => {};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }
sub getPolicySelectorAttrDef { return POLICY_SELECTOR_ATTR_DEF; }
sub getPolicySelectorMap { return POLICY_SELECTOR_MAP; }

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


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
    push @{ $args{attributes}->{displayed} }, 'host_manager_id';

    # Build the list of host managers
    my $manager_options = {};
    for my $component (Entity::Component->search(custom => { category => 'HostManager' })) {
        $manager_options->{$component->id} = $component->toJSON;
        $manager_options->{$component->id}->{label} = $component->host_type;
    }
    my @options = values %{ $manager_options };
    $args{attributes}->{attributes}->{host_manager_id}->{options} = \@options;

    # If host_manager_id defined but do not corresponding to a available value,
    # it is an old value, so delete it.
    if (not defined $manager_options->{$args{params}->{host_manager_id}}) {
        delete $args{params}->{host_manager_id};
    }
    # If no host_manager_id defined and and attr is mandatory, use the first one as value
    if (! defined $args{params}->{host_manager_id} and $args{set_mandatory}) {
        $self->setFirstSelected(name       => 'host_manager_id',
                                attributes => $args{attributes}->{attributes},
                                params     => $args{params});
    }

    if (defined $args{params}->{host_manager_id}) {
        # Get the host manager params from the selected host manager
        my $hostmanager = Entity->get(id => $args{params}->{host_manager_id});
        my $managerparams = $hostmanager->getHostManagerParams();
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

    return $args{attributes};
}

1;
