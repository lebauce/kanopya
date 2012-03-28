#    NetappManager.pm - NetApp base manager
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

package Entity::Connector::NetappManager;
use lib "/opt/kanopya/lib/external/NetApp";
use base "Entity::Connector";

use warnings;
use NetApp::API;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub get {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::get(%args);

    $self->init();

    return $self;
}

sub init {
    my $self = shift;

    return if (defined $self->{api});

    my $netapp = Entity::ServiceProvider::Outside::Netapp->get(
                     id => $self->getAttr(name => "service_provider_id")
                 );

    $self->{api} = NetApp::API->new(
                       addr     => $netapp->getAttr(name => "netapp_addr"),
                       username => $netapp->getAttr(name => "netapp_login"),
                       passwd   => $netapp->getAttr(name => "netapp_passwd")
                   );

    $self->{netapp} = $netapp;

    eval {
        $self->system_get_version();
        $self->{state} = "up";
    };
    if ($@) {
        $self->{state} = "down";
    }
}

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $method = $autoload[-1];

    if (not defined $self->{api}) {
        $self->init();
    }

    return $self->{api}->$method(%args);
}

sub DESTROY {
    if (defined $self->{api}) {
        $self->{api}->logout();
        $self->{api} = undef;
    }
}

=head2 getFreeSpace

    Desc : Implement getFreeSpace from DiskManager interface.
           This function returns the free space on all disks
    args :

=cut

sub getFreeSpace {
    my $self = shift;
	my $total_spare_cap = 0;
    my @disks = $self->disks;

    for my $disk (@disks) {
        my $raid_state = $disk->raid_state;
        if (($raid_state eq "spare") ||
            ($raid_state eq "pending") ||
            ($raid_state eq "reconstructing")) {
            $total_spare_cap += $disk->used_space;
        }
    }

    return $total_spare_cap;
}

1;
