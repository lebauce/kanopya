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
package EEntity::EComponent::EOpennebula3;
use base "EEntity::EComponent";

use strict;
use Template;
use String::Random;

use Log::Log4perl "get_logger";
use General;

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

# generate configuration files on node
sub configureNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point']);

    my $masternodeip = $args{cluster}->getMasterNodeIp();
     
    if($masternodeip) {
        # this is an opennebula cluster node
        $log->info("Opennebula cluster's node configuration");
        $log->debug('generate /etc/default/libvirt-bin');    
        $self->generateLibvirtbin(econtext => $args{econtext}, mount_point => $args{mount_point});
        
        $log->debug('generate /etc/libvirt/libvirtd.conf');    
        $self->generateLibvirtdconf(
            econtext    => $args{econtext}, 
            mount_point => $args{mount_point}, 
            host => $args{host}
        );

		$log->debug('generate /etc/libvirt/qemu.conf');    
        $self->generateQemuconf(
            econtext    => $args{econtext}, 
            mount_point => $args{mount_point}, 
            host => $args{host}
        );

		$self->addInitScripts(
          etc_mountpoint => $args{mount_point}, 
                econtext => $args{econtext}, 
              scriptname => 'kvm', 
              startvalue => 20, 
               stopvalue => 20
       );
        
        $self->addInitScripts(
          etc_mountpoint => $args{mount_point}, 
                econtext => $args{econtext}, 
              scriptname => 'libvirt-bin', 
              startvalue => 20, 
               stopvalue => 20
       );
       
       $self->addInitScripts(
          etc_mountpoint => $args{mount_point}, 
                econtext => $args{econtext}, 
              scriptname => 'dnsmasq', 
              startvalue => 40, 
               stopvalue => 1
       );
       
       
    } else {
       # this is the opennebula frontend 
       $log->info('opennebula frontend configuration');
       $log->debug('generate etc/oned.conf');       
       
       # mount_point must stay empty since oned.conf dis copied to nfsexports directory 
       $self->generateOnedConf(econtext => $args{econtext}, mount_point => '');
       
       $log->debug('init script generation for oned script');
       $self->generateOnedinitscript(econtext => $args{econtext}, mount_point => $args{mount_point});
       
       $self->addInitScripts(
          etc_mountpoint => $args{mount_point}, 
                econtext => $args{econtext}, 
              scriptname => 'oned', 
              startvalue => 40, 
              stopvalue => 1
       );
    }
}

# generate $ONE_LOCATION/etc/oned.conf configuration file
sub generateOnedConf {
     my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point']);
    
    my $data = $self->_getEntity()->getTemplateDataOned();
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "oned.conf.tt", output => "/nfsexports/one3/etc/oned.conf", data => $data);          
 
}

# generate /etc/default/libvirt-bin configuration file
sub generateLibvirtbin {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point']);
    
    my $data = $self->_getEntity()->getTemplateDataLibvirtbin();
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "libvirt-bin.tt", output => "/default/libvirt-bin", data => $data);            
 
}

# generate /etc/libvirt/libvirtd.conf configuration file
sub generateLibvirtdconf {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point', 'host']);
    
    my $data = $self->_getEntity()->getTemplateDataLibvirtd();
    $data->{listen_ip_address} = $args{host}->getInternalIP()->{ipv4_internal_address};
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "libvirtd.conf.tt", output => "/libvirt/libvirtd.conf", data => $data);            
 
}

# generate /etc/libvirt/qemu.conf configuration file
sub generateQemuconf {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point', 'host']);
    
    my $data = {};
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "qemu.conf.tt", output => "/libvirt/qemu.conf", data => $data); 
}


# generate /etc/init.d/oned init script
sub generateOnedinitscript {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point']);
    
    my $data = $self->_getEntity()->getTemplateDataOnedInitScript();
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "oned_initscript.tt", output => "/init.d/oned", data => $data);            
    my $command = '/bin/chmod +x '.$args{mount_point}.'/init.d/oned';
    $log->debug($command);
    my $result = $args{econtext}->execute(command => $command);
} 


sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point']);
    
    $self->configureNode(%args);
    
    
}

sub postStartNode {
     my $self = shift;
     my %args = @_;
     my $masternodeip = $args{cluster}->getMasterNodeIp();
     my $nodeip = $args{host}->getInternalIP()->{ipv4_internal_address};
     if($masternodeip eq $nodeip) {
         # this host is the master node so we do nothing
     } else {
         # this host is a new cluster node so we declare it to opennebula
         my $command = $self->_oneadmin_command(command => "onehost create $nodeip im_kvm vmm_kvm tm_shared");
         use EFactory;
         my $masternode_econtext = EFactory::newEContext(ip_source => '127.0.0.1', ip_destination => $masternodeip);
		 sleep(10);
         my $result = $masternode_econtext->execute(command => $command);
     }
}

sub preStopNode {
     #~ my $self = shift;
     #~ my %args = @_;
     #~ my $masternodeip = $args{cluster}->getMasterNodeIp();
     #~ my $nodeip = $args{host}->getInternalIP()->{ipv4_internal_address};
     #~ if($masternodeip eq $nodeip) {
         #~ # this host is the master node so we do nothing
     #~ } else {
         #~ # this host is a new cluster node so we declare it to opennebula
         #~ my $command = $self->_oneadmin_command(command => "onehost delete $nodeip");
         #~ use EFactory;
         #~ my $masternode_econtext = EFactory::newEContext(ip_source => '127.0.0.1', ip_destination => $masternodeip);
		 #~ sleep(10);
         #~ my $result = $masternode_econtext->execute(command => $command);
     #~ }
}

sub isUp {
    my $self = shift;
    my %args = @_;
    
    General::checkParams( args => \%args, required => ['cluster', 'host', 'host_econtext'] );
    my $ip = $args{host}->getInternalIP()->{ipv4_internal_address};
    
    if($args{cluster}->getMasterNodeIp() eq $ip) {
        # host is the opennebula frontend
        # we must test opennebula port reachability
        my $net_conf = $self->{_entity}->getNetConf();
        my ($port, $protocols) = each %$net_conf;
        my $cmd = "nmap -n -sT -p $port $ip | grep $port | cut -d\" \" -f2";
        my $port_state = `$cmd`;
        chomp($port_state);
        $log->debug("Check host <$ip> on port $port ($protocols->[0]) is <$port_state>");
        if ($port_state eq "closed"){
            return 0;
        }
        return 1;          
    } else {
        # host is an hypervisor node
        # we must test libvirtd port reachability
        my $port = 16509;
        my $proto = 'tcp';
        my $cmd = "nmap -n -sT -p $port $ip | grep $port | cut -d\" \" -f2";
        my $port_state = `$cmd`;
        chomp($port_state);
        $log->debug("Check host <$ip> on port $port ($proto) is <$port_state>");
        if ($port_state eq "closed"){
            return 0;
        }
        return 1;
    }   
}

# prefix commands to use oneadmin account with its environment variables
sub _oneadmin_command {
	my $self = shift;
	my %args = @_;
	General::checkParams(args => \%args, required => ['command']);
	
	my $config = $self->_getEntity()->getConf();
	my $command = "su oneadmin -c '";
    $command .= "export ONE_XMLRPC=http://localhost:$config->{port}/RPC2 ; ";
	$command .= "export ONE_LOCATION=$config->{install_dir} ; ";
	$command .= "export ONE_AUTH=\$ONE_LOCATION/one_auth ; ";
	$command .= "PATH=\$ONE_LOCATION/bin:\$PATH ; ";
	$command .= $args{command} ."'";
	return $command;
}

1;
