#    Copyright © 2011 Hedera Technology SAS
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
package EEntity::EComponent::ESnmpd5;
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

# generate snmpd configuration files on node
sub addNode {
    my ($self, %args) = @_;
    
    General::checkParams(args     => \%args,
                         required => ['cluster','host','mount_point']);

    my $conf = $self->_getEntity()->getConf();

    # generation of /etc/default/snmpd 
    my $data = {};
    $data->{node_ip_address} = $args{host}->getAdminIp;
    $data->{options} = $conf->{snmpd_options};       
    
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/default/snmpd',
        template_dir  => '/templates/components/snmpd',
        template_file => 'default_snmpd.tt',
        data          => $data
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/default',
    );
    
    # generation of /etc/snmpd/snmpd.conf 
    $data = {};
    $data->{monitor_server_ip} = $conf->{monitor_server_ip};

    $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/snmp/snmpd.conf',
        template_dir  => '/templates/components/snmpd',
        template_file => 'snmpd.conf.tt',
        data          => $data
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/snmp',
    );

    # add snmpd init scripts
    $self->addInitScripts(
        mountpoint => $args{mount_point},
        scriptname => 'snmpd',
    );
}

# Reload snmp process
sub reload {
    my ($self, %args) = @_;
    my $command = "invoke-rc.d snmpd restart";
    my $result = $self->getEContext->execute(command => $command);
    return undef;
}

1;
