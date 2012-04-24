# Host.pm - Object class of Ḿotherboard (Administrator side)

#    Copyright © 2011-2012 Hedera Technology SAS
#
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

package Entity::Host;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Operation;
use General;
use Administrator;
use Entity::Container;

use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("administrator");
my $errmsg;

=head2 Host Attributes

hostmodel_id : Int : Identifier of host model.
processormodel_id : Int : Identifier of host processor model
kernel_id : Int : kernel identifier which will be used by host if non specified by cluster
host_serial_number : String : This is the serial number attributed to host

host_powersupply_id : Int : Facultative identifier to know which powersupplycard and port is used.
Powersupplyid is created during host creation.
host_desc :  String : This is a free field to enter a description of host. It is generally used to
specify owner, team, ...

active : Int : This is an internal parameter used to activate or deactivate resources on Kanopya System
host_hostname : Hostname is also internally managed. Host hostname will be generated from the mac address
It is generated when a host is added into a cluster
host_initiatorname : This attributes is generated when a host is added in a cluster and allow to connect
to internal storage to get the systemimage
host_state : String : This parameter is internally managed, it allows to follow migration step.
It could be :
- WaitingStart
- Starting
- ReadyStart
- Up

- WaitingStop
- ReadyStop
- Stopping
- Down
=cut

use constant ATTR_DEF => {
    host_manager_id => {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0
    },
    hostmodel_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    processormodel_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    kernel_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    host_serial_number => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    host_powersupply_id => {
        pattern      => '^\w*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    host_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    active => {
        pattern      => '^[01]$',
        is_mandatory => 0,
        is_extended  => 0
    },
    host_hostname => {
        pattern      => '^\w*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    host_ram => {
        pattern      => '^\w*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    host_core => {
        pattern      => '^\w*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    host_initiatorname => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    host_state => {
        pattern      => '^up:\d*|down:\d*|starting:\d*|stopping:\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'create'    => {'description' => 'create a new host',
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this host',
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this host',
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this host',
                        'perm_holder' => 'entity',
        },
        'activate'=> {'description' => 'activate this host',
                        'perm_holder' => 'entity',
        },
        'deactivate'=> {'description' => 'deactivate this host',
                        'perm_holder' => 'entity',
        },
        'addHarddisk'=> {'description' => 'add a hard disk to this host',
                        'perm_holder' => 'entity',
        },
        'removeHarddisk'=> {'description' => 'remove a hard disk from this host',
                        'perm_holder' => 'entity',
        },
        'removeInterface'=> {'description' => 'remove an interface from this host',
                        'perm_holder' => 'entity',
        },
        'addIface'=> {'description' => 'add one or more interface to  this host',
                        'perm_holder' => 'entity',
        },

        'setperm'    => {'description' => 'set permissions on this host',
                        'perm_holder' => 'entity',
        },
    };
}

=head2 getServiceProvider

    desc: Return the service provider that provides the host.

=cut

sub getServiceProvider {
    my $self = shift;

    my $service_provider_id = $self->getHostManager->getAttr(name => 'service_provider_id');

    return Entity::ServiceProvider->get(id => $service_provider_id);
}

=head2 getHostManager

    desc: Return the component/conector that manage this host.

=cut

sub getHostManager {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => 'host_manager_id'));
}

=head2 getState

=cut

sub getState {
    my $self = shift;
    my $state = $self->{_dbix}->get_column('host_state');
    return wantarray ? split(/:/, $state) : $state;
}

sub getPrevState {
    my $self = shift;
    my $state = $self->{_dbix}->get_column('host_prev_state');
    return wantarray ? split(/:/, $state) : $state;
}

=head2 setState

=cut

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['state']);
    my $new_state = $args{state};
    my $current_state = $self->getState();
    $self->{_dbix}->update({'host_prev_state' => $current_state,
                            'host_state' => $new_state.":".time})->discard_changes();;
}

=head2 getNodeState

=cut

sub getNodeState {
    my $self = shift;
    my $state = $self->{_dbix}->node->get_column('node_state');
    return wantarray ? split(/:/, $state) : $state;
}

=head2 getNodeNumber

=cut
sub getNodeNumber {
    my $self = shift;
    my $node_number = $self->{_dbix}->node->get_column('node_number');
    return $node_number;
}

=head2 getNodeSystemimage

=cut

sub getNodeSystemimage {
    my $self = shift;

    my $systemimage_id = $self->{_dbix}->node->get_column('systemimage_id');
    return Entity::Systemimage->get(id => $systemimage_id);
}

=head2 getHostRAM
=cut
sub getHostRAM {
    my $self = shift;
    my $host_ram = $self->{_dbix}->get_column('host_ram');
    return $host_ram;
}

=head2 getHostCore
=cut
sub getHostCORE {
    my $self = shift;
    my $host_core = $self->{_dbix}->get_column('host_core');
    return $host_core;
}

sub setNodeNumber {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['node_number']);
    my $best_node_number = $args{'node_number'};
    $self->{_dbix}->node->update({'node_number' => $best_node_number});
}

sub getPrevNodeState {
    my $self = shift;
    my $state = $self->{_dbix}->node->get_column('node_prev_state');
    return wantarray ? split(/:/, $state) : $state;
}

=head2 setNodeState

=cut

sub setNodeState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    my $new_state = $args{state};
    my $current_state = $self->getNodeState();
    $self->{_dbix}->node->update({
        node_prev_state => $current_state,
        node_state      => $new_state . ":" . time
    })->discard_changes();
}

=head2 Entity::Host->becomeNode (%args)

    Class : Public

    Desc : Create a new node instance in db from host linked to cluster (in params).

    args:
        inside_id : Int : inside identifier
        master_node : Int : 0 or 1 to say if the host is the master node
    return: Node identifier

=cut

sub becomeNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'inside_id', 'master_node',
                                       'node_number', 'systemimage_id' ]);

    my $adm = Administrator->new();
    my $res = $adm->{db}->resultset('Node')->create({
                  inside_id      => $args{inside_id},
                  host_id        => $self->getAttr(name => 'host_id'),
                  master_node    => $args{master_node},
                  node_number    => $args{node_number},
                  systemimage_id => $args{systemimage_id},
              });

    return $res->get_column("node_id");
}

=head2 Entity::Host->addIface (%args)

    Class : Public

    Desc : Create a new iface instance in db.

    args:
        iface_name : Char : interface identifier
        iface_mac_addr : Char : the mac address linked to iface
        iface_pxe:Int :0 or 1 
        host_id: Int 
        
    return: iface identifier

=cut

sub addIface {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'iface_name', 'iface_mac_addr', 'iface_pxe' ]);

    my $adm = Administrator->new();
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id},
                                                   method    => 'addIface');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(
                  error => "Permission denied to add an interface to this host"
              );
    }
    my $res = $adm->{db}->resultset('Iface')->create(
                  { iface_name     => $args{iface_name},
                    iface_mac_addr => $args{iface_mac_addr},
                    iface_pxe      => $args{iface_pxe},
                    host_id        => $self->getAttr(name => 'host_id') }
              );

    return $res->get_column("iface_id");
}

=head2 getIfaces

=cut

sub getIfaces {
    my $self = shift;
    my $ifcs = [];
    my $interfaces = $self->{_dbix}->ifaces;
    while(my $ifc = $interfaces->next) {
        my $tmp = {};
        $tmp->{iface_id}       = $ifc->get_column('iface_id');
        $tmp->{iface_name}     = $ifc->get_column('iface_name');
        $tmp->{iface_mac_addr} = $ifc->get_column('iface_mac_addr');
        $tmp->{iface_pxe}      = $ifc->get_column('iface_pxe');
        
        push @$ifcs, $tmp;
    }
    return wantarray ? @$ifcs : $ifcs;
}

=head2 getPXEMacAddress

=cut

sub getPXEMacAddress {
    my $self = shift;

    my $interfaces = $self->{_dbix}->ifaces;
    while(my $ifc = $interfaces->next) {
        if ($ifc->get_column('iface_pxe')) {
            return $ifc->get_column('iface_mac_addr');
        }
    }
}

sub removeInterface {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['iface_id']);

    my $adm = Administrator->new();
    # removeInterface method concerns an existing entity so we use his entity_id
   my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'removeInterface');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to remove an interface from this host");
    }

    my $ifc = $self->{_dbix}->ifaces->find($args{iface_id});
    $ifc->delete();
}

sub becomeMasterNode{
    my $self = shift;

    my $row = $self->{_dbix}->node;
    if(not defined $row) {
        $errmsg = "Entity::Host->becomeMasterNode :Host " . $self->getAttr(name => "entity_id") . " is not a node!";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    $row->update({master_node => 1});
}

=head2 Entity::Host->stopToBeNode (%args)

    Class : Public

    Desc : Remove a node instance for a dedicated host.

    args:
        cluster_id : Int : Cluster identifier

=cut

sub stopToBeNode{
    my $self = shift;

    my $row = $self->{_dbix}->node;
    $log->debug("node <" . $self->getAttr(name => "entity_id") .  "> stop to be node");
    if(not defined $row) {
        $errmsg = "Entity::Host->stopToBeNode : node representing host " .
                   $self->getAttr(name => "entity_id") . " not found!";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    $row->delete;
}

=head2 getHosts

=cut

sub getHosts {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub getHost {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @Hosts = $class->search(%args);
    return pop @Hosts;
}

sub getHostFromIP {
    my $class = shift;
    my %args = @_;

    throw Kanopya::Exception::NotImplemented();
}

sub getFreeHosts {
    my $class = shift;
    my %args = @_;

    my $hash = {active => 1, host_state => {-like => 'down:%'}};

    if (defined $args{host_manager_id}) {
        $hash->{host_manager_id} = $args{host_manager_id}
    }

    my @hosts = $class->getHosts(hash => $hash);
    my @free;
    foreach my $m (@hosts) {
        if(not $m->{_dbix}->node) {
            push @free, $m;
        }
    }
    return @free;
}

=head2 update

=cut

sub update {}

=head2 remove

=cut

sub remove {
    my $self = shift;

    $log->debug("New Operation RemoveHost with host_id : <" .
                $self->getAttr(name => "host_id") . ">");

    Operation->enqueue(
        priority => 200,
        type     => 'RemoveHost',
        params   => {
            host_id => $self->getAttr(name => "host_id")
        },
    );
}

sub extension {
    return "hostdetails";
}

sub getHarddisks {
    my $self = shift;
    my $hds = [];
    my $harddisks = $self->{_dbix}->harddisks;
    while(my $hd = $harddisks->next) {
        my $tmp = {};
        $tmp->{harddisk_id} = $hd->get_column('harddisk_id');
        $tmp->{harddisk_device} = $hd->get_column('harddisk_device');
        push @$hds, $tmp;
    }
    return $hds;

}

sub addHarddisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['device']);

    my $adm = Administrator->new();
    # addHarddisk method concerns an existing entity so we use his entity_id
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'addHarddisk');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to add a hard disk to this host");
    }

    $self->{_dbix}->harddisks->create({
        harddisk_device => $args{device},
        host_id => $self->getAttr(name => 'host_id'),
    });
}

sub removeHarddisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['harddisk_id']);

    my $adm = Administrator->new();
    # removeHarddisk method concerns an existing entity so we use his entity_id
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'removeHarddisk');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to remove a hard disk from this host");
    }

    my $hd = $self->{_dbix}->harddisks->find($args{harddisk_id});
    $hd->delete();
}

sub activate{
    my $self = shift;

    $log->debug("New Operation ActivateHost with host_id : " . $self->getAttr(name=>'host_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateHost',
                   params   => {host_id => $self->getAttr(name=>'host_id')});
}

sub deactivate{
    my $self = shift;

    $log->debug("New Operation EDeactivateHost with host_id : " . $self->getAttr(name=>'host_id'));
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateHost',
                   params   => {host_id => $self->getAttr(name=>'host_id')});
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    return 'Entity::Host <' . $self->getAttr(name => "entity_id") .'>';
}

sub getInternalIP {
    my $self = shift;
    my $adm = Administrator->new();

    # For instance, return the first ip of the first iface found.
    my $iface = $self->{_dbix}->ifaces->single();
    if (defined $iface) {
        my $ip = $iface->ips->single();
        if (defined $ip) {
            # TODO: Do not use ipv4_internal table, so do not use the NetworkManager any more ?
            my $ipv4_id = $adm->{manager}->{network}->getInternalIPId(
                              ipv4_internal_address => $ip->get_column('ip_addr')
                          );
            return $adm->{manager}->{network}->getInternalIP(ipv4_internal_id => $ipv4_id);
        }
    }
    return {};
}

sub setInternalIP {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['ipv4_address','ipv4_mask']);

    # For instance, add an IP to the frist iface found.
    my $iface = $self->{_dbix}->ifaces->single();
    if (defined $iface) {
        # TODO: Do not use ipv4_internal table, so do not use the NetworkManager any more ?
        my $adm = Administrator->new();
        my $net_id = $adm->{manager}->{network}->newInternalIP(%args);

        $iface->ips->create({ ip_addr => $args{ipv4_address} });

        return $net_id;
    }
    throw Kanopya::Exception::DB(
              error => "Not iface defined for Host <" . $self->getAttr(name => 'entity_id') . ">."
          );
}

sub removeInternalIP {
    my $self = shift;
    my $adm = Administrator->new();

    # For instance, remove all ip related to this host.
    my $ifaces = $self->{_dbix}->ifaces;
    while(my $iface = $ifaces->next) {
        my $ips = $iface->ips;
        while(my $ip = $ips->next) {
            # TODO: Do not use ipv4_internal table, so do not use the NetworkManager any more ?
            my $ipv4_id = $adm->{manager}->{network}->getInternalIPId(
                              ipv4_internal_address => $ip->get_column('ip_addr')
                          );
            $adm->{manager}->{network}->delInternalIP(ipv4_id => $ipv4_id);
            $ip->delete();
        }
    }
}

sub getClusterId {
    my $self = shift;
    return $self->{_dbix}->node->inside->get_column('inside_id');
}

sub getPowerSupplyCardId {
    my $self = shift;
    my $row = $self->{_dbix}->host_powersupply;
    if (defined $row) {
        return $row->get_column('powersupplycard_id');}
    else {
        return;
    }
}

sub getModel {
    my $self = shift;
    my $model_row = $self->{_dbix}->hostmodel;
    if ( defined $model_row ) {
        return $model_row->get_columns();
    }
    return;
}

sub getRemoteSessionURL {
    my $self = shift;

   return $self->getHostManager->getRemoteSessionURL(host => $self);
}

1;
