# Host.pm - Object class of Ḿotherboard (Administrator side)
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
# Created 14 july 2010
package Entity::Host;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Operation;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("administrator");
my $errmsg;

=head2 Host Attributes

hostmodel_id : Int : Identifier of host model.
processormodel_id : Int : Identifier of host processor model
kernel_id : Int : kernel identifier which will be used by host if non specified by cluster
host_serial_number : String : This is the serial number attributed to host
host_mac_address : String : This is the main network interface mac address of the host

host_powersupply_id : Int : Facultative identifier to know which powersupplycard and port is used.
Powersupplyid is created during host creation.
host_desc :  String : This is a free field to enter a description of host. It is generally used to
specify owner, team, ...

active : Int : This is an internal parameter used to activate or deactivate resources on Kanopya System
host_internal_ip : String : This another internally manage attribute, it allow to save internal ip of
a host when it is in a cluster
host_hostname : Hostname is also internally managed. Host hostname will be generated from the mac address
It is generated when a host is added into a cluster
host_initiatorname : This attributes is generated when a host is added in a cluster and allow to connect
to internal storage to get the systemimage
etc_device_id : Int : This parameter corresponding to lv storage and iscsitarget generated
when a host is configured to be migrated into a cluster
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
              hostmodel_id    =>    {pattern            => '^\d*$',
                                            is_mandatory    => 1,
                                            is_extended        => 0},
              processormodel_id        => {pattern            => '^\d*$',
                                            is_mandatory    => 1,
                                            is_extended     => 0},
              kernel_id                    => {pattern            => '^\d*$',
                                            is_mandatory    => 1,
                                            is_extended        => 0},
              host_serial_number    => {pattern         => '^.*$',
                                            is_mandatory    => 1,
                                            is_extended     => 0},
              host_powersupply_id=> {pattern         => '^\w*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
              host_desc            => {pattern         => '^[\w\s]*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
              active                    => {pattern         => '^[01]$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
              host_mac_address    => {pattern         => '^[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}$',  # mac address format must be lower case
                                            is_mandatory    => 1,        # to have udev persistent net rules work
                                            is_extended     => 0},
              host_internal_ip    => {pattern         => '^.*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
              host_hostname        => {pattern         => '^\w*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
              host_ram        =>      {pattern         => '^\w*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
              host_core        => {pattern         => '^\w*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},

              host_initiatorname    => {pattern         => '^.*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
              etc_device_id                => {pattern         => 'm/^\d*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
            host_state                => {pattern         => '^up:\d*|down:\d*|starting:\d*|stopping:\d*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
            host_ipv4_internal_id     => {pattern         => 'm/^\d*$',
                                            is_mandatory    => 0,
                                            is_extended     => 0},
            host_toto                => {pattern         => '^.*$',
                                            is_mandatory    => 0,
                                            is_extended     => 1}
            };

sub getAttrDef{
    return ATTR_DEF;
}
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

        'setperm'    => {'description' => 'set permissions on this host',
                        'perm_holder' => 'entity',
        },
    };
}

=head2 get

=cut

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);

    my $admin = Administrator->new();
    my $host = $admin->{db}->resultset('Host')->find($args{id});
    if(not defined $host) {
        $errmsg = "Entity::Host->get : id <$args{id}> not found !";
     $log->error($errmsg);
     throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    my $entity_id = $host->entitylink->get_column('entity_id');
    my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get host with id $args{id}");
    }

    my $self = $class->SUPER::get( %args, table=>"Host");
    $self->{_ext_attrs} = $self->getExtendedAttrs(ext_table => "hostdetails");
    return $self;
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

sub setNodeNumber{
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

    General::checkParams(args => \%args, required => ['state']);
    my $new_state = $args{state};
    my $current_state = $self->getNodeState();
    $self->{_dbix}->node->update({'node_prev_state' => $current_state,
                                  'node_state' => $new_state . ":" . time})->discard_changes();
}

=head2 Entity::Host->becomeNode (%args)

    Class : Public

    Desc : Create a new node instance in db from host linked to cluster (in params).

    args:
        cluster_id : Int : Cluster identifier
        master_node : Int : 0 or 1 to say if the host is the master node
    return: Node identifier

=cut

sub becomeNode{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['cluster_id','master_node']);

    my $adm = Administrator->new();
    my $res =$adm->{db}->resultset('Node')->create({cluster_id=>$args{cluster_id},
                                            host_id =>$self->getAttr(name=>'host_id'),
                                            master_node => $args{master_node}});
    return $res->get_column("node_id");
}
#node_number=>$args{node_number},
sub becomeMasterNode{
    my $self = shift;

    my $row = $self->{_dbix}->node;
    if(not defined $row) {
        $errmsg = "Entity::Host->becomeMasterNode :Host ".$self->getAttr(name=>"host_mac_address")." is not a node!";
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
    $log->debug("node <".$self->getAttr(name=>"host_mac_address")."> stop to be node");
    if(not defined $row) {
        $errmsg = "Entity::Host->stopToBeNode : node representing host ".$self->getAttr(name=>"host_mac_address")."  not found!";
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

    return $class->SUPER::getEntities( %args,  type => "Host");
}

sub getHost {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @Hosts = $class->SUPER::getEntities( %args,  type => "Host");
    return pop @Hosts;
}

sub getHostFromIP {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['ipv4_internal_ip']);

    my $adm = Administrator->new();
    my $net_id = $adm->{manager}->{network}->getInternalIPId( ipv4_internal_address => $args{ipv4_internal_ip} );
    return $class->SUPER::getEntities( hash=>{host_ipv4_internal_id => $net_id},  type => "Host");
}

sub getFreeHosts {
    my $class = shift;
    my @hosts = $class->getHosts(hash => {active => 1, host_state => {-like => 'down:%'}});
    my @free;
    foreach my $m (@hosts) {
        if(not $m->{_dbix}->node) {
            push @free, $m;
        }
    }
    return @free;
}

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);

    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Host");

    # Set the extended parameters
    $self->{_ext_attrs} = $attrs->{extended};
    return $self;
}

=head2 create

=cut

sub create {
    my $self = shift;

    my %params = $self->getAttrs();
    $log->debug("New Operation AddHost with attrs : " . Dumper(%params));
    Operation->enqueue(priority => 200,
                   type     => 'AddHost',
                   params   => \%params);
}

=head2 update

=cut

sub update {}

=head2 remove

=cut

sub remove {
    my $self = shift;

    $log->debug("New Operation RemoveHost with host_id : <".$self->getAttr(name=>"host_id").">");
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveHost',
        params   => {host_id => $self->getAttr(name=>"host_id")},
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
    my $string = $self->{_dbix}->get_column('host_mac_address');
    $string =~ s/\://g;
    return $string;
}

sub getEtcName {
    my $self = shift;
    my $mac = $self->getAttr(name => "host_mac_address");
    $mac =~ s/\:/\_/mg;
    return "etc_". $mac;
}

=head2 getMacName

return Mac address with separator : replaced by _

=cut

sub getMacName {
    my $self = shift;
    my $mac = $self->getAttr(name => "host_mac_address");
    $mac =~ s/\:/\_/mg;
    return $mac;
}

=head2 getEtcDev

get etc attributes used by this host

=cut

sub getEtcDev {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Host->getEtcDev must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    $log->info("retrieve etc attributes");
    my $etcrow = $self->{_dbix}->etc_device;
    my $devices = {
        etc => { lv_id => $etcrow->get_column('lvm2_lv_id'),
                 vg_id => $etcrow->get_column('lvm2_vg_id'),
                 lvname => $etcrow->get_column('lvm2_lv_name'),
                 vgname => $etcrow->lvm2_vg->get_column('lvm2_vg_name'),
                 size => $etcrow->get_column('lvm2_lv_size'),
                 freespace => $etcrow->get_column('lvm2_lv_freespace'),
                 filesystem => $etcrow->get_column('lvm2_lv_filesystem')
                }    };
    $log->info("Host etc and root devices retrieved from database");
    return $devices;
}

sub getInternalIP {
    my $self = shift;
    my $adm = Administrator->new();
    if ($self->getAttr(name=>"host_ipv4_internal_id")) {
        return $adm->{manager}->{network}->getInternalIP(ipv4_internal_id => $self->getAttr(name=>"host_ipv4_internal_id"));
    }
    return {};

}

sub setInternalIP{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['ipv4_address','ipv4_mask']);

    my $adm = Administrator->new();
    my $net_id = $adm->{manager}->{network}->newInternalIP(%args);
    $self->setAttr(name => "host_ipv4_internal_id", value => $net_id);
    return $net_id;
}

sub removeInternalIP{
    my $self = shift;

    my $internal_net_id = $self->getAttr(name =>"host_ipv4_internal_id");

    $self->{_dbix}->update({'host_ipv4_internal_id' => undef});
    my $adm = Administrator->new();
    my $net_id = $adm->{manager}->{network}->delInternalIP(ipv4_id => $internal_net_id);

}




sub getClusterId {
    my $self = shift;
    return $self->{_dbix}->node->cluster->get_column('cluster_id');
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

1;
