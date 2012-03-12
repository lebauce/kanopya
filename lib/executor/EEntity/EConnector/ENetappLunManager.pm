#    Copyright © 2012 Hedera Technology SAS
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

package EEntity::EConnector::ENetappLunManager;
use base "EEntity::EConnector";

use warnings;
use strict;

use General;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

=head2 createDisk

createDisk ( name, size, filesystem, econtext )
    desc: This function creates a new volume on NetApp.
    args:
        name : string : new volume name
        size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
        filesystem : String : filesystem type
        econtext : Econtext : execution context on the storage server
    return:
        1 if an error occurred, 0 otherwise
    
=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "volume_id", "name", "size", "filesystem", "econtext" ]);

    my $volume = Entity::Container::NetappVolume->get(id => $args{volume_id});
    my $volume_name = "/vol/" . $volume->getAttr(name => "name") . "/" . $args{name};

    my $api = $self->_getEntity();
    $api->lun_create_by_size(path => $volume_name,
                             size => $args{size},
                             type => "linux");

    if (! defined $args{"noformat"}) {
        my $newdevice = "";
        $self->mkfs(device   => $newdevice,
                    fstype   => $args{filesystem},
                    econtext => $args{econtext});
    }
    delete $args{noformat};
    delete $args{econtext};

    # TODO: Update volume group size

    my $container = $self->_getEntity()->addContainer(%args);

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('removeDisk'),
            parameters => [ $self, "container", $container, "econtext", $args{econtext} ]
        );
    }

    return $container;
}

=head2 removeDisk

=cut

sub removeDisk{
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required=>[ "container", "econtext" ]);

    if (! $args{container}->isa("Entity::Container::NetappLun")) {
        throw Kanopya::Exception::Execution(
                  error => "Container must be a Entity::Container::NetappLun"
              );
    }

    $self->_getEntity()->lun_remove(path => $args{container}->{path});

    $self->_getEntity()->delContainer(container => $args{container});

    #TODO: insert erollback ?
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

    General::checkParams(args     => \%args,
                         required => [ "device", "fstype", "econtext" ]);
    
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
