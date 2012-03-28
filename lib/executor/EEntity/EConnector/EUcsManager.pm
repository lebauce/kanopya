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

package EEntity::EConnector::EUcsManager;
use base "EEntity";
use base "EEntity::EHostManager";

use strict;
use warnings;
use General;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "cluster", "host" ]);

    my $ucs = $self->_getEntity();
    my $sn = $args{host}->getAttr(name => "host_serial_number");
    $ucs->start_service_profile(dn => $ucs->{ou} . "/" . $sn);
}

sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "cluster", "host" ]);

    my $ucs = $self->_getEntity();
    my $sn = $args{host}->getAttr(name => "host_serial_number");
    $ucs->stop_service_profile(dn => $ucs->{ou} . "/" . $sn);
}

sub postStart {
}

=head2 getFreeHost

    Desc : Return one free host that match the criterias
    args : ram, cpu

=cut

sub getFreeHost {
    my $self = shift;
    my %args = @_;

    if ($args{ram_unit}) {
        $args{ram} .= $args{ram_unit};
        delete $args{ram_unit};
    }

    $args{host_manager_id} = $self->_getEntity->getAttr(name => 'entity_id');

    my $ucs = $self->_getEntity();
    $ucs->init();
    my $ou = $ucs->{ucs}->getAttr(name => "ucs_ou");

    # Get all free hosts of the specified host manager
    my @hosts = $self->_getEntity()->getFreeHosts();
    my $free_hosts = ();

    for my $host (@hosts) {
        my $blade = $ucs->{api}->get(dn      => $host->getAttr(name => "host_serial_number"),
                                     classId => "computeBlade");
        my $sp = $blade->{assignedToDn};

        if ($blade->{dn} ne "sys/chassis-1/blade-5") {
            push @{$free_hosts}, $host;
        }
    }

    return DecisionMaker::HostSelector->getHost(%args);
}

1;
