 # Copyright © 2014 Hedera Technology SAS
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

HCM native network manager.
Configure the nodes network insterface using the HCM lib based on
ifaces, interfaces, netconfs, poolip and networks.

=end classdoc
=cut

package Entity::Component::HCMNetworkManager;
use parent Entity::Component;
use parent Manager::NetworkManager;

use strict;
use warnings;

use Entity::Component;
use Kanopya::Exceptions;

use TryCatch;
use Hash::Merge;
use Date::Simple (':all');
use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    network_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }


my $merge = Hash::Merge->new();


=pod
=begin classdoc

@return the storage type description.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub networkType {
    my ($self, %args) = @_;

    return "HCM network manager";
}


=pod
=begin classdoc

@return the component label

=end classdoc
=cut

sub label {
    my ($self, %args) = @_;

    return $self->networkType;
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    my @boot_policies = values(Manager::HostManager->BOOT_POLICIES);
    return {
        # TODO: call super on all Manager supers
        %{ $self->SUPER::getManagerParamsDef },
        interfaces => {
            label        => 'Interfaces',
            type         => 'relation',
            relation     => 'single_multi',
            # is_editable  => 1,
            is_mandatory => 1,
            attributes   => {
                attributes => {
                    policy_id => {
                        type     => 'relation',
                        relation => 'single',
                    },
                    netconfs => {
                        label       => 'Network configurations',
                        type        => 'relation',
                        relation    => 'multi',
                        link_to     => 'netconf',
                        pattern     => '^\d*$',
                        is_editable => 1,
                    },
                    bonds_number => {
                        label       => 'Bonding slave count',
                        type        => 'integer',
                        pattern     => '^\d*$',
                        is_editable => 1,
                    },
                    interface_name => {
                        label        => 'Name',
                        type         => 'string',
                        pattern      => '^.*$',
                        is_editable  => 1,
                        is_mandatory => 1,
                    },
                },
            },
        }
    };
}


=pod
=begin classdoc

@return the managers parameters as an attribute definition. 

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub getNetworkManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { "params" => {} });

    my $paramdef = $self->getManagerParamsDef();

    my @netconfs;
    for my $netconf (Entity::Netconf->search(hash => {})) {
        push @netconfs, $netconf->toJSON();
    }

    $paramdef->{interfaces}->{attributes}->{attributes}->{netconfs}->{options}
        = \@netconfs;

    return $paramdef;
}


=pod
=begin classdoc

Check params required for creating disks.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub checkNetworkManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "interfaces" ]);
}


=pod
=begin classdoc

Not supported.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub ApplyVLAN {
    my ($self, %args) = @_;

    $log->warn("ApplyVLAN not supported by network manager " . $self->label);
}

1;
