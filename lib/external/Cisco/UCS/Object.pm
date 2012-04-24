#    Copyright 2012 Hedera Technology SAS
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

package Cisco::UCS::Object;

use warnings;
use strict;

sub new {
    my $class = shift;
    my %args = @_;

    my $hash = $args{hash};
    my %old = %{$args{hash}};
    my $classId = $args{classId};

    $hash->{old} = \%old;
    $hash->{ucs} = $args{ucs};
    $hash->{classId} = $classId;

    if ($classId eq "lsServer") {
        if ($hash->{type} eq "updating-template") {
            use Cisco::UCS::ServiceProfileTemplate;
            bless $hash, "Cisco::UCS::ServiceProfileTemplate";
        }
        else {
            use Cisco::UCS::ServiceProfile;
            bless $hash, "Cisco::UCS::ServiceProfile";
        }
    }
    elsif ($classId eq "fabricVlan") {
        use Cisco::UCS::VLAN;
        bless $hash, "Cisco::UCS::VLAN";
    }
    elsif ($classId eq "computeBlade") {
        use Cisco::UCS::Blade;
        bless $hash, "Cisco::UCS::Blade";
    }
    elsif ($classId eq "vnicEther") {
        use Cisco::UCS::Ethernet;
        bless $hash, "Cisco::UCS::Ethernet";
    }
    else {
        bless $hash;
    }

    return $hash;
}

sub children {
    my ($self, $classId) = @_;

    my $children = $self->{ucs}->resolve_children(dn      => $self->{dn},
                                                  classId => $classId);

    return $self->{ucs}->map_objects(objects => $children->{outConfigs},
                                     classId => $classId);
}

sub delete {
    my $self = shift;

    $self->{ucs}->put(dn      => $self->{dn},
                      classId => $self->{classId},
                      status  => "deleted");
}

sub update {
    my ($self, %args) = @_; 

    my %old = %{$self->{old}};
    my %updated = ();

    foreach my $key (keys %{$self}) {
        if (($key ne "old") and
            (not defined $self->{old}{$key}) or
            (not ($self->{$key} eq $self->{old}{$key}))) {
            $updated{$key} = $self->{$key};
        }
    }

    return $self->{ucs}->put(dn      => $self->{dn},
                             classId => $self->{classId},
                             %updated);
}

1;
