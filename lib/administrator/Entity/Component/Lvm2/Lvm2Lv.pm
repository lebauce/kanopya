#    Copyright © 2011 Hedera Technology SAS
#
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

package Entity::Component::Lvm2::Lvm2Lv;
use base BaseDB;

use Entity::Component::Lvm2::Lvm2Vg;
use Entity::Container::LvmContainer;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    lvm2_vg_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
    lvm2_lv_name => {
        label        => 'Name',
        type         => 'string',
        is_mandatory => 1,
        is_editable  => 0,
    },
    lvm2_lv_freespace => {
        label        => 'Free space',
        type         => 'string',
        unit         => 'byte',
        is_mandatory => 0,
        is_editable  => 0,
    },
    lvm2_lv_size => {
        label        => 'Total size',
        type         => 'string',
        unit         => 'byte',
        is_mandatory => 1,
        is_editable  => 0,
    },
    lvm2_lv_filesystem => {
        label        => 'Filesystem',
        type         => 'string',
        is_mandatory => 1,
        is_editable  => 0,
    },
    container_device => {
        label        => 'Device',
        type         => 'string',
        is_virtual   => 1,
        is_editable  => 0,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub create {
    my ($class, %args) = @_;

    $class->checkAttrs(attrs => \%args);

    my $vg = Entity::Component::Lvm2::Lvm2Vg->get(id => $args{lvm2_vg_id});
    $vg->lvm2->createDisk(vg_id      => $args{lvm2_vg_id},
                          name       => $args{lvm2_lv_name},
                          size       => $args{lvm2_lv_size},
                          filesystem => $args{lvm2_lv_filesystem});
}

sub remove {
    my ($self, %args) = @_;

    $self->lvm2_vg->lvm2->removeDisk(
        container => Entity::Container::LvmContainer->find(hash => { lv_id => $self->id })
    );
}

sub containerDevice {
    my ($self, %args) = @_;

    return Entity::Container::LvmContainer->find(hash => { lv_id => $self->id })->container_device;
}


1;
