# Hostmodel.pm - This object allows to manipulate Host model
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
# Created 11 aug 2010
package Entity::Hostmodel;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use General;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    hostmodel_brand         => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_name          => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_chipset       => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_processor_num => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_consumption   => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_iface_num     => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_ram_slot_num  => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_ram_max       => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    processormodel_id              => { pattern => '\d*', is_mandatory => 0, is_extended => 0 },
};

sub methods {
    return {
        'create'    => {'description' => 'create a new host model', 
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this host model', 
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this host model', 
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this host model', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this host model', 
                        'perm_holder' => 'entity',
        },
    }; 
}

=head2 getHostmodels

=cut

sub getHostmodels {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

=head2 create

=cut

sub create {
    my $self = shift;
    my $adm = Administrator->new();
    my $mastergroup_eid = $self->getMasterGroupEid();
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new hostmodel");
    }
    
    $self->save();
}

=head2 update

=cut 

sub update {}

=head2 remove

=cut

sub remove {
    my $self = shift;
    my $adm = Administrator->new();
    # delete method concerns an existing entity so we use his entity_id
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'remove');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to delete this host model");
    }
    $self->SUPER::delete();
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('hostmodel_name')." ".$self->{_dbix}->get_column('hostmodel_brand');
    return $string;
}

sub getAttrDef{
    return ATTR_DEF;
}
1;
