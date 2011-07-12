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

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new( %args );
    return $self;
}


# generate de script iptables dans /etc/init.d/firewall
sub configureNode {
    my $self = shift;
    my %args = @_;
        
    General::checkParams(args => \%args, required => ['econtext', 'motherboard', 'mount_point']);
     #TODO insert configuration files generation
    
    my $cluster = $args{cluster};
    my $components = $cluster->getComponents();
    
    my $data = { components => [] };
    foreach my $component (values %$components) {
        my $netconf = $component->getNetConf();
        while(my ($port, $protocols) = each %$netconf) {
            my $tmp = {};
            $tmp->{port} = $port;
            push (@{$data->{components}}, $tmp);
            $tmp->{ protocol}= $protocol;
            if (($tmp->{ protocol}= $protocol) eq 'ssl'){
                }
                else {
            push (@{$data->{components}}, $tmp);    
            }
          }
    }
        
     #my $iptables_conf = $self->_getEntity()->getGeneralConf();   
    #$data->{port} = $iptables_conf->{'module_port'};
    #$data->{portNumber} = $iptables_conf->{'module_number_port'};
   
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/",
                         input_file => "Iptables.tt", output => "/init.d/firewall", data => $data);             

  
 # status iptables
 
    $self->addInitScripts(      econtext => $args{econtext}, 
                                scriptname => 'firewall', 
                                startvalue => '15', 
                                stopvalue => '09');
    
}
sub addNode {
    my $self = shift;
    my %args = @_;    
    General::checkParams(args => \%args, required => ['econtext', 'motherboard', 'mount_point']);
    $self->configureNode(%args);
    
    #TODO addInitScript(..) if there is a daemon associated to this component
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

