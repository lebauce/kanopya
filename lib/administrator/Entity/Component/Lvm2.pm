# Lvm2.pm Logical volume manager component (Adminstrator side)
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
# Created 22 august 2010
=head1 NAME

<Entity::Component::Lvm2> <Lvm2 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Lvm2> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Lvm2>;

my $component_instance_id = 2; # component instance id

Entity::Component::Lvm2->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Lvm2->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Lvm2 is class allowing to instantiate an Lvm2 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Lvm2;
use base "Entity::Component";

use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Entity::HostManager;
use Entity::ServiceProvider;
use Entity::Container::LvmContainer;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

sub getMainVg {
    my $self = shift;

    my $vgname = $self->{_dbix}->lvm2_vgs->single->get_column('lvm2_vg_name');
    my $vgid = $self->{_dbix}->lvm2_vgs->single->get_column('lvm2_vg_id');
    $log->debug("Main VG founds, its id is <$vgid>");
    #TODO getMainVg, return id or name ?
    return {vgid => $vgid, vgname =>$vgname};
}

sub getVg {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => [ "lvm2_vg_id" ]);

    return  $self->{_dbix}->lvm2_vgs->find($args{lvm2_vg_id})->get_column('lvm2_vg_name');
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
        $log->info("Given size $args{lvm2_lv_size} is already in bytes.");
    }

    $log->debug("lvm2_lv_name is $args{lvm2_lv_name}, " .
                "lvm2_lv_size is $args{lvm2_lv_size}, " .
                "lvm2_lv_filesystem is $args{lvm2_lv_filesystem}, " .
                "lvm2_vg_id is $args{lvm2_vg_id}");

    my $lv_rs = $self->{_dbix}->lvm2_vgs->single({ lvm2_vg_id => $args{lvm2_vg_id} })->lvm2_lvs;
    my $res = $lv_rs->create(\%args);

    $log->info("lvm2 logical volume $args{lvm2_lv_name} saved to database");

    $res->discard_changes;
    return $res->get_column("lvm2_lv_id");
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

    my $conf = {};
    my @tab_volumegroups = ();
    my $volumegroups = $self->{_dbix}->lvm2_vgs;
    while(my $vg_row = $volumegroups->next){
        my @tab_logicalvolumes = ();
        my %vg = $vg_row->get_columns();
        my $logicalvolumes = $vg_row->lvm2_lvs;
        while(my $lv_row = $logicalvolumes->next) {
            my %lv = $lv_row->get_columns();
            push @tab_logicalvolumes, \%lv;
        }
        $vg{lvm2_lvs} = \@tab_logicalvolumes;
        push @tab_volumegroups, \%vg;
    }
    $conf->{lvm2_vgs} = \@tab_volumegroups;
    return $conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;

    # TODO input validation
    for my $vg ( @{ $conf->{vgs} }) {
        for my $new_lv ( @{ $vg->{lvs} }) {
            if (keys %$new_lv) {
                $self->createDisk(
                    name       => $new_lv->{lvm2_lv_name},
                    size       => $new_lv->{lvm2_lv_size},
                    filesystem => $new_lv->{lvm2_lv_filesystem},
                    vg_id      => $vg->{vg_id}
                );
            }
        }
    }
}

sub getExportManagerFromBootPolicy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "boot_policy" ]);

    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));

    if ($args{boot_policy} eq Entity::HostManager->BOOT_POLICIES->{pxe_iscsi}) {
        return $cluster->getComponent(name => "Iscsitarget", version => "1");
    }
    elsif ($args{boot_policy} eq Entity::HostManager->BOOT_POLICIES->{pxe_nfs}) {
        return $cluster->getComponent(name => "Nfsd", version => "3");
    }
    
    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported boot policy: $args{boot_policy}"
          );
}

=head2 createDisk

    Desc : Implement createDisk from DiskManager interface.
           This function enqueue a ECreateDisk operation.
    args :

=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "vg_id", "name", "size", "filesystem" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateDisk',
        params   => {
            disk_manager_id     => $self->getAttr(name => 'component_id'),
            name                => $args{name},
            size                => $args{size},
            filesystem          => $args{filesystem},
            vg_id               => $args{vg_id},
        },
    );
}

=head2 removeDisk

    Desc : Implement removeDisk from DiskManager interface.
           This function enqueue a ERemoveDisk operation.
    args :

=cut

sub removeDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    $log->debug("New Operation RemoveDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveDisk',
        params   => {
            container_id => $args{container}->getAttr(name => 'container_id'),
        },
    );
}

=head2 getFreeSpace

    Desc : Implement getFreeSpace from DiskManager interface.
           This function return the free space on the volume group.
    args :

=cut

sub getFreeSpace {
    my $self = shift;
    my %args = @_;

    my $vg_id = General::checkParam(args    => \%args,
                                    name    => 'vg_id',
                                    default => $self->getMainVg->{vgid});

    my $vg_rs = $self->{_dbix}->lvm2_vgs->single({ lvm2_vg_id => $vg_id });

    return $vg_rs->get_column('lvm2_vg_freespace');
}

=head2 getContainer

    Desc : Implement getContainer from DiskManager interface.
           This function return the container hash that match
           identifiers given in paramters.
    args : lv_id

=cut

sub getContainer {
    my $self = shift;
    my %args = @_;

    my $main  = $self->getMainVg;
    my $vg_rs = $self->{_dbix}->lvm2_vgs->single({ lvm2_vg_id => $main->{vgid} });
    my $lv_rs = $vg_rs->lvm2_lvs->single({ lvm2_lv_id => $args{lv_id} });

    my $lvm_container = Entity::Container::LvmContainer->find(
                            hash => { lv_id => $lv_rs->get_column('lvm2_lv_id') }
                        );
    my $container = {
        container_id         => $lvm_container->{_dbix}->get_column('lvm_container_id'),
        container_name       => $lv_rs->get_column('lvm2_lv_name'),
        container_size       => $lv_rs->get_column('lvm2_lv_size'),
        container_filesystem => $lv_rs->get_column('lvm2_lv_filesystem'),
        container_freespace  => $lv_rs->get_column('lvm2_lv_freespace'),
        container_device     => '/dev/' . $vg_rs->get_column('lvm2_vg_name') .
                                '/' . $lv_rs->get_column('lvm2_lv_name'),
    };

    return $container;
}

=head2 addContainer

    Desc : Implement addContainer from DiskManager interface.
           This function create a new LvmContainer into database.
    args : lv_id

=cut

sub addContainer {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "lv_id" ]);

    my $container = Entity::Container::LvmContainer->new(
                        disk_manager_id     => $self->getAttr(name => 'lvm2_id'),
                        lv_id               => $args{lv_id},
                    );

    my $container_id = $container->getAttr(name => 'container_id');
    $log->info("Lvm container <$container_id> saved to database");

    return $container;
}

=head2 delContainer

    Desc : Implement delContainer from DiskManager interface.
           This function delete a LvmContainer from database.
    args : container

=cut

sub delContainer {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    $args{container}->delete();
}


=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut
1;
