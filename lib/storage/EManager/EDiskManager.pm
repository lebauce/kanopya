#    Copyright © 2012 Hedera Technology SAS
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


=pod
=begin classdoc

TODO

=end classdoc
=cut

package EManager::EDiskManager;
use base "EManager";

use warnings;
use strict;
use Log::Log4perl 'get_logger';
use General;
use Kanopya::Exceptions;

my $log = get_logger("");


=pod
=begin classdoc

This function create a filesystem on a device.

@param device string device full path (like /dev/sda2 or /dev/vg/lv)
@param fstype string name of filesystem (ext2, ext3, ext4)
@param fsoptions string filesystem options to use during creation (optional)

=end classdoc
=cut

sub mkfs {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "device", "fstype" ]);
    
    my $command = "TMPDIR=`mktemp -d`;" .
                  "TMPDISK=`mktemp`;" .
                  "DEV=`readlink -f $args{device}`;" .
                  "[ -x /usr/bin/virt-format ] && virt-format -a $args{device} --filesystem=$args{fstype} || " .
                  "(virt-make-fs --format=raw --size=256M --type=$args{fstype} --partition -- \$TMPDIR \$TMPDISK;" .
                  "virt-resize --expand /dev/sda1 \$TMPDISK \$DEV; rm \$TMPDISK; rmdir \$TMPDIR)";

    my $ret = $self->getEContext->execute(command => $command,
                                          timeout => 3600);
    if($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
}


=pod
=begin classdoc

Parent method to check prerequisites for remove disk.
Call this method in overriden method in sub classes.

=end classdoc
=cut

sub removeDisk{
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => [ "container" ]);

    # Check if the container has no container access
    if (scalar(@{ $args{container}->getAccesses })) {
        throw Kanopya::Exception::Execution::ResourceBusy(
                  error => "Can not remove exported container $self"
              );
    }
}

1;
