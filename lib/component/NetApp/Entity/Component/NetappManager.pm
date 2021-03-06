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


=pod
=begin classdoc

Link Kanopya to NetApp Data Storage

=end classdoc
=cut

package Entity::Component::NetappManager;
use base 'Entity::Component';

use Entity::ServiceProvider::Netapp;
use warnings;
use NetApp::API;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub get {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::get(%args);

    return $self;
}

sub init {
    my $self = shift;

    return if (defined $self->{api});

    my $netapp = Entity::ServiceProvider::Netapp->get(
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


=pod
=begin classdoc

Implement getFreeSpace from DiskManager interface. This function returns the free space on all disks

=end classdoc
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


=pod
=begin classdoc

Override relation used when deletion in order to skip AUTOLOAD

=end classdoc
=cut

sub entity_lock_entity {
    my $self = shift;
    return $self->SUPER::entity_lock_entity;
}

=pod
=begin classdoc

Override relation used when deletion in order to skip AUTOLOAD

=end classdoc
=cut

sub param_preset {
    my $self = shift;
    return $self->SUPER::param_preset;
}
1;
