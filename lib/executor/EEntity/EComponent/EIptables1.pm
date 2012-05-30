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
package EEntity::EComponent::EIptables1;
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl "get_logger";
use General;
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

# generate de script iptables dans /etc/init.d/firewall
sub configureNode {
    my ($self, %args) = @_;
        
    General::checkParams(args => \%args, required => ['host', 'mount_point']);

     #TODO insert configuration files generation
    my $cluster = $self->_getEntity->getServiceProvider;
    my $data = {};
       
    my $components = $cluster->getComponents(category => "all"); 
    my $components_instance=$self->_getEntity()->getComponentInstance();
    my $iptables_components= $self->_getEntity()->getIptables1Component();
   
   #my $adresse=$self->$cluster->getMasterNodeIp();
    my $clusteraddress=$self->_getEntity()->getClusterIp();
      $data->{clusteraddress}=$clusteraddress; 
     $data->{components}=[];
     COMPONENT:
    foreach my $component_instance (@$components_instance){
        foreach my $iptables_component (@$iptables_components) {
	       if ($component_instance->{iptables1_component_instance_id} == $iptables_component){
	           next COMPONENT;   
	       }
        }
	       my $component = $cluster->getComponentByInstanceId(component_instance_id => $component_instance->{iptables1_component_instance_id});
	       my $netconf = $component->getNetConf();
           while(my ($port, $protocols) = each %$netconf) {
                PROTOCOL:         
                foreach my $element (@$protocols){
                    if ($element eq 'ssl') {
                        next PROTOCOL; 
                    }
                    my $tmp = {};
                    $tmp->{port} = $port;
                    $tmp->{protocol}= $element;
                    push (@{$data->{components}}, $tmp); 
                    }
           } 
        
     }
     
     #$data->{clusteraddress} = $clusteraddress;
     
     my $iptables_secure= $self->_getEntity()->getSecureRule();
     TABLE:
     foreach my $element (keys (%$iptables_secure)){
        if ($$iptables_secure{$element} == 1){
            $data->{$element} = $$iptables_secure{$element};     
        }
     }
     
     my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/init.d/firewall',
        template_dir  => '/templates/components/iptables',
        template_file => 'Iptables.tt',
        data          => $data 
    );
    
     $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/init.d'
    );


     my $command = '/bin/chmod +x '.$args{mount_point}.'/etc/init.d/firewall';
     my $result = $self->getExecutorEContext->execute(command => $command);
     $log->debug(Dumper $result);
     
#    my $a=$self->_getEntity()->getClusterIp();
#    $log->debug(">>>>>>>" . Dumper $data);
#    print Dumper $data ;
}



               
sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['host', 'mount_point', 'cluster']);

    $self->configureNode(%args);
    
    #TODO addInitScript(..) if there is a daemon associated to this component
    # status iptables 
    $self->addInitScripts(      
        mountpoint => $args{mount_point}, 
        scriptname => 'firewall', 
    );
}






  
sub reload {
    my ($self, %args) = @_;
    my $command = "invoke-rc.d iptables restart";
    my $result = $self->getEContext->execute(command => $command);
    return undef;
}

1;
