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

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";
use General;
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

# generate de script iptables dans /etc/init.d/firewall
sub configureNode {
    my $self = shift;
    my %args = @_;
        
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point', 'cluster']);

     #TODO insert configuration files generation
    my $cluster = $args{cluster};
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
     $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point}.'/etc',
             template_dir => "/templates/components/iptables",
             input_file => "Iptables.tt", output => '/init.d/firewall', data => $data);             
     my $command = '/bin/chmod +x '.$args{mount_point}.'/etc/init.d/firewall';
     my $result = $args{econtext}->execute(command => $command);        
     $log->debug(Dumper $result);
     
#    my $a=$self->_getEntity()->getClusterIp();
#    $log->debug(">>>>>>>" . Dumper $data);
#    print Dumper $data ;
}



               
sub addNode {
    my $self = shift;
    my %args = @_;    
    General::checkParams(args => \%args, required => ['econtext', 'host', 'mount_point', 'cluster']);

    $self->configureNode(
           econtext => $args{econtext},
               host => $args{host},
        mount_point => $args{mount_point}.'/etc',
            cluster => $args{cluster}
    );
    
    #TODO addInitScript(..) if there is a daemon associated to this component
    # status iptables 
    $self->addInitScripts(      
        mountpoint => $args{mount_point}, 
          econtext => $args{econtext}, 
        scriptname => 'firewall', 
    );
}


# Reload process
sub activate{
   my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);
    my $command = '/bin/chmod +x'.$args{mount_point}.'/init.d/firewall';
    my $result = $args{econtext}->execute(command => $command);
    return undef;
}   



  
sub reload {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);

    my $command = "invoke-rc.d iptables restart";
    my $result = $args{econtext}->execute(command => $command);
    return undef;
}

1;
