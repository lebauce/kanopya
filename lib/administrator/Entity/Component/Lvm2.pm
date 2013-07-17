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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package Entity::Component::Lvm2;
use base "Entity::Component";
use base "Manager::DiskManager";

use strict;
use warnings;

use General;

use Manager::HostManager;
use Entity::ServiceProvider;
use Entity::Container::LvmContainer;
use Entity::Component::Lvm2::Lvm2Pv;
use Kanopya::Exceptions;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    lvm2_vgs => {
        label        => 'Volume groups',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
    },
    disk_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub diskType {
    return "LVM logical volume";
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
        vg_id => {
            label        => 'Volume group to use',
            type         => 'enum',
            is_mandatory => 1,
        },
    };
}


=pod
=begin classdoc

Check params required for creating disks.

=end classdoc
=cut

sub checkDiskManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "vg_id", "systemimage_size" ]);
}


=pod
=begin classdoc

@return the managers parameters as an attribute definition. 

=end classdoc
=cut

sub getDiskManagerParams {
    my $self = shift;
    my %args  = @_;

    my $vgparam = $self->getManagerParamsDef->{vg_id};
    $vgparam->{options} = {};

    for my $vg (@{ $self->getConf->{lvm2_vgs} }) {
       $vgparam->{options}->{$vg->{lvm2_vg_id}} = $vg->{lvm2_vg_name};
    }
    return { vg_id => $vgparam };
}

sub getMainVg {
    my $self = shift;

    my @vgs = $self->lvm2_vgs;
    return shift @vgs;
}

sub lvCreate{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "lvm2_lv_name", "lvm2_lv_size",
                                       "lvm2_lv_filesystem", "lvm2_vg_id" ]);

    eval{
        my ($value, $unit) = General::convertSizeFormat(size => $args{lvm2_lv_size});
        $args{lvm2_lv_size} = General::convertToBytes(value => $value, units => $unit);
    };
    if ($@) {
        $log->debug("Given size $args{lvm2_lv_size} is already in bytes.");
    }

    $log->debug("lvm2_lv_name is $args{lvm2_lv_name}, " .
                "lvm2_lv_size is $args{lvm2_lv_size}, " .
                "lvm2_lv_filesystem is $args{lvm2_lv_filesystem}, " .
                "lvm2_vg_id is $args{lvm2_vg_id}");

    my $vg_rs = $self->{_dbix}->lvm2_vgs->single({ lvm2_vg_id => $args{lvm2_vg_id} });
    my $res   = $vg_rs->lvm2_lvs->create(\%args);

    $log->debug("lvm2 logical volume $args{lvm2_lv_name} saved to database");

    $res->discard_changes;
    my $container = Entity::Container::LvmContainer->new(
                        disk_manager_id      => $self->getAttr(name => 'entity_id'),
                        container_name       => $res->get_column('lvm2_lv_name'),
                        container_size       => $res->get_column('lvm2_lv_size'),
                        container_filesystem => $res->get_column('lvm2_lv_filesystem'),
                        container_freespace  => $res->get_column('lvm2_lv_freespace'),
                        container_device     => '/dev/' . $vg_rs->get_column('lvm2_vg_name') .
                                                '/' . $res->get_column('lvm2_lv_name'),
                        lv_id                => $res->get_column("lvm2_lv_id"),
                    );

    return $container;
}

sub vgSizeUpdate{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "lvm2_vg_id", "lvm2_vg_freespace" ]);

    my $vg_rs = $self->{_dbix}->lvm2_vgs->single( {lvm2_vg_id => $args{lvm2_vg_id}});
    delete $args{lvm2_vg_id};

    $log->debug("Volume group freespace size update");
    return $vg_rs->update(\%args);
}

sub lvRemove{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "lvm2_lv_name", "lvm2_vg_id" ]);

    $log->debug("lvm2_lv_name is $args{lvm2_lv_name}, lvm2_vg_id is $args{lvm2_vg_id}");

    my $vg_row = $self->{_dbix}->lvm2_vgs->find($args{lvm2_vg_id});
    my $lv_row = $vg_row->lvm2_lvs->single({ lvm2_lv_name => $args{lvm2_lv_name} });
    $lv_row->delete();

    $log->info("lvm2 logical volume $args{lvm2_lv_name} deleted from database");
}

sub getConf {
    my $self = shift;

    my @lvm2_vgs = $self->lvm2_vgs;
    my @volumegroups = map {
        my $vg   = $_;
        my $json = $vg->toJSON(raw => 1);

        my @lvm2_lvs = $vg->lvm2_lvs;
        my @logicalvolumes = map { $_->toJSON(raw => 1) } @lvm2_lvs;
        $json->{lvm2_lvs} = \@logicalvolumes;

        my @lvm2_pvs = $vg->lvm2_pvs;
        my @physical_volumes = map { $_->toJSON(raw => 1) } @lvm2_pvs;
        $json->{lvm2_pvs} = \@physical_volumes;

        $json;
    } @lvm2_vgs;

    return {
        lvm2_vgs => \@volumegroups
    };
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'conf' ]);

    my $conf = $args{conf};
    for my $vg ( @{ $conf->{lvm2_vgs} }) {
        for my $new_lv ( @{ $vg->{lvm2_lvs} }) {
            if (keys %$new_lv and not $new_lv->{lvm2_lv_id}) {
                $self->createDisk(
                    name       => $new_lv->{lvm2_lv_name},
                    size       => $new_lv->{lvm2_lv_size},
                    filesystem => $new_lv->{lvm2_lv_filesystem},
                    vg_id      => $new_lv->{lvm2_vg}
                );
            }
        }

        delete $vg->{lvm2_lvs};
    }

    $self->SUPER::setConf(%args);
}

sub getExportManagerFromBootPolicy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "boot_policy" ]);

    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));

    if ($args{boot_policy} eq Manager::HostManager->BOOT_POLICIES->{pxe_iscsi}) {
        return $cluster->getComponent(name => "Iscsitarget", version => "1");
    }
    elsif ($args{boot_policy} eq Manager::HostManager->BOOT_POLICIES->{pxe_nfs}) {
        return $cluster->getComponent(name => "Nfsd", version => "3");
    }
    
    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported boot policy: $args{boot_policy}"
          );
}

sub getBootPolicyFromExportManager {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "export_manager" ]);

    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));

    if ($args{export_manager}->getId == $cluster->getComponent(name => "Iscsitarget", version => "1")->getId) {
        return Manager::HostManager->BOOT_POLICIES->{pxe_iscsi};
    }
    elsif ($args{export_manager}->getId == $cluster->getComponent(name => "Nfsd", version => "3")->getId) {
        return Manager::HostManager->BOOT_POLICIES->{pxe_nfs};
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported export manager:" . $args{export_manager}
          );
}

sub getExportManagers {
    my $self = shift;
    my %args = @_;

    my $cluster = $self->service_provider;

    return [ $cluster->getComponent(name => "Iscsitarget", version => "1"),
             $cluster->getComponent(name => "Nfsd", version => "3") ];
}


sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "vg_id", "name", "size", "filesystem" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateDisk',
        params   => {
            name       => $args{name},
            size       => $args{size},
            filesystem => $args{filesystem},
            vg_id      => $args{vg_id},
            context    => {
                disk_manager => $self,
            }
        },
    );
}


sub getFreeSpace {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'vg_id' => undef });

    my $vg = $args{vg_id} ? Entity::Component::Lvm2::Lvm2Vg->get(id => $args{vg_id})
                          : $self->getMainVg;

    return $vg->lvm2_vg_freespace;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;
    my $manifest = "";

    $manifest .= $self->instanciatePuppetResource(
        name => 'kanopya::lvm',
    );

    for my $vg ($self->lvm2_vgs) {
        my @pvs = ();
        for my $pv ($vg->lvm2_pvs) {
            $manifest .= $self->instanciatePuppetResource(
                resource => 'physical_volume',
                name => $pv->lvm2_pv_name,
                params => {
                    ensure => 'present',
                    tag => 'kanopya::lvm'
                }
            );

            push @pvs, $pv->lvm2_pv_name;
        }

        $manifest .= $self->instanciatePuppetResource(
            resource => 'volume_group',
            name => $vg->lvm2_vg_name,
            params => {
                ensure => 'present',
                physical_volumes => \@pvs,
                tag => 'kanopya::lvm'
            }
        );
    }

    return merge($self->SUPER::getPuppetDefinition(%args), {
        lvm => {
            manifest => $manifest
        }
    } );
}

1;
