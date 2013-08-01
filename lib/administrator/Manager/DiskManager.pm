# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Manager::DiskManager;
use base "Manager";

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

Check params required for creating disks.

=end classdoc
=cut

sub checkDiskManagerParams {}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        systemimage_size => {
            label        => 'System image size',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 0,
        },
    };
}


=pod
=begin classdoc

@return the managers parameters as an attribute definition. 

=end classdoc
=cut

sub getDiskManagerParams {
    my $self = shift;
    my %args  = @_;

    return {};
}


sub getFreeSpace {
    throw Kanopya::Exception::NotImplemented();
}


sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "name" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateDisk',
        params   => {
            context => {
                disk_manager => $self,
            },
            %args,
        },
    );
}


sub removeDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    $log->debug("New Operation RemoveDisk with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'RemoveDisk',
        params   => {
            context => {
                disk_manager => $self,
                container    => $args{container},
            },
        },
    );
}


sub getExportManagers {
    my $self = shift;
    my %args = @_;

    return [];
}

sub diskType {
    return '';
}


sub getExportManagerFromBootPolicy {
    throw Kanopya::Exception::NotImplemented();
}


sub getBootPolicyFromExportManager {
    throw Kanopya::Exception::NotImplemented();
}

1;
