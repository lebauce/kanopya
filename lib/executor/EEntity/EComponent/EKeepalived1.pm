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
package EEntity::EComponent::EKeepalived1;
use base 'EEntity::EComponent';

use strict;
use Date::Simple (':all');
use Log::Log4perl "get_logger";
use General;



my $log = get_logger("executor");
my $errmsg;

# called when a node is added to a cluster
sub addNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['mount_point', 'host']);

    my $keepalived = $self->_getEntity();
    my $masternodeip = $self->getServiceProvider->getMasterNodeIp();
        
    # recuperer les adresses ips publiques et les ports
    
    if(not defined $masternodeip) {

        # no masternode defined, this host becomes the masternode
        #  so it is the first initialization of keepalived
        
        # retrieve all public ips associated with the cluster
        my $publicips  = [];
        my $interfaces = $args{cluster}->getNetworkInterfaces();
        foreach my $interface (@{$interfaces}) {
            if ($interface->getRole()->getAttr(name => 'interface_role_name') eq "public") {
                my $networks = $interface->{_dbix}->interface_networks;
                while (my $interface_network = $networks->next) {
                    my $network = Entity::Network->get(id => $interface_network->get_column('network_id'));
                    my $poolIps = $network->getAssociatedPoolips();
                    foreach my $poolIp (@{$poolIps}) {
                        push(@{$publicips}, @{$poolIp->getAllIps()});
                    }
                }
            }
        }
                
        my $components = $args{cluster}->getComponents(category => 'all');

        # retrieved loadbalanced components and there ports
        my $ports = [];
        foreach my $component(values %$components) {
            if($component->getClusterizationType() eq 'loadbalanced') {
                my $netconf = $component->getNetConf();
                foreach my $port (keys %$netconf) {
                    push(@$ports, $port); 
                }
            }
        }
        
        foreach my $vip (@$publicips) {
            foreach my $port (@$ports) {
                
                #$log->debug("adding virtualserver  definition in database");
                my $vsid = $keepalived->addVirtualserver(
                    virtualserver_ip => $vip->addr(),
                    virtualserver_port => $port,
                    virtualserver_lbkind => 'NAT',
                    virtualserver_lbalgo => 'wlc');
                
                $log->debug("adding realserver definition in database");
                 my $rsid = $keepalived->addRealserver(
                    virtualserver_id => $vsid,
                    realserver_ip => $args{host}->getAdminIp,
                    realserver_port => $port,
                    realserver_checkport => $port,
                    realserver_checktimeout => 15,
                    realserver_weight => 1);
            }    
        }
    
        $log->debug("generate /etc/default/ipvsadm file");
        $self->generateIpvsadm(host => $args{host}, mount_point => $args{mount_point});
        
        $log->debug("generate /etc/keepalived/keepalived.conf file");
        $self->generateKeepalived(host => $args{host}, mount_point => $args{mount_point});
        
        $self->addInitScripts(
            mountpoint => $args{mount_point},
            scriptname => 'ipvsadm'
        );
            
        $self->addInitScripts(
            mountpoint => $args{mount_point}, 
            scriptname => 'keepalived'
        );
                                
        # activating ipv4 forwarding to sysctl
        $log->debug('activating ipv4 forwarding to sysctl.conf');
        my $command = "echo 'net.ipv4.ip_forward=1' >> $args{mount_point}/sysctl.conf";
        $log->debug($command);
        $self->getExecutorEContext->execute(command => $command);
    
    } else {
        # a masternode exists so we update his keepalived configuration
        $log->debug("Keepalived update");
        
        # add this host as realserver for each virtualserver of this cluster
        my $virtualservers = $keepalived->getVirtualservers();
        
        foreach my $vs (@$virtualservers) {
            my $rsid = $keepalived->addRealserver(
                virtualserver_id => $vs->{virtualserver_id},
                realserver_ip => $args{host}->getAdminIp,
                realserver_port => $vs->{virtualserver_port},
                realserver_checkport => $vs->{virtualserver_port},
                realserver_checktimeout => 15,
                realserver_weight => 2);
        }
        
        $log->debug('Generation of network_routes script');
        $self->addnetwork_routes(mount_point              => $args{mount_point},
                                 loadbalancer_internal_ip => $masternodeip);
        
        $log->debug('init script generation for network_routes script');
        $self->addInitScripts(
            mountpoint => $args{mount_point},
            scriptname => 'network_routes'
        );
 
        $self->generateAndSendKeepalived();
        $self->reload();
        
    }
}

sub preStopNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['host', 'cluster']);
    
    if ($args{cluster}->getMasterNodeIp() ne $args{host}->getAdminIp()) {
        my $keepalived      = $self->_getEntity();
        my $virtualservers  = $keepalived->getVirtualservers();
        
        foreach my $vs (@{$virtualservers}) {
            my $realserver_id = $keepalived->getRealserverId(virtualserver_id   => $vs->{virtualserver_id},
                                                             realserver_ip      => $args{host}->getAdminIp());
            
            $keepalived->setRealServerWeightToZero(virtualserver_id => $vs->{virtualserver_id},
                                                   realserver_id    => $realserver_id);
        }
        
        $self->generateAndSendKeepalived();
        $self->reload();
    }
}

# called when a node is removed from a cluster 
sub stopNode {
    my $self = shift;
    my %args = @_;
    
    my $keepalived = $self->_getEntity();
    my $masternodeip = $args{cluster}->getMasterNodeIp();
    if($masternodeip eq $args{host}->getAdminIp) {
        # this host is the masternode so we remove virtualserver definitions
        $log->debug('No master node ip retreived, we are stopping the master node');
        my $virtualservers = $keepalived->getVirtualservers();
        foreach my $vs (@$virtualservers) {
            $keepalived->removeVirtualserver(virtualserver_id => $vs->{virtualserver_id});
        }
        
    } else {
        my $virtualservers = $keepalived->getVirtualservers();
        
        foreach my $vs (@{$virtualservers}) {
            my $realserver_id = $keepalived->getRealserverId(virtualserver_id   => $vs->{virtualserver_id},
                                                             realserver_ip      => $args{host}->getAdminIp());
            
            $keepalived->removeRealserver(virtualserver_id  => $vs->{virtualserver_id},
                                          realserver_id     => $realserver_id);
        }
        
        $self->generateAndSendKeepalived();
        $self->reload();
    }
    
}

sub cleanNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['host', 'cluster', 'mount_point']);
    
    my $keepalived = $self->_getEntity();
    
    # remove this host as realserver for each virtualserver of this cluster
    my $virtualservers = $keepalived->getVirtualservers();

    foreach my $vs (@$virtualservers) {
       my $realserver_id = $keepalived->getRealserverId(virtualserver_id => $vs->{virtualserver_id},
                                                        realserver_ip => $args{host}->getAdminIp);


       $keepalived->removeRealserver(
                virtualserver_id => $vs->{virtualserver_id},
                realserver_id => $realserver_id);
    }

    # If masternode then delete virtual server entry in db
    my $masternodeip = $args{cluster}->getMasterNodeIp();
    if($masternodeip eq $args{host}->getAdminIp) {
        foreach my $vs (@$virtualservers) {
           $keepalived->removeVirtualserver(virtualserver_id => $vs->{virtualserver_id});
        }
    }
}

# Reload configuration of keepalived process
sub reload {
    my $self = shift;
    my %args = @_;

    my $command = "invoke-rc.d keepalived reload";
    my $result = $self->getEContext->execute(command => $command);
    return undef;
}

# generate /etc/keepalived/keepalived.conf configuration file
sub generateKeepalived {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['host','mount_point']);
    my $cluster = $self->_getEntity->getServiceProvider;
    my $host = $cluster->getMasterNode;
    $host = $args{host} if not defined $host;
    my $data = $self->_getEntity()->getTemplateDataKeepalived();
    my $file = $self->generateNodeFile(
        host          => $host,
        cluster       => $cluster,
        file          => '/etc/keepalived/keepalived.conf',
        template_dir  => '/templates/components/keepalived',
        template_file => 'keepalived.conf.tt',
        data          => $data
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/keepalived'
    );
}

sub generateAndSendKeepalived {
    my ($self, %args) = @_;
    
    my $data = $self->_getEntity()->getTemplateDataKeepalived();
    my $file = $self->generateNodeFile(
        host          => $self->getServiceProvider->getMasterNode,
        cluster       => $self->getServiceProvider,
        file          => '/etc/keepalived/keepalived.conf',
        template_dir  => '/templates/components/keepalived',
        template_file => 'keepalived.conf.tt',
        data          => $data
    );
   
    $self->getEContext()->send(
        src  => $file,
        dest => '/etc/keepalived'
    );
}

# generate /etc/default/ipvsadm configuration file for the master node
sub generateIpvsadm {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['host','mount_point']);
    my $cluster = $self->_getEntity->getServiceProvider;
    my $host = $cluster->getMasterNode;
    $host = $args{host} if not defined $host;
    my $data = $self->_getEntity()->getTemplateDataIpvsadm();
    my $file = $self->generateNodeFile(
        host          => $host,
        cluster       => $cluster,
        file          => '/etc/default/ipvsadm',
        template_dir  => '/templates/components/keepalived',
        template_file => 'default_ipvsadm.tt',
        data          => $data
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/default'
    );
}

# add network_routes script to the node 
sub addnetwork_routes {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['mount_point', 'loadbalancer_internal_ip']);
    
    my $data = {};
    $data->{gateway} = $args{loadbalancer_internal_ip};
    
    my $file = $self->generateNodeFile(
        host          => $self->getServiceProvider->getMasterNode,
        cluster       => $self->getServiceProvider,
        file          => '/etc/init.d/network_routes',
        template_dir  => '/templates/components/keepalived',
        template_file => 'network_routes.tt',
        data          => $data
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/init.d'
    );
    
    my $command = '/bin/chmod +x '.$args{mount_point}.'/etc/init.d/network_routes';
    $log->debug($command);
    my $result = $self->getExecutorEContext->execute(command => $command);
     
}

sub postStartNode{
    my $self = shift;
    my %args = @_;
    
    my $keepalived = $self->_getEntity();
    my $masternodeip = $args{cluster}->getMasterNodeIp();
    if($masternodeip eq $args{host}->getAdminIp) {
        # this host is the masternode so we remove virtualserver definitions
        $log->debug('First Node is started, nothing to do');
        return;        
    } else {
        $self->generateKeepalived(mount_point => '/etc');
        $self->reload();
    }
}
1;
