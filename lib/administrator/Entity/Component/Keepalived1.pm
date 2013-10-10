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
use Entity::Interface;
use Entity::Component::Keepalived1::Keepalived1Vrrpinstance;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

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

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'conf' ]);

    my $conf = $args{conf};

    # Pop and link an IP for each new vrrp instance (according to associated virtualip interface)
    for my $instance (@{ $conf->{keepalived1_vrrpinstances} }) {
        if (not exists $instance->{vrrpinstance_id}) {
            my $interface = Entity::Interface->get(id => $instance->{virtualip_interface_id});

            my @netconfs  = $interface->netconfs;
            if (0 == scalar @netconfs) {
                throw Kanopya::Exception::Internal(
                    error => "No network configuration linked to interface '".$interface->interface_name."'"
                );
            }

            my @poolips = $netconfs[0]->poolips;
            if (0 == scalar @poolips) {
                throw Kanopya::Exception::Internal(
                    error => "No pool ips linked to first network configuration of interface '"
                             .$interface->interface_name."'"
                );
            }

            my $poolip = $poolips[0];
            my $new_ip = $poolip->popIp();

            $instance->{virtualip_id} = $new_ip->id;
        }
    }

    $self->SUPER::setConf(%args);
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
        return $self->SUPER::getPuppetDefinition(%args);
    }

    my @vrrp_instances = $self->keepalived1_vrrpinstances;
    my @vrrp_members = map { $_->vrrpinstance_name } @vrrp_instances;
    
    # global config
    $manifest = $self->instanciatePuppetResource(
                    name => "kanopya::keepalived",
                    params => {
                        email => $self->notification_email,
                        smtp_server => $self->smtp_server
                    }
                );

    # vrrp config 
    if (scalar(@vrrp_instances)) {
        # vrrp sync group

        $manifest .= $self->instanciatePuppetResource(
                         name => 'VG1',
                         resource => "keepalived::vrrp_sync_group",
                         params => {
                             members => \@vrrp_members
                         }
                     );

        # vrrp instances
        for my $instance (@vrrp_instances) {
            # we find host iface associated with cluster interface
            my $iface_name = $self->getHostIface(host => $args{host}, 
                                                 interface => $instance->interface);
        
            # ip must have format: 192.168.222.100/24 dev eth0
            $manifest .= $self->instanciatePuppetResource(
                name => $instance->vrrpinstance_name,
                resource => "keepalived::vrrp_instance",
                params => {
                    kind => $state,
                    interface => $iface_name,
                    password => 'mypassword',
                    virtual_router_id => 1,
                    virtual_addresses => [ $instance->virtualip->getStringFormat .
                                           " dev " .
                                           $self->getHostIface(
                                               host => $args{host},
                                               interface => $instance->virtualip_interface
                                           ) ]
                }
            );
        }
    }

    return merge($self->SUPER::getPuppetDefinition(%args), {
        keepalived => {
            manifest => $manifest
        }
    } );
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
