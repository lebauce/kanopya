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
use base "EEntity::EComponent";

use strict;
use Data::Dumper;
use Log::Log4perl "get_logger";
use Kanopya::Exceptions;
use General;

my $log = get_logger("executor");
my $errmsg;
# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

=head2 createDisk

createDisk ( name, size, filesystem, econtext )
    desc: This function create a new lv on storage server.
    args:
        name : string : new lv name
        size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
        filesystem : String : The filesystem is defined by mkfs filesystem option
        econtext : Econtext : execution context on the storage server
    return:
        code returned by EEntity::EComponent::ELvm2->lvCreate
    
=cut
sub createDisk {
    my $self = shift;
    my %args = @_;
    General::checkParams(args=>\%args, required=>["name", "size", "filesystem", "econtext"]);

    my $vg = $self->_getEntity()->getMainVg();
    my $lv_id = $self->lvCreate(lvm2_vg_id =>$vg->{vgid}, lvm2_lv_name => $args{name},
                    lvm2_lv_filesystem =>$args{filesystem}, lvm2_lv_size => $args{size},
                    econtext => $args{econtext}, lvm2_vg_name => $vg->{vgname});
    if (( exists $args{erollback} and defined $args{erollback})){
           $args{erollback}->add(function   =>$self->can('removeDisk'),
                                parameters => [$self,
                                               "name", $args{name},
                                               "econtext", $args{econtext}]);
    }
    return $lv_id;
}
=head2 removeDisk

removeDisk ( name, econtext )
    desc: This function remove a lv using it lvname.
    args:
        name : string: lv name
        econtext : Econtext : execution context on the storage server
    return:
        code returned by EEntity::EComponent::ELvm2->lvRemove

=cut
sub removeDisk{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args, required=>["name", "econtext"]);

    my $vg = $self->_getEntity()->getMainVg();

    return $self->lvRemove(lvm2_vg_id =>$vg->{vgid}, lvm2_lv_name => $args{name},
                    econtext => $args{econtext}, lvm2_vg_name => $vg->{vgname});
}
=head2 lvCreate

createDisk ( lvm2_lv_name, lvm2_lv_size, lvm2_lv_filesystem, lvm2_vg_id, econtext, lvm2_vg_name)
    desc: This function create a new lv on storage server and add it in db through entity part
    args:
        lvm2_lv_name : string : new lv name
        lvm2_lv_size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
        lvm2_lv_filesystem : String : The filesystem is defined by mkfs filesystem option
        econtext : Econtext : execution context on the storage server
        lvm2_vg_id : Int : VG id on which lv will be created
        lvm2_vg_name : String : vg name
    return:
        code returned by Entity::Component::Lvm2->lvCreate
    
=cut
sub lvCreate{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args, required=>["lvm2_lv_name", "lvm2_lv_size",
                                                  "lvm2_lv_filesystem", "econtext", 
                                                  "lvm2_vg_id", "lvm2_vg_name"]);

    $log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");
    $log->debug("lvcreate $args{lvm2_vg_name} -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}");
    my $command = "lvcreate $args{lvm2_vg_name} -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}";
    my $ret = $args{econtext}->execute(command => $command);
    if($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
    
    my $newdevice = "/dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}";
    if (! defined $args{"noformat"}){
        $self->mkfs(device => $newdevice, fstype => $args{lvm2_lv_filesystem}, econtext => $args{econtext});
    }
    delete $args{noformat};
    
    $self->vgSpaceUpdate(econtext => $args{econtext}, lvm2_vg_id => $args{lvm2_vg_id}, 
                        lvm2_vg_name => $args{lvm2_vg_name});
    delete $args{econtext};
    delete $args{lvm2_vg_name};
    
    return $self->_getEntity()->lvCreate(%args);
    
    
    
}
=head2 vgSizeUpdate

vgSizeUpdate ( lvm2_vg_id, econtext, lvm2_vg_name)
    desc: This function update vg free space on storage server
    args:
        econtext : Econtext : execution context on the storage server
        lvm2_vg_id : Int : identifier of vg update
        lvm2_vg_name : String : vg name
    return:
        code returned by Entity::Component::Lvm2->vgSpaceUpdate
    
=cut
sub vgSpaceUpdate {
    my $self = shift;
    my %args = @_;
    
    if ((! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id}) ||
        (! exists $args{econtext} or ! defined $args{econtext}) ||
        (! exists $args{lvm2_vg_name} or ! defined $args{lvm2_vg_name})) { 
        $errmsg = "ELvm2->vgSpaceUpdate need a econtext, lvm2_vg_id and lvm2_vg_name named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $command = "vgs $args{lvm2_vg_name} --noheadings -o vg_free --nosuffix --units M --rows";
    my $ret = $args{econtext}->execute(command => $command);
    if($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
    my $freespace = $ret->{stdout};
    chomp $freespace;
    $freespace =~ s/^[ \t]+//;
    $freespace =~ s/,\d*$//;

    return $self->_getEntity()->vgSizeUpdate(lvm2_vg_freespace => $freespace, lvm2_vg_id => $args{lvm2_vg_id});
}

=head2 lvRemove

lvRemove ( lvm2_lv_name, lvm2_vg_id, econtext, lvm2_vg_name)
    desc: This function remove a lv.
    args:
        name : string: lv name
        econtext : Econtext : execution context on the storage server


=cut
sub lvRemove{
    my $self = shift;
    my %args = @_;
    
    if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
        (! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id}) ||
        (! exists $args{econtext} or ! defined $args{econtext}) ||
        (! exists $args{lvm2_vg_name} or ! defined $args{lvm2_vg_name})) { 
        $errmsg = "ELvm2->removeLV need a lvm2_lv_name, lvm2_vg_id, econtext and lvm2_vg_name named argument!"; 
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    $log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");
    $log->debug("lvremove -f /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}");
    my $ret = $args{econtext}->execute(command => "lvremove -f /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}");
#    delete $args{econtext};
#    delete $args{lvm2_vg_name};
    $self->_getEntity()->lvRemove(%args);
    $self->vgSpaceUpdate(econtext => $args{econtext}, lvm2_vg_id => $args{lvm2_vg_id}, 
                        lvm2_vg_name => $args{lvm2_vg_name});
}

=head2 mkfs

_mkfs ( device, fstype, fsoptions, econtext)
    desc: This function create a filesystem on a device.
    args:
        device : string: device full path (like /dev/sda2 or /dev/vg/lv)
        fstype : string: name of filesystem (ext2, ext3, ext4)
        fsoptions : string: filesystem options to use during creation (optional) 
        econtext : Econtext : execution context on the storage server
=cut
sub mkfs {
    my $self = shift;
    my %args = @_;
    
    if ((! exists $args{device} or ! defined $args{device}) ||
        (! exists $args{fstype} or ! defined $args{fstype}) ||
        (! exists $args{econtext} or ! defined $args{econtext})) { 
        $errmsg = "ELvm2->_mkfs need a device, fstype and econtext named argument!"; 
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    
    my $command = "mkfs -t $args{fstype} ";
    if($args{fsoptions}) {
        $command .= "$args{fsoptions} ";
    }
    $command .= " $args{device}";
    my $ret = $args{econtext}->execute(command => $command);
    if($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
}

1;
