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

package EEntity::EComponent::EPhysicalhoster0;
use base "EEntity::EComponent";
use base "EEntity::EHostManager";

use strict;
use warnings;

use General;
use Entity::Powersupplycard;
use DecisionMaker::HostSelector;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");
my $errmsg;


=head2 startHost

=cut

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "cluster", "host", "econtext" ]);

    my $host = $args{host};
    my $powersupplycard_id = $host->getPowerSupplyCardId();
    if (!$powersupplycard_id) {
        if (not -e '/usr/sbin/etherwake') {
            $errmsg = "EOperation::EStartNode->startNode : /usr/sbin/etherwake not found";
            $log->error($errmsg);
            throw Kanopya::Exception::Execution(error => $errmsg);
        }
        my $command = "/usr/sbin/etherwake " . $host->getAttr(name => 'host_mac_address');
        my $result = $args{econtext}->execute(command => $command);
    }
    else {
        my $powersupplycard = Entity::Powersupplycard->get(id => $powersupplycard_id);
        my $powersupply_ip = $powersupplycard->getAttr(name => "powersupplycard_ip");

        $log->debug("Start host with power supply whose ip is : <$powersupply_ip>");
        my $sock = new IO::Socket::INET (
                       PeerAddr => $powersupply_ip,
                       PeerPort => '1470',
                       Proto    => 'tcp',
                   );
        $sock->autoflush(1);
        die "Could not create socket: $!\n" unless $sock;

        my $port = $powersupplycard->getHostPort(
                       host_powersupply_id => $host->getAttr(name => "host_powersupply_id")
                   );

        my $s = "R";
        $s .= pack "B16", ('0' x ($port - 1)) . '1' . ('0' x (16 - $port));
        $s .= pack "B16", "000000000000000";
        printf $sock $s;
        close($sock);
    }

    my $current_state = $host->getState();

    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $host->can('save'),
            parameters => [ $host ]
        );
        $args{erollback}->add(
            function   => $host->can('setAttr'),
            parameters => [ $host, "name" ,"host_state", "value", $current_state ]
        );
    }
}

=head2 stopHost

=cut

sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "cluster", "host" ]);

    my $host = $args{host};
    my $powersupply_id = $host->getAttr(name => "host_powersupply_id");
    if ($powersupply_id) {
        my $powersupplycard = Entity::Powersupplycard->get(
                                  id => $host->getPowerSupplyCardId()
                              );

        my $sock = new IO::Socket::INET (
                       PeerAddr => $powersupplycard->getAttr(name => "powersupplycard_ip"),
                       PeerPort => '1470',
                       Proto    => 'tcp',
                   );

        $sock->autoflush(1);
        die "Could not create socket: $!\n" unless $sock;

        my $port = $powersupplycard->getHostPort(host_powersupply_id => $powersupply_id);
        my $s = "R";
        $s .= pack "B16", "000000000000000";
        $s .= pack "B16", ('0' x ($port - 1)) . '1' . ('0' x (16 - $port));
        printf $sock $s;
        close($sock);
    }
}

=head2 getFreeHost

=cut

sub getFreeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "ram", "cpu" ]);

    if ($args{ram_unit}) {
        $args{ram} .= $args{ram_unit};
        delete $args{ram_unit};
    }
    $args{host_manager_id} = $self->_getEntity->getAttr(name => 'component_id');

    return DecisionMaker::HostSelector->getHost(%args);
}

=head2 postStart

=cut

sub postStart {
}

1;
