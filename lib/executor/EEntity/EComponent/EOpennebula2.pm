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
package EEntity::EComponent::EOpennebula2;

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

# generate configuration files on node
sub configureNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'motherboard', 'mount_point']);

    my $masternodeip = $args{cluster}->getMasterNodeIp();
    
    
    if($masternodeip) {
        # this is an opennebula cluster node 
    
    } else {
       # this is the opennebula frontend 
       
       $log->debug('generate etc/oned.conf generation');       
       $self->generateOnedConf(econtext => $args{econtext}, mount_point => $args{mount_point});
       
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
                         input_file => "oned.conf.tt", output => "/nfsexports/opennebula/cloud/one/etc/oned.conf", data => $data);          
 
}

# generate /etc/default/libvirt-bin configuration file
sub generateLibvirtbin {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point']);
    
    my $data = $self->_getEntity()->getTemplateDataLibvirtbin();
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "libvirt-bin.tt", output => "/etc/default/libvirtd-bin", data => $data);            
 
}

# generate /etc/libvirt/libvirtd.conf configuration file
sub generateLibvirtdconf {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point']);
    
    my $data = $self->_getEntity()->getTemplateDataLibvirtd();
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "libvirtd.conf.tt", output => "/etc/libvirt/libvirtd.conf", data => $data);            
 
}

# generate /etc/init.d/oned init script
sub generateOnedinitscript {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'mount_point']);
    
    my $data = $self->_getEntity()->getTemplateDataOnedInitScript();
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/opennebula",
                         input_file => "oned_initscript.tt", output => "/etc/init.d/oned", data => $data);            
 
} 


sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'motherboard', 'mount_point']);
    
    $self->configureNode(%args);
    
    
}

sub postStartNode{}

sub preStopNode {}


# Reload process
sub reload {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);

}

1;
