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

package EEntity::EConnector::ENetappVolumeManager;
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
                         required => [ "name", "size", "filesystem", "econtext" ]);

    my $api = $self->_getEntity();
    $api->volume_create("containing-aggr-name" => "aggr0",
                        volume => "/" . $args{name},
                        size   => $args{size});

    delete $args{noformat};
    delete $args{econtext};

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

sub removeDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required=>[ "container", "econtext" ]);

    if (! $args{container}->isa("Entity::Container::NetappVolume")) {
        throw Kanopya::Exception::Execution(
                  error => "Container must be a Entity::Container::NetappVolume"
              );
    }

    my $container_name = $args{container}->getAttr(name => 'name');

    $self->_getEntity()->volume_offline(name => $container_name);
    $self->_getEntity()->volume_destroy(name  => $container_name,
                                        force => "true");

    $self->_getEntity()->delContainer(container => $args{container});

    #TODO: insert erollback ?
}

1;
