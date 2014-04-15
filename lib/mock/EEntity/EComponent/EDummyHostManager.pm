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

=pod
=begin classdoc

Dmmy host manager that alway says "all is alright !".

@since    2014-May-09
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EComponent::EDummyHostManager;
use base "EEntity::EComponent";
use base "EManager::EHostManager";

use strict;
use warnings;

use Entity::Host;
use Harddisk;

use String::Random;
use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");


my $random = String::Random->new;


=pod
=begin classdoc

Create a new dummy host

=end classdoc
=cut

sub getFreeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "interfaces", "ram" ],
                         optional => { "deploy_on_disk" => 0, "tags" => [], "no_tags" => [],
                                       "core" => undef, "cpu" => undef });

    my $host = Entity::Host->new(active             => 1,
                                 host_manager_id    => $self->id,
                                 host_serial_number => $random->randpattern("CCccccn"),
                                 host_ram           => 8 * 1024 * 1024 * 1024,
                                 host_core          => 8);

    my $pxe = 1;
    for my $interface (@{ $args{interfaces} }) {
        my $mac = $random->randregex("[0-9][A-F]:[A-F][0-9]:[0-9][A-F]:[A-F][0-9]:[0-9][A-F]:[0-9][A-F]");
        $host->addIface(iface_name => $interface->interface_name, iface_pxe => $pxe, iface_mac_addr => $mac);

        $pxe = 0;
    }

    if ($args{deploy_on_disk}) {
        Harddisk->new(host_id         => $host->id,
                      harddisk_device => "/dev/sda1",
                      harddisk_size   => 1 * 1024 * 1024 * 1024 * 1024);
    }

    return $host;
}


=pod
=begin classdoc

Remove the dummy host

=end classdoc
=cut

sub releaseHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    $args{host}->delete();
}


=pod
=begin classdoc

Do nothing.

=end classdoc
=cut

sub startHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);
}


=pod
=begin classdoc

Do nothing.

=end classdoc
=cut

sub stopHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    # Stop host !
}


=pod
=begin classdoc

Do nothing.

=end classdoc
=cut

sub haltHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    # Halt host !
}


=pod
=begin classdoc

A dummy host is up, execpted when the corresponding node is goingout

=end classdoc
=cut

sub checkUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my ($state, $timestamp) = $args{host}->node->getState();
    if ($state ne 'goingout') {
        # I'm up !
        return 1;
    }
    return 0;
}


1;
