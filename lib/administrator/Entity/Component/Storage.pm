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

package Entity::Component::Storage;
use base "Entity::Component";
use base "Manager::DiskManager";

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    disk_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {}

sub diskType {
    return "Unmanaged storage";
}

sub getExportManagers {
    my $self = shift;
    my %args = @_;

    return [ $self->service_provider->getComponent(name => "Iscsi") ];
}

sub getReadOnlyParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'readonly' ]);
    
    return undef;
}

sub getFreeSpace {
    my $self = shift;
    my %args = @_;

    return 0;
}

sub getExportManagerFromBootPolicy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "boot_policy" ]);

    if ($args{boot_policy} eq Manager::HostManager->BOOT_POLICIES->{root_iscsi}) {
        return $self->service_provider->getComponent(name => "Iscsi");
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported boot policy: $args{boot_policy}"
          );
}

sub getBootPolicyFromExportManager {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "export_manager" ]);

    if ($args{export_manager}->id == $self->service_provider->getComponent(name => "Iscsi")->id) {
        return Manager::HostManager->BOOT_POLICIES->{root_iscsi};
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported export manager:" . $args{export_manager}
          );
}

1;
