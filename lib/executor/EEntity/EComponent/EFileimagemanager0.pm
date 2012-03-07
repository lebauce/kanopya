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

package EEntity::EComponent::EFileimagemanager0;
use base "EEntity::EComponent";

use strict;

use General;
use EFactory;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

=head2 createDisk

=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "name", "size", "filesystem", "econtext" ]);

    my $container_access = $self->_getEntity()->getMainContainerAccess();

    $self->fileCreate(container_access => $container_access,
                      file_name        => $args{name},
                      file_size        => $args{name},
                      file_filesystem  => $args{filesystem},
                      econtext         => $args{econtext});

    my $container = $self->_getEntity()->addContainer(
                        container_access_id => $container_access->getAttr(
                                                   name => 'container_access_id'
                                               ),
                        file_name           => $args{name},
                        file_size           => $args{size},
                        file_filesystem     => $args{filesystem},
                    );

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

    if (! $args{container}->isa("Entity::Container::FileContainer")) {
        throw Kanopya::Exception::Execution(
                  error => "Container must be a Entity::Container::FileContainer"
              );
    }

    my $container_access = $self->_getEntity()->getMainContainerAccess();

    $self->fileRemove(container        => $args{container},
                      container_access => $container_access,
                      econtext         => $args{econtext});

    $self->_getEntity()->delContainer(container => $args{container});

    #TODO: insert erollback ?
}

=head2 fileCreate
    
=cut

sub fileCreate{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "container_access", "file_name",
                                       "file_size", "file_filesystem",
                                       "econtext" ]);

    $log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");

    # Firstly mount the container access on the executor.
    my $mountpoint = $args{container_access}->getContainer->getAttr(name => 'container_name') .
                     "_filecreate_" . $args{file_name};
    my $econtainer_access = EFactory::newEEntity(data => $args{container_access});
    
    $econtainer_access->mount(mountpoint => $mountpoint,
                              econtext   => $args{econtext});

    my $file_image_path = "$mountpoint/$args{file_name}.img";

    $log->debug("Container access mounted, trying to create $file_image_path");

    if (-e $file_image_path) {
        throw Kanopya::Exception::Execution(
                  error => "FileContainer with name <" . $args{file_name} . "> " .
                           "already exists on container access <" .
                           $args{container_access}->getAttr(name => 'container_name') . ">"
              );
    }

    eval {
        # Open the file in write mode
        open(FILEIMAGE, '>', $file_image_path);

        # Seek the file until wanted size
        seek(FILEIMAGE, $args{file_size} - 1, 0);

        # Write 0 tat the end of file
        print FILEIMAGE 0;

        close(FILEIMAGE);
    };
    if ($@) {
        throw Kanopya::Exception::Execution(
                  error => "Unable to create file <$file_image_path> with size <$args{file_size}>: $@"
              );
    }

    if (! defined $args{"noformat"}){
        $self->mkfs(device   => $file_image_path,
                    fstype   => $args{file_filesystem},
                    econtext => $args{econtext});
    }

    $econtainer_access->umount(mountpoint => $mountpoint,
                               econtext   => $args{econtext});
}

=head2 fileRemove

=cut

sub fileRemove{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "container", "container_access",
                                       "econtext" ]);

    $log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");

    # Firstly mount the container access on the executor.
    my $mountpoint = $args{container_access}->getContainer->getAttr(name => 'container_name') .
                     "_filecreate_" . $args{file_name};
    my $econtainer_access = EFactory::newEEntity(data => $args{container_access});
    
    $econtainer_access->mount(mountpoint => $mountpoint,
                              econtext   => $args{econtext});

    my $file_image_path = "$mountpoint/$args{file_name}.img";

    $log->debug("Container access mounted, trying to remove $file_image_path");

    my $fileremove_cmd = "rm -f $file_image_path";
    $log->debug($fileremove_cmd);
    my $ret = $args{econtext}->execute(command => $fileremove_cmd);

    if($ret->{'stderr'}){
        $errmsg = "Error with removing file " . $file_image_path .  ": " . $ret->{'stderr'};
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }

    $econtainer_access->umount(mountpoint => $mountpoint,
                               econtext   => $args{econtext});
}

=head2 mkfs

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
