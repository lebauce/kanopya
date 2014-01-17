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

    my $command;  

    if (scalar($args{host}->ipmi_credentials > 0)) {
        
        $log->info('Start physical host with IPMI');

        my $ipmicreds = ($args{host}->ipmi_credentials)[0];
        my $ipmitool = '/usr/bin/ipmitool';
        
        if (not -e $ipmitool) {
            $errmsg = 'EOperation::EStartNode->startNode : command \'ipmitool\' not found';
            throw Kanopya::Exception::Execution(error => $errmsg);
        }

        $command = $ipmitool . ' -H ' . $ipmicreds->ipmi_credentials_ip_addr . ' -U ' .
                   $ipmicreds->ipmi_credentials_user . ' -P '. $ipmicreds->ipmi_credentials_password .
                   ' chassis power status';
        my $powerstatus = $self->_host->getEContext->execute(command => $command);

        if ($powerstatus->{stdout} =~/on/ ) {
            my $errmsg = 'Physical host is already powered on (Host MAC is ' . $args{host}->getPXEIface->iface_mac_addr .
                         ', Host IPMI card is ' . $ipmicreds->ipmi_credentials_ip_addr . ' )';
            throw Kanopya::Exception::Execution::InvalidState(error => $errmsg);
        }

        $command = $ipmitool . ' -H ' . $ipmicreds->ipmi_credentials_ip_addr .
                   ' -U ' . $ipmicreds->ipmi_credentials_user . ' -P ' .
                   $ipmicreds->ipmi_credentials_password . ' chassis power on';
    }
    else {
        $log->info('Start physical host with Wake On Lan');
        
        my $wol = '/usr/sbin/etherwake';

        if (not -e $wol) {
            $wol = '/usr/bin/wol';
            if (not -e $wol) {
                $errmsg = "EOperation::EStartNode->startNode : Neither 'etherwake' nor 'wol' command where found";
                throw Kanopya::Exception::Execution(error => $errmsg);
            }
            $wol .= " --host " . $args{host}->getPXEIface->getIPAddr;
        }
        else {
            $wol .= " -i " . $self->getMasterNode->host->getAdminIface->iface_name;
        }

        $command = $wol . " " . $args{host}->getPXEIface->iface_mac_addr; 
    }
    
    my $result = $self->_host->getEContext->execute(command => $command);

    my $current_state = $args{host}->getState();

    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $args{host}->_entity->can('save'),
            parameters => [ $args{host} ]
        );
        $args{erollback}->add(
            function   => $args{host}->_entity->can('setAttr'),
            parameters => [ $args{host}, "name" ,"host_state", "value", $current_state ]
        );
    }
}

sub stopHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    # Implemented only with IPMI
    if (scalar($args{host}->ipmi_credentials > 0)) {
        $log->info('Stop physical host with IPMI');

        my $ipmicreds = ($args{host}->ipmi_credentials)[0];
        my $ipmitool = '/usr/bin/ipmitool';
        if (not -e $ipmitool) {
            $errmsg = 'EOperation::EStopNode->stopNode : command \'ipmitool\' not found';
            throw Kanopya::Exception::Execution(error => $errmsg);
        }

        my $command = $ipmitool . ' -H ' . $ipmicreds->ipmi_credentials_ip_addr . ' -U ' .
                      $ipmicreds->ipmi_credentials_user . ' -P ' . $ipmicreds->ipmi_credentials_password .
                      ' chassis power off';
        my $result = $self->_host->getEContext->execute(command => $command);
    }
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
