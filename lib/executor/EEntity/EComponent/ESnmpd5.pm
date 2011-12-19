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

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

# generate snmpd configuration files on node
sub addNode {
    my $self = shift;
    my %args = @_;
    
    if((! exists $args{econtext} or ! defined $args{econtext}) ||
        (! exists $args{host} or ! defined $args{host}) ||
        (! exists $args{mount_point} or ! defined $args{mount_point})) {
        $errmsg = "EComponent::ESnmpd5->configureNode needs a host, mount_point and econtext named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    
    my $conf = $self->_getEntity()->getConf();
    
    # generation of /etc/default/snmpd 
    my $data = {};
    $data->{node_ip_address} = $args{host}->getInternalIP()->{ipv4_internal_address};
    $data->{options} = $conf->{snmpd_options};       
    
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/snmpd",
                         input_file => "default_snmpd.tt", output => "/default/snmpd",
                          data => $data);
                         
    # generation of /etc/snmpd/snmpd.conf 
    $data = {};
    $data->{monitor_server_ip} = $conf->{monitor_server_ip};

    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/snmpd",
                         input_file => "snmpd.conf.tt", output => "/snmp/snmpd.conf",
                          data => $data);

    
    # add snmpd init scripts
    $self->addInitScripts(
        etc_mountpoint => $args{mount_point},
        econtext => $args{econtext},
        scriptname => 'snmpd',
        startvalue => 20,
        stopvalue => 20
    );
          
}

# Reload snmp process
sub reload {
    my $self = shift;
    my %args = @_;
    
    if(! exists $args{econtext} or ! defined $args{econtext}) {
        $errmsg = "EComponent::ESnmpd5->reload needs an econtext named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $command = "invoke-rc.d snmpd restart";
    my $result = $args{econtext}->execute(command => $command);
    return undef;
}

1;
