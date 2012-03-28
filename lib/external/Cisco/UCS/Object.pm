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

use Cisco::UCS;

sub new {
    my $class = shift;
    my %args = @_;

    my $hash = $args{hash};
    my %old = %{$args{hash}};
    $hash->{old} = \%old;
    $hash->{ucs} = $args{ucs};
    $hash->{classId} = $args{classId};

    bless $hash;
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

    foreach my $key (keys %old) {
        if (not ($self->{$key} eq $self->{old}{$key})) {
            $updated{$key} = $self->{$key};
        }
    }

    return $self->{ucs}->put(dn      => $self->{dn},
                             classId => $self->{classId},
                             %updated);
}

1;
