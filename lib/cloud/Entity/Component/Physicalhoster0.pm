# Copyright © 2012 Hedera Technology SAS
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

package Entity::Component::Physicalhoster0;
use base "Entity::Component";
use base "Manager::HostManager";

use strict;
use warnings;

use Manager::HostManager;
use Kanopya::Exceptions;
use Entity::Tag;

use Log::Log4perl "get_logger";
use Data::Dumper;
use IO::Socket;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
    # TODO: move this virtual attr to HostManager attr def when supported
    host_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{pxe_iscsi},
            Manager::HostManager->BOOT_POLICIES->{pxe_nfs});
}

sub hostType {
    return "Physical host";
}

sub getConf {
    return {};
}

sub setConf {
}

sub getHostManagerParams {
    my $self = shift;
    my %args = @_;

    my $definition = $self->getManagerParamsDef();
    $definition->{tags}->{options} = {};
    $definition->{no_tags}->{options} = {};

    my @tags = Entity::Tag->search();
    for my $tag (@tags) {
        $definition->{tags}->{options}->{$tag->id} = $tag->tag;
        $definition->{no_tags}->{options}->{$tag->id} = $tag->tag;
    }

    return {
        cpu     => $definition->{cpu},
        ram     => $definition->{ram},
        tags    => $definition->{tags},
        no_tags => $definition->{no_tags},

    };
}

sub checkHostManagerParams {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ "cpu", "ram" ]);
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        cpu => {
            label        => 'Required CPU number',
            type         => 'integer',
            unit         => 'core(s)',
            pattern      => '^\d*$',
            is_mandatory => 1,
            order        => 1,
            description  => 'Required number of CPU cores',
        },
        ram => {
            label        => 'Required RAM amount',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 1,
            description  => 'Required amount of RAM',
            order        => 2,
        },
        tags => {
            label        => 'Mandatory Tags',
            type         => 'enum',
            relation     => 'multi',
            is_mandatory => 0,
            order        => 3,
            description  => 'HCM offers a tag system to filter resources. You can filter per datacenter'.
                            ' or per users or per functionalities. Mandatory tags are inclusive tags.',
        },
        no_tags => {
            label        => 'Forbidden Tags',
            type         => 'enum',
            relation     => 'multi',
            is_mandatory => 0,
            order        => 4,
            description  => 'HCM offers a tag system to filter resources. You can filter per datacenter '.
                            'or per users or per functionalities. Forbidden tags are exclusive tags.',
        },
    };
}

sub getRemoteSessionURL {
    return "";
}

1;
