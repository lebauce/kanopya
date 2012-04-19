# Entity::Vlan.pm  

#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 16 july 2010

=head1 NAME

Entity::Vlan

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::Network;
use base "Entity";

use Entity::Poolip;

use constant ATTR_DEF => {
    network_name => {
        pattern      => '^\w*$',
        is_mandatory => 1,                               
        is_extended  => 0,
        is_editable  => 0,
    },
};

sub methods {
    return {
        'associatePoolip' => {
            'description' => 'update network_poolip by adding network_id, poolipid',
            'perm_holder' => 'entity',
        },
        'getassociatedPoolip' => {
            'description' => 'return list of poolip_id soociated to network',
            'perm_holder' => 'entity',
        },
        'dissociatePoolip' => {
            'description' => 'dissociate a pool ip from a network',
            'perm_holder' => 'entity',
        },
    };
}

sub getAttrDef { return ATTR_DEF; }


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('network_name');
    return $string;
}

=head2 associatePoolip

    desc:associate poolip to vlan

=cut

sub associatePoolip {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'poolip' ]);

    my $adm = Administrator->new();
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id},
                                                   method    => 'associatePoolip');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to associate pool ip to this network");
    }
    my $res = $self->getNetworksPoolipsDbix->create({
                  poolip_id  => $args{poolip}->getAttr(name => 'entity_id'),
                  network_id => $self->getAttr(name => 'entity_id')
              });
}

=head2 getAssociatedPoolips

    desc:get list of pool ip id associated to a vlan

=cut

sub getAssociatedPoolips {
    my $self = shift;

    my $pips = [];
    my $poolips = $self->getNetworksPoolipsDbix;
    while(my $poolip = $poolips->next) {
        my $tmp = Entity::Poolip->get(id => $poolip->get_column('poolip_id'));
        push @$pips, $tmp;
    }
    return $pips;
}

=head2 dissociatePoolip

    desc:dessociate a pool ip from vlan without deleting it from pool ip list 

=cut

sub dissociatePoolip {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'poolip' ]);

    my $adm = Administrator->new();
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id},
                                                   method    => 'dissociatePoolip');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to dissociate pool ip to this network");
    }

    $self->getNetworksPoolipsDbix->search({
        poolip_id => $args{poolip}->getAttr(name => 'entity_id')
    })->single()->delete();
}

sub getNetworksPoolipsDbix {
    my $self = shift;
    return $self->{_dbix}->network_poolips;
}

1;
