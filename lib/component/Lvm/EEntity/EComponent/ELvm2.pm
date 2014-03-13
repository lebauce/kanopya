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


=pod
=begin classdoc

TODO

=end classdoc
=cut

package EEntity::EComponent::ELvm2;
use base "EManager::EDiskManager";
use base "EEntity::EComponent";

use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Lvm2Vg;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

This function create a new lv on storage server.

@param name new lv name
@param size disk size finishing by unit (M : Mega, K : kilo, G : Giga)
@param filesystem The filesystem is defined by mkfs filesystem option
@optional vg_id

@return code returned by EEntity::EComponent::ELvm2->lvCreate

=end classdoc
=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'name', 'size', 'filesystem' ],
                         optional => { 'vg_id' => undef });

    my $vg = $args{vg_id} ? Lvm2Vg->get(id => $args{vg_id})
                          : $self->getMainVg;

    $self->lvCreate(vg_name            => $vg->lvm2_vg_name,
                    lvm2_lv_name       => $args{name},
                    lvm2_lv_filesystem => $args{filesystem},
                    lvm2_lv_size       => $args{size});

    my $newdevice = "/dev/" . $vg->lvm2_vg_name . "/$args{name}";
    if (! defined $args{"noformat"}) {
        $self->mkfs(device => $newdevice, fstype => $args{filesystem});
    }
    delete $args{noformat};
    
    $self->vgSpaceUpdate(lvm2_vg_id   => $vg->id,
                         lvm2_vg_name => $vg->lvm2_vg_name);

    my $entity = $self->_entity->lvCreate(
                     lvm2_vg_id         => $vg->id,
                     lvm2_lv_name       => $args{name},
                     lvm2_lv_filesystem => $args{filesystem},
                     lvm2_lv_size       => $args{size}
                 );

    my $container = EEntity->new(data => $entity);
    if (exists $args{erollback} and defined $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('removeDisk'),
            parameters => [ $self, "container", $container ]
        );
    }

    return $container;
}


sub removeDisk{
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => [ "container" ]);

    if (! $args{container}->isa("EEntity::EContainer::ELvmContainer")) {
        throw Kanopya::Exception::Execution(
                  error => "Container must be a EEntity::EContainer::ELvmContainer, not " . 
                           ref($args{container})
              );
    }

    # Check if the disk is removable
    $self->SUPER::removeDisk(%args);

    my $vg = $self->getMainVg();
    $self->lvRemove(lvm2_vg_id   => $vg->id,
                    lvm2_lv_name => $args{container}->container_name,
                    lvm2_vg_name => $vg->lvm2_vg_name);

    $self->_entity->lvRemove(lvm2_vg_id   => $vg->id,
                             lvm2_lv_name => $args{container}->container_name);

    $self->vgSpaceUpdate(lvm2_vg_id   => $vg->id,
                         lvm2_vg_name => $vg->lvm2_vg_name);

    $args{container}->delete();

    #TODO: insert erollback ?
}


=pod
=begin classdoc

This function create a new lv on storage server and add it in db through entity part

@param lvm2_lv_name string new lv name
@param lvm2_lv_size String disk size finishing by unit (M : Mega, K : kilo, G : Giga)
@param lvm2_lv_filesystem String The filesystem is defined by mkfs filesystem option
@param lvm2_vg_id Int VG id on which lv will be created
@param lvm2_vg_name String vg name

@return code returned by Entity::Component::Lvm2->lvCreate

=end classdoc
=cut

sub lvCreate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "lvm2_lv_name", "lvm2_lv_size",
                                       "lvm2_lv_filesystem", "vg_name" ]);

    my $command = "lvcreate $args{vg_name} -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}B";

    my $ret = $self->getEContext->execute(command => $command);
    if ($ret->{exitcode} != 0) {
        if ($ret->{stderr} =~ m/already exists/) {
            throw Kanopya::Exception::Execution::AlreadyExists(error => $ret->{stderr});
        }
        else {
            throw Kanopya::Exception::Execution(
                      error => "Error during execution of '$command', $ret->{stderr}"
                  );
        }
    }
}


=pod
=begin classdoc

This function create a filesystem on a device.

@param device string device full path (like /dev/sda2 or /dev/vg/lv)
@param fstype string name of filesystem (ext2, ext3, ext4)
@param fsoptions string filesystem options to use during creation (optional)
@param econtext Econtext execution context on the storage server

=end classdoc
=cut

sub mkfs {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "device", "fstype" ]);
    
    my $command = "mkfs -F -t $args{fstype} ";
    if ($args{fsoptions}) {
        $command .= "$args{fsoptions} ";
    }

    $command .= " $args{device}";
    my $ret = $self->getEContext->execute(command => $command);
    if($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
}


=pod
=begin classdoc

This function update vg free space on storage server

@param lvm2_vg_id Int identifier of vg update
@param lvm2_vg_name String vg name

@return code returned by Entity::Component::Lvm2->vgSpaceUpdate

=cut

sub vgSpaceUpdate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "lvm2_vg_id", "lvm2_vg_name" ]);

    my $command = "vgs $args{lvm2_vg_name} --noheadings -o vg_free --nosuffix --units B --rows";
    my $ret = $self->getEContext->execute(command => $command);

    if($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
    my $freespace = $ret->{stdout};
    chomp $freespace;
    $freespace =~ s/^[ \t]+//;
    $freespace =~ s/,\d*$//;

    return $self->_entity->vgSizeUpdate(lvm2_vg_freespace => $freespace,
                                             lvm2_vg_id        => $args{lvm2_vg_id});
}

=pod
=begin classdoc

This function remove a lv.

@param lvm2_lv_name string lv name
@param lvm2_vg_name string vg name
@param lvm2_vg_id int vg id

=end classdoc
=cut

sub lvRemove{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "lvm2_vg_id", "lvm2_vg_name", "lvm2_lv_name" ]);

    my $ret;
    my $lvchange_cmd = "lvchange -a n /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}";
    $log->debug($lvchange_cmd);
    $ret = $self->getEContext->execute(command => $lvchange_cmd);

    my $lvremove_cmd = "lvremove -f /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}";
    $log->debug($lvremove_cmd);
    $ret = $self->getEContext->execute(command => $lvremove_cmd);

    if ($ret->{exitcode} != 0) {
        $errmsg = "Error with removing logical volume " .
                  "/dev/$args{lvm2_vg_name}/$args{lvm2_lv_name} " . $ret->{'stderr'};
        $log->error($errmsg);

        # sterr is defined, but the logical volume seems to be corectly
        # removed from vg.
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
}

1;
