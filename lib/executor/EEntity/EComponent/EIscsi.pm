#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EComponent::EIscsi;
use base "EEntity::EComponent";
use base 'EManager::EExportManager';

use strict;
use warnings;

use General;
use EFactory;
use Entity::ContainerAccess::IscsiContainerAccess;
use Entity::Component::Iscsi::IscsiPortal;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'export_name', 'iscsi_portal', 'target', 'lun' ],
                         optional => { 'typeio' => 'fileio', 'iomode' => 'wb' });

    my $portal = Entity::Component::Iscsi::IscsiPortal->get(id => $args{iscsi_portal});
    my $params = {
         export_manager_id       => $self->id,
         container_access_export => $args{target},
         lun_name                => $args{lun},
         container_access_ip     => $portal->iscsi_portal_ip,
         container_access_port   => $portal->iscsi_portal_port,
         typeio                  => $args{typeio},
         iomode                  => $args{iomode},
    };

    # If container given in paramater, check if the disk is not already exported
    if ($args{container}) {
        $self->SUPER::createExport(%args);

        $params->{container} = $args{container};
    }

    return EFactory::newEEntity(data => Entity::ContainerAccess::IscsiContainerAccess->new(%$params));
}

sub removeExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    if (not $args{container_access}->isa("EEntity::EContainerAccess::EIscsiContainerAccess")) {
        throw Kanopya::Exception::Execution(
                  error => "ContainerAccess must be a EEntity::EContainerAccess::EIscsiContainerAccess, not " .
                           ref($args{container_access})
              );
    }

    $args{container_access}->remove();
}

1;
