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


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        %{ $self->SUPER::getManagerParamsDef },
        cpu => {
            label        => 'Required CPU number',
            type         => 'integer',
            unit         => 'core(s)',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        ram => {
            label        => 'Required RAM amount',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        tags => {
            label        => 'Tags',
            type         => 'enum',
            relation     => 'multi',
            is_mandatory => 0,
        }
    };
}

sub getHostManagerParams {
    my $self = shift;
    my %args = @_;

    my $definition = $self->getManagerParamsDef();
    $definition->{tags}->{options} = {};

    my @tags = Entity::Tag->search();
    for my $tag (@tags) {
        $definition->{tags}->{options}->{$tag->id} = $tag->tag;
    }

    return {
        cpu  => $definition->{cpu},
        ram  => $definition->{ram},
        tags => $definition->{tags},
    };
}

sub getConf {
    return {};
}

sub setConf {
}

sub getRemoteSessionURL {
    return "";
}

1;
