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

package EEntity::EContainerAccess::ELocalContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");
use Data::Dumper;

=head2 connect

=cut

sub connect {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $file = $self->getContainer->container_device;
    my $device;
    if (-b $file) {
        $device = $file;
    }
    else {
        # Get a free loop device
        $command = "losetup -f";
        $result = $args{econtext}->execute(command => $command);
        if ($result->{exitcode} != 0) {
            throw Kanopya::Exception::Execution(error => $result->{stderr});
        }
        chomp($result->{stdout});
        $device = $result->{stdout};

        $command = "losetup $device $file";
        $result = $args{econtext}->execute(command => $command);
        if ($result->{exitcode} != 0) {
            throw Kanopya::Exception::Execution(error => $result->{stderr});
        }
    }
    $log->debug("Return file loop dev (<$device>).");
    $self->setAttr(name  => 'device_connected', value => $device);

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('disconnect'),
            parameters => [ $self, "econtext", $args{econtext} ]
        );
    }

    return $device;
}

=head2 disconnect

=cut

sub disconnect {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $file = $self->getContainer->container_device;

    if (! -b $file) {
        my $device = $self->device_connected;

        $command = "losetup -d $device";
        $result  = $args{econtext}->execute(command => $command);
        if ($result->{exitcode} != 0) {
            throw Kanopya::Exception::Execution(error => $result->{stderr});
        }
    }

    $self->setAttr(name  => 'device_connected',
                   value => '');
}

1;
