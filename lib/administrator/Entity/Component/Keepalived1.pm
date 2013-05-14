# Keepalived1.pm -Keepalive (load balancer) component (Adminstrator side)
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 22 august 2010

package Entity::Component::Keepalived1;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Entity::Interface;
use Entity::Component::Keepalived1::Keepalived1Vrrpinstance;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    notification_email => {
        label          => 'Notification email',
        type           => 'string',
        pattern        => '^.*$',
        is_mandatory   => 1,
        is_editable    => 1
    },
    smtp_server      => {
        label        => 'SMTP server',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    keepalived1_vrrpinstances => {
        label       => 'High Available IP',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1
    },
};
sub getAttrDef { return ATTR_DEF; }

sub getBaseConfiguration {
    return {
        notification_email      => 'admin@mycluster.com',
        smtp_server             => '127.0.0.1',
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;
    my $manifest = "";
    my $state;
    # first we check if we need to deploy a new keepalived 
    my $node_number = $args{host}->node->node_number;
    if($node_number == 1) {
        $state = 'MASTER';
    } elsif($node_number == 2) {
        $state = 'BACKUP';
    } else {
        return $manifest;
    }
    
    my $email = $self->notification_email;
    my $smtp_server = $self->smtp_server;
    
    my @vrrp_instances = $self->keepalived1_vrrpinstances;
    
    # global config
    $manifest .= "class { 'kanopya::keepalived': }\n\n";
    $manifest .= "class { 'concat::setup': }\n\n";
    $manifest .= "class { 'keepalived':\n";
    $manifest .= "   email       => '$email',\n";
    $manifest .= "   smtp_server => '$smtp_server'\n";
    $manifest .= "}\n\n";
    
    # vrrp config 
    if(scalar(@vrrp_instances)) {
        # vrrp sync group
        $manifest .= "keepalived::vrrp_sync_group { 'VG1':\n";
        $manifest .= "  members => [";
        $manifest .= join(',', map { "'".$_->vrrpinstance_name."'" } @vrrp_instances);
        $manifest .= "]\n";
        $manifest .= "}\n\n";
    
        # vrrp instances
        for my $instance (@vrrp_instances) {
            # we find host iface associated with cluster interface
            my $iface_name = $self->getHostIface(host => $args{host}, 
                                                 interface => $instance->interface);
        
            $manifest .= "keepalived::vrrp_instance { '".$instance->vrrpinstance_name."':\n";
            $manifest .= "  kind              => '".$state."',\n";
            $manifest .= "  interface         => '".$iface_name."',\n"; 
            $manifest .= "  password          => 'mypassword',\n";
            $manifest .= "  virtual_router_id => 1,\n";
            $manifest .= "  virtual_addresses => [";
            # ip must have format: 192.168.222.100/24 dev eth0
            $manifest .= join(',', map { "'".$_->getStringFormat." dev ".$self->getHostIface(host => $args{host}, interface => $_->interface)."'" } 
                                   $instance->keepalived1_virtualips);
            $manifest .= "]\n";
            $manifest .= "}\n\n";
        }
    }

    return {
        manifest     => $manifest,
        dependencies => []
    };
}

sub getHostIface {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['interface','host']);
    my @netconfs = $args{interface}->netconfs;
    my $netconfig = pop @netconfs;
    my $iface_name;
    IFACE:
    for my $iface ($args{host}->ifaces) {
        NETCONF:
        for my $netconf ($iface->netconfs) {
            if($netconfig->id == $netconf->id) {
                $iface_name = $iface->iface_name;
                last IFACE;
            }
        }
    }
    return $iface_name;
}

1;
