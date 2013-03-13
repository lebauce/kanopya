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

TODO

=end classdoc

=cut

package EEntity::EComponent::EPhysicalhoster0;
use base "EEntity::EComponent";
use base "EManager::EHostManager";

use strict;
use warnings;

use Net::Ping;
use General;
use DecisionMaker::HostSelector;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;


sub startHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    if (not -e '/usr/sbin/etherwake') {
        $errmsg = "EOperation::EStartNode->startNode : /usr/sbin/etherwake not found";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
    my $iface = $self->getMasterNode->host->getAdminIface->iface_name;
    my $command = "/usr/sbin/etherwake -i " . $iface . " " . $args{host}->getPXEIface->iface_mac_addr;
    my $result = $self->_host->getEContext->execute(command => $command);

    my $current_state = $args{host}->getState();

    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $args{host}->can('save'),
            parameters => [ $args{host} ]
        );
        $args{erollback}->add(
            function   => $args{host}->can('setAttr'),
            parameters => [ $args{host}, "name" ,"host_state", "value", $current_state ]
        );
    }
}

sub stopHost {
}

=pod

=begin classdoc

Check up if the host is pingable

=end classdoc

=cut

sub checkUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $ip = $args{host}->adminIp;
    my $ping = Net::Ping->new("icmp");
    my $pingable = $ping->ping($ip, 2);
    $ping->close();
    return $pingable ? $pingable : 0;
}

1;
