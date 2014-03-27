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

    my $command = '';
    my $additional_command = '';

    if (scalar($args{host}->ipmi_credentials) > 0) {
        
        $log->info('Start physical host with IPMI');

        my $ip = ($args{host}->ipmi_credentials)[0]->ipmi_credentials_ip_addr;
        my $login = ($args{host}->ipmi_credentials)[0]->ipmi_credentials_user;
        my $pass = ($args{host}->ipmi_credentials)[0]->ipmi_credentials_password;

        TOOLS:
        foreach ($self->_getIPMITools(ip => $ip, login => $login, pass => $pass)) {
            my $ipmitool = $_;
            my $ipmiclient = $self->_host->getEContext->which(command => $ipmitool->{bin});
            $log->info('Start physical host using ' . $ipmiclient);
            if ($ipmiclient ne "") {

                my $test_command = $ipmiclient . $ipmitool->{test_command};

                my $powerstatus = $self->_host->getEContext->execute(command => $test_command)->{stdout};

                if ($powerstatus =~/on/ ) {
                    my $errmsg = 'Physical host is already powered on (Host MAC is ' . 
                                 $args{host}->getPXEIface->iface_mac_addr . ', Host IPMI card is ' . $ip . ' )';
                    throw Kanopya::Exception::Execution::InvalidState(error => $errmsg);
                }

                $command = $ipmiclient . $ipmitool->{power_on_command};

                if (exists $ipmitool->{additional_bin}) {
                    my $additional_bin =  $self->_host->getEContext->which(command => $ipmitool->{additional_bin});
                    $additional_command = $additional_bin . $ipmitool->{args_additional};
                }

                last TOOLS;
            }
        }

        if ($command eq "") {
            throw Kanopya::Exception::Execution(error => 'no IPMI client found');
        }
    } else {
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

    $self->_host->getEContext->execute(command => $command);

    if ($additional_command ne '') {
        $self->_host->getEContext->execute(command => $additional_command);
    } 

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

    my $command = '';
    my $additional_command = '';

    # Implemented only with IPMI
    if (scalar($args{host}->ipmi_credentials) > 0) {
        $log->info('Stop physical host with IPMI');

        my $ip = ($args{host}->ipmi_credentials)[0]->ipmi_credentials_ip_addr;
        my $login = ($args{host}->ipmi_credentials)[0]->ipmi_credentials_user;
        my $pass = ($args{host}->ipmi_credentials)[0]->ipmi_credentials_password;

        TOOLS:
        foreach ($self->_getIPMITools(ip => $ip, login => $login, pass => $pass)) {
            my $ipmitool = $_;
            my $ipmiclient = $self->_host->getEContext->which(command => $ipmitool->{bin});
            $log->info('Stopping physical host using ' . $ipmiclient);
            if ($ipmiclient ne "") {
                $command = $ipmiclient . $ipmitool->{power_off_command};
                if (exists $ipmitool->{additional_bin}) {
                    my $additional_bin =  $self->_host->getEContext->which(
                                              command => $ipmitool->{additional_bin}
                                          );
                    $additional_command = $additional_bin . $ipmitool->{args_additional};
                }   
                last TOOLS;
            }
        }

        my $result = $self->_host->getEContext->execute(command => $command);

        if ($additional_command ne '') {
            $self->_host->getEContext->execute(command => $additional_command);
        }    
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

sub _getIPMITools {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => [ 'ip', 'login', 'pass' ]);

    my @ipmitools = (
        {  'bin'                => 'ipmi-chassis',
           'test_command'       => " -h $args{ip} -u $args{login} -p $args{pass} --get-status" .
                                        " -D LAN_2_0 | grep 'System Power'",
           'power_on_command'   => " -h $args{ip} -u $args{login} -p $args{pass} --chassis-control=POWER-UP" .
                                        " -D LAN_2_0",
           'power_off_command'  => " -h $args{ip} -u $args{login} -p $args{pass} --chassis-control=POWER-DOWN" .
                                        " -D LAN_2_0",
           'additional_bin'     => 'bmc-device',
           'args_additional'    => " -h $args{ip} -u $args{login} -p $args{pass} --cold-reset",
        },
        {  'bin'                => 'ipmitool',
           'test_command'       => " -H $args{ip} -U $args{login} -P $args{pass} chassis power status",
           'power_on_command'   => " -H $args{ip} -U $args{login} -P $args{pass} chassis power on",
           'power_off_command'  => " -H $args{ip} -U $args{login} -P $args{pass} chassis power off", 
        });
    return @ipmitools;
}

1;
