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

package Cisco::UCS::ServiceProfile;
use base "Cisco::UCS::Object";

use warnings;
use strict;

sub new {
    my $class = shift;
    my %args = @_;

    return $class->SUPER::new(%args);
}

sub create {
    my $class = shift;
    my %args = @_;

    if (not defined ($args{dn})) {
        $args{dn} = "org-root/ls-" . $args{name};
    }

    my $ucs = $args{ucs};
    delete $args{ucs};

    return $ucs->create(classId => "lsServer",
                        %args)
}

sub associate {
    my $self = shift;
    my %args = @_;

    $self->{lsBinding} = [ {
        pnDn              => $args{blade},
        restrictMigration => $args{restrictMigration} || "no",
        rn                => "pn"
    } ];

    $self->update();
}

sub set_power_state {
    my $self = shift;
    my %args = @_;

    $self->{lsPower} = [ {
        childAction       => "deleteNonPresent",
        state             => $args{state},
        rn                => "power"
    } ];

    $self->update();
}

sub start {
    my $self = shift;

    $self->set_power_state(state => "up");
}


sub stop {
    my $self = shift;

    $self->set_power_state(state => "soft-shut-down");
}

sub reboot {
    my $self = shift;

    $self->set_power_state(state => "cycle-wait");
}

sub unbind {
    my $self = shift;

    $self->{srcTemplName} = "";
    $self->update();
}

1;
