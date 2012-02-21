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

package Entity::Vlan;
use base "Entity";

use constant ATTR_DEF => {
	vlan_name			=> { pattern        => '^\w*$',
							 is_mandatory   => 1,                               
                             is_extended    => 0,
                             is_editable    => 0,
                           },
    vlan_desc			=> { pattern      => '^.*$',
							 is_mandatory => 0,
							 is_extended  => 0,
							 is_editable  => 1,
						   },
                           
    vlan_number			=> { pattern      => '^\d*$',
							 is_mandatory => 1,
							 is_extended  => 0,
							 is_editable  => 0,
							 },
};
sub methods {
    return {
        'create'    => {'description' => 'create a new vlan',
                        'perm_holder' => 'mastergroup',
        },
        'associateVlanpoolip'        => {'description' => 'update vlanpoolip by adding vlan_id, poolipid',
                        'perm_holder' => 'entity',
        },
        'getassociatedPoolip'    => {'description' => 'return list of poolip_id soociated to vlan',
                        'perm_holder' => 'entity',
        },
        'removePoolip'    => {'description' => 'dissociate a pool ip from a  vlan',
                        'perm_holder' => 'entity',
        },
         'remove'    => {'description' => 'remove a vlan ',
                        'perm_holder' => 'entity',
        },
       
    };
}
sub getAttrDef { return ATTR_DEF; }
sub getVlans {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}
=head2 create

=cut

sub create {
    my $self = shift;
    my $admin = Administrator->new();
    $self->save();
}
=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('vlan_desc');
    return $string;
}
=head2 create
desc:associate poolip to vlan
=cut

sub associateVlanpoolip {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['vlan_id','poolip_id']);

    my $adm = Administrator->new();
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'associateVlanpoolip');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to associate pool ip to this vlan");
    }
    my $res =$adm->{db}->resultset('VlanPoolip')->create(
		{	poolip_id=>$args{poolip_id},
            vlan_id =>$self->getAttr(name=>'vlan_id')
        }
    );

    return $res->get_column("poolip_id");
}

=head2 create
desc:get list of pool ip id associated to a vlan
=cut

sub getassociatedPoolip {
    my $self = shift;
    my $pips = [];
    my $poolips = $self->{_dbix}->vlan_poolips;
    while(my $pip = $poolips->next) {
        my $tmp = {};
        $tmp->{poolip_id}       = $pip->get_column('poolip_id');
        
        push @$pips, $tmp;
    }
    return $pips;

}
=head2 create
desc:dessociate a pool ip from vlan without deleting it from pool ip list 
=cut
sub removePoolip {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['poolip_id']);

    my $adm = Administrator->new();
    # removePoolip method concerns an existing entity so we use his entity_id
  # my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'removePoolip');
   # if(not $granted) {
    #    throw Kanopya::Exception::Permission::Denied(error => "Permission denied to remove a pool ip from this vlan");
    #}
  # 
    my $pip=$adm->{db}->resultset('VlanPoolip')->search(undef, {
    columns => [qw/poolip_id/]
      });
    $pip->delete();
}
1;
