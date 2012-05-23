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

package EEntity::EComponent::ELvm2;
use base "EDiskManager";
use base "EEntity::EComponent";

use strict;

use General;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

=head2 createDisk

createDisk ( name, size, filesystem)
    desc: This function create a new lv on storage server.
    args:
        name : string : new lv name
        size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
        filesystem : String : The filesystem is defined by mkfs filesystem option
    return:
        code returned by EEntity::EComponent::ELvm2->lvCreate
    
=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'name', 'size', 'filesystem' ]);

    my $vg_id = General::checkParam(args    => \%args,
                                    name    => 'vg_id',
                                    default => $self->_getEntity->getMainVg->{vgid});

    my $entity = $self->lvCreate(lvm2_vg_id         => $vg_id,
                                 lvm2_lv_name       => $args{name},
                                 lvm2_lv_filesystem => $args{filesystem},
                                 lvm2_lv_size       => $args{size});
    my $container = EFactory::newEEntity(data => $entity);

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('removeDisk'),
            parameters => [ $self, "container", $container ]
        );
    }

    return $container;
}

=head2 removeDisk

=cut

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

    my $vg = $self->getMainVg();
    $self->lvRemove(lvm2_vg_id   => $vg->{vgid},
                    lvm2_lv_name => $args{container}->getAttr(name => 'container_name'),
                    lvm2_vg_name => $vg->{vgname});

    $args{container}->delete();

    #TODO: insert erollback ?
}

=head2 lvCreate

createDisk ( lvm2_lv_name, lvm2_lv_size, lvm2_lv_filesystem, lvm2_vg_id, lvm2_vg_name)
    desc: This function create a new lv on storage server and add it in db through entity part
    args:
        lvm2_lv_name : string : new lv name
        lvm2_lv_size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
        lvm2_lv_filesystem : String : The filesystem is defined by mkfs filesystem option
        lvm2_vg_id : Int : VG id on which lv will be created
        lvm2_vg_name : String : vg name
    return:
        code returned by Entity::Component::Lvm2->lvCreate
    
=cut

sub lvCreate{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "lvm2_lv_name", "lvm2_lv_size",
                                       "lvm2_lv_filesystem", "lvm2_vg_id" ]);

    my $vg_name = $self->_getEntity()->getVg(lvm2_vg_id => $args{lvm2_vg_id});

    my $command = "lvcreate $vg_name -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}B";
    $log->debug($command);

    my $ret = $self->getEContext->execute(command => $command);
    if ($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }

    my $newdevice = "/dev/$vg_name/$args{lvm2_lv_name}";
    if (! defined $args{"noformat"}) {
        $self->mkfs(device => $newdevice, fstype => $args{lvm2_lv_filesystem});
    }
    delete $args{noformat};
    
    $self->vgSpaceUpdate(lvm2_vg_id   => $args{lvm2_vg_id},
                         lvm2_vg_name => $vg_name);
    
    return $self->_getEntity()->lvCreate(%args);
}

=head2 vgSizeUpdate

vgSizeUpdate ( lvm2_vg_id, lvm2_vg_name)
    desc: This function update vg free space on storage server
    args:
        lvm2_vg_id : Int : identifier of vg update
        lvm2_vg_name : String : vg name
    return:
        code returned by Entity::Component::Lvm2->vgSpaceUpdate
    
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

    return $self->_getEntity()->vgSizeUpdate(lvm2_vg_freespace => $freespace,
                                             lvm2_vg_id        => $args{lvm2_vg_id});
}

=head2 lvRemove

lvRemove ( lvm2_lv_name, lvm2_vg_id, lvm2_vg_name)
    desc: This function remove a lv.
    args:
        name : string: lv name

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

    $self->_getEntity()->lvRemove(%args);
    $self->vgSpaceUpdate(lvm2_vg_id   => $args{lvm2_vg_id}, 
                         lvm2_vg_name => $args{lvm2_vg_name});
}

1;
