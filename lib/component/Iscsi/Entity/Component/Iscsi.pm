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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package Entity::Component::Iscsi;
use base "Entity::Component";
use base "Manager::ExportManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use IscsiPortal;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    iscsi_portals => {
        label        => 'ISCSI portals',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
    },
    export_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {}

sub exportType {
    return "Unmanaged ISCSI target";
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        iscsi_portals => {
            label        => 'ISCSI portals to use',
            type         => 'enum',
            relation     => 'multi',
            is_mandatory => 1,
        },
        target => {
            label        => 'ISCSI target name',
            type         => 'string',
            pattern      => '^.*$',
            is_mandatory => 1,
        },
        lun => {
            label        => 'LUN number',
            type         => 'integer',
            pattern      => '^\d+$',
            is_mandatory => 1,
        },
    };
}

sub checkExportManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "iscsi_portals", "target", "lun" ]);
}


=pod
=begin classdoc

@return the managers parameters as an attribute definition. 

=end classdoc
=cut

sub getExportManagerParams {
    my $self = shift;
    my %args  = @_;

    my $definition = $self->getManagerParamsDef();
    $definition->{iscsi_portals}->{options} = {};

    for my $portal (@{ $self->getConf->{iscsi_portals} }) {
        $definition->{iscsi_portals}->{options}->{$portal->{iscsi_portal_id}}
            = $portal->{iscsi_portal_ip} . ':' . $portal->{iscsi_portal_port};
    }

    return {
        iscsi_portals => $definition->{iscsi_portals},
        target        => $definition->{target},
        lun           => $definition->{lun},
    };
}

sub getConf {
    my $self = shift;
    my $conf = {};
    my @portals = ();

    for my $portal ($self->iscsi_portals) {
        push @portals, { iscsi_portal_ip   => $portal->iscsi_portal_ip,
                         iscsi_portal_port => $portal->iscsi_portal_port,
                         iscsi_portal_id   => $portal->iscsi_portal_id,
                         iscsi_id          => $self->id };
    }

    $conf->{iscsi_portals} = \@portals;
    return $conf;
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'conf' ]);

    my $conf = $args{conf};
    my $configured = {};
    for my $portal (@{ $conf->{iscsi_portals} }) {
        my $portal_id = $portal->{iscsi_portal_id};
        if (not $portal_id) {
            $portal_id = IscsiPortal->new(
                             iscsi_id          => $self->id,
                             iscsi_portal_ip   => $portal->{iscsi_portal_ip},
                             iscsi_portal_port => $portal->{iscsi_portal_port},
                         )->id;
        }
        $configured->{$portal_id} = 1;
    }
    for my $existing ($self->iscsi_portals) {
        if (not defined $configured->{$existing->id}) {
            $existing->remove();
        }
    }
}


=pod
=begin classdoc

Insert default configuration in db for this component. 

=end classdoc
=cut

sub insertDefaultExtendedConfiguration {
    my $self = shift;

    for my $node ($self->component_nodes) {
        IscsiPortal->new(
            iscsi_id          => $self->id,
            iscsi_portal_ip   => $node->node->host->adminIp,
            iscsi_portal_port => 3260
        );
    }
}

sub getNetConf {
    return {
        iscsid => {
            port => 3260,
            protocols => ['tcp']
        }
    };
}

sub getReadOnlyParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'readonly' ]);

    my $value;
    if ($args{readonly}) { $value = 'ro'; }
    else                 { $value = 'wb'; }
    return {
        name  => 'iomode',
        value => $value,
    }
}

1;
