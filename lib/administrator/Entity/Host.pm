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
use Entity::Operation;
use General;
use Externalnode::Node;

use Entity::ServiceProvider;
use Entity::Container;
use Entity::Interface;
use Entity::Iface;
use Entity::Operation;
use Entity::Workflow;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


use constant ATTR_DEF => {
    host_manager_id => {
        label        => 'Host manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
    hostmodel_id => {
        label        => 'Board model',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    processormodel_id => {
        label        => 'Processor model',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    kernel_id => {
        label        => 'Specific kernel',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    host_serial_number => {
        label        => 'Serial number',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    host_desc => {
        label        => 'Description',
        type         => 'text',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    active => {
        label        => 'Active',
        type         => 'boolean',
        pattern      => '^[01]$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    host_hostname => {
        label        => 'Hostname',
        type         => 'string',
        pattern      => '^[\w\d\-\.]*$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    host_ram => {
        label        => 'RAM capability',
        description  => 'Memory capability of the physical host',
        type         => 'integer',
        unit         => 'byte',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    host_core => {
        label        => 'CPU capability',
        type         => 'integer',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    host_initiatorname => {
        label        => 'Iscsi initiator name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    host_state => {
        label        => 'Host state',
        type         => 'string',
        pattern      => '^up:\d*|down:\d*|starting:\d*|stopping:\d*|locked:\d*|broken:\d*$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    ifaces => {
        label        => 'Network interfaces',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
    },
    admin_ip => {
        label        => 'Administration ip',
        is_virtual   => 1,
    },
    remote_session_url => {
        label        => 'Remote session url',
        is_virtual   => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        activate => {
            description => 'activate this host',
            perm_holder => 'entity',
        },
        deactivate => {
            description => 'deactivate this host',
            perm_holder => 'entity',
        },
        resubmit => {
            description => 'resubmit the corresponding node',
            perm_holder => 'entity',
        },
        removeIface => {
            description => 'remove an interface from this host',
            perm_holder => 'entity',
        },
        addIface => {
            description => 'add one or more interface to  this host',
            perm_holder => 'entity',
        },
    };
}

=head2 create

=cut

sub create {
    my $class = shift;
    my %args  = @_;

    General::checkParams(args   => \%args,
                         required => ['host_manager_id', 'host_core', 'kernel_id',
                                      'host_ram', 'host_serial_number' ]);

    Entity->get(id => $args{host_manager_id})->createHost(%args);
}

sub resubmit() {
    my $self = shift;

    Entity::Workflow->run(name => 'ResubmitNode', params => { context => { host => $self } });
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
    my $state = $self->host_state;
    return wantarray ? split(/:/, $state) : $state;
}

sub getPrevState {
    my $self = shift;
    my $state = $self->host_prev_state;
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

    $self->setAttr(name => 'host_prev_state', value => $current_state);
    $self->setAttr(name => 'host_state', value => $new_state.":".time);
    $self->save();
}

=head2 getNodeState

=cut

sub getNodeState {
    my $self = shift;
    my $state = $self->node->node_state;
    return wantarray ? split(/:/, $state) : $state;
}

=head2 getNodeNumber

=cut
sub getNodeNumber {
    my $self = shift;
    my $node_number = $self->node->node_number;
    return $node_number;
}

=head2 getNodeSystemimage

=cut

sub getNodeSystemimage {
    my $self = shift;
    return $self->node->systemimage;
}

sub getNode {
    my $self = shift;
    return $self->node;
}

sub getPrevNodeState {
    my $self = shift;
    my $state = $self->node->node_prev_state;
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

    my $node = $self->node;
    $node->setAttr(name => 'node_prev_state', value => $current_state || "");
    $node->setAttr(name => 'node_state', value => $new_state . ":" . time);
    $node->save();
}

=head2 updateCPU

=cut

sub updateCPU {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cpu_number' ]);

    # If the host is a node, then it is used in a cluster
    # belonging to a user, so update quota
    if ($self->node) {
        my $user = $self->node->inside->user;

        if ($args{cpu_number} < $self->host_core) {
            $user->releaseQuota(resource => 'cpu',
                                amount   => $self->host_core - $args{cpu_number});
        } else {
            $user->consumeQuota(resource => 'cpu',
                                amount   => $args{cpu_number} - $self->host_core);
        }
    }

    $self->setAttr(name => "host_core", value => $args{cpu_number});
    $self->save();
}

=head2 updateMemory

=cut

sub updateMemory {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'memory' ]);

    # If the host is a node, then it is used in a cluster
    # belonging to a user, so update quota
    if ($self->node) {
        my $user = $self->node->inside->user;

        if ($args{memory} < $self->host_ram) {
            $user->releaseQuota(resource => 'ram',
                                amount   => $self->host_ram - $args{memory});
        } else {
            $user->consumeQuota(resource => 'ram',
                                amount   => $args{memory} - $self->host_ram);
        }
    }

    $self->setAttr(name => "host_ram", value => $args{memory});
    $self->save();
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
    my $node = Externalnode::Node->new(
                   inside_id           => $args{inside_id},
                   host_id             => $self->getAttr(name => 'host_id'),
                   master_node         => $args{master_node},
                   node_number         => $args{node_number},
                   systemimage_id      => $args{systemimage_id},
               );

    return $node->id;
}

sub becomeMasterNode {
    my $self = shift;
    my $node = $self->node;

    if (not defined $node) {
        $errmsg = "Entity::Host->becomeMasterNode :Host " . $self->id . " is not a node!";
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }

    $node->setAttr(name => 'master_node', value => 1);
    $node->save();
}

=head2 Entity::Host->stopToBeNode (%args)

    Class : Public

    Desc : Remove a node instance for a dedicated host.

    args:
        cluster_id : Int : Cluster identifier

=cut

sub stopToBeNode{
    my $self = shift;

    if (not defined $self->node) {
        $errmsg = "Host " . $self->id . " is not a node!";
        $log->error($errmsg);
        #throw Kanopya::Exception::DB(error => $errmsg);
    }
    else {
        $self->node->delete();
    }

    # Remove node entry
    $self->setState(state => 'down');
}

sub isIfacesConfigured {
    my $self = shift;
    my %args = @_;

    my $configured = 0;
    for my $iface ($self->ifaces) {
        $configured = scalar $iface->netconfs;
    }
    return $configured;
}

sub configureIfaces {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'cluster' ]);

    my @ifaces = $self->getIfaces;

    # Set the ifaces netconf according to the cluster interfaces
    INTERFACES:
    foreach my $interface (@{ $args{cluster}->interfaces }) {
        my $iface = shift;
        $iface->update(netconf_ifaces => \@{ $interface->netconfs });
    }
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

    my $iface = Entity::Iface->new(iface_name     => $args{iface_name},
                                   iface_mac_addr => $args{iface_mac_addr},
                                   iface_pxe      => $args{iface_pxe},
                                   host_id        => $self->id);

    return $iface->id;
}

=head2 getIfaces

=cut

sub getIfaces {
    my $self = shift;
    my %args = @_;
    my @ifaces = ();

    General::checkParams(args => \%args, optional => { 'role' => undef });

    # Make sure to have all pxe ifaces before non pxe ones within the resulting array
    foreach my $pxe (1, 0) {
        my @ifcs = Entity::Iface->search(hash => { host_id   => $self->id,
                                                   iface_pxe => $pxe,
                                                   # Do not search bonding slave ifaces
                                                   master    => undef });

        IFACE:
        for my $iface (@ifcs) {
            if (defined $args{role}) {
                my $hasrole = 0;

                NETCONFROLE:
                for my $netconf ($iface->netconfs) {
                    if ($netconf->netconf_role->netconf_role_name eq $args{role}) {
                        $hasrole = 1;
                        last NETCONFROLE;
                    }
                }
                if (not $hasrole) {
                    next IFACE;
                }
            }
            push @ifaces, $iface;
        }
    }
    return wantarray ? @ifaces : \@ifaces;
}

=head2 getPXEIface

=cut

sub getPXEIface {
    my $self = shift;

    my $pxe_iface;
    eval {
        $pxe_iface = Entity::Iface->find(hash => {
                         host_id   => $self->host_id,
                         iface_pxe => 1,
                         # Do not search bonding slave ifaces
                         master    => undef
                     });
    };
    if ($@) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "No pxe iface found."
              );
    }
    return $pxe_iface;
}

sub removeIface {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['iface_id']);

    my $ifc = Entity::Iface->find(hash => { host_id => $self->id, iface_id => $args{iface_id} });
    $ifc->delete();
}

sub getAdminIface {
    my $self = shift;
    my %args = @_;

    # Can we make it smarter ?
    my @ifaces = $self->getIfaces(role => "admin");
    if (scalar (@ifaces) == 0 and defined $args{throw}) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Host <" . $self->id . "> Could not find any iface associate to a admin role."
              );
    }
    return $ifaces[0];
}

sub adminIp {
    my $self = shift;
    my %args = @_;

    my $iface = $self->getAdminIface();
    if ($iface and $iface->hasIp) {
        if (defined ($iface) and $iface->hasIp) {
            return $iface->getIPAddr;
        }
    }
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

    my $hash = { active => 1, host_state => {-like => 'down:%'} };

    if (defined $args{host_manager_id}) {
        $hash->{host_manager_id} = $args{host_manager_id}
    }

    my @hosts = $class->getHosts(hash => $hash);
    my @free;
    foreach my $m (@hosts) {
        if(not $m->node) {
            push @free, $m;
        }
    }
    return @free;
}

=head2 remove

=cut

sub remove {
    my $self = shift;

    $log->debug("New Operation RemoveHost with host_id : <" . $self->getAttr(name => "host_id") . ">");

    Entity::Operation->enqueue(
        priority => 200,
        type     => 'RemoveHost',
        params   => {
            context  => {
                host => $self,
            },
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

    $self->{_dbix}->harddisks->create({
        harddisk_device => $args{device},
        host_id => $self->getAttr(name => 'host_id'),
    });
}

sub removeHarddisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['harddisk_id']);

    my $hd = $self->{_dbix}->harddisks->find($args{harddisk_id});
    $hd->delete();
}

sub activate{
    my $self = shift;

    $log->debug("New Operation ActivateHost with host_id : " . $self->getAttr(name=>'host_id'));
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'ActivateHost',
        params   => {
            context => {
                host => $self
           }
       }
   );
}

sub deactivate{
    my $self = shift;

    $log->debug("New Operation EDeactivateHost with host_id : " . $self->getAttr(name=>'host_id'));
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'DeactivateHost',
        params   => {
            context => {
                host => $self
           }
       }
   );
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    return 'Entity::Host <' . $self->getAttr(name => "entity_id") .'>';
}

sub getClusterId {
    my $self = shift;
    return $self->node->service_provider->id;
}

sub getCluster {
    my $self = shift;
    return $self->node->service_provider;
}

sub getModel {
    my $self = shift;
    return $self->hostmodel;
}

sub remoteSessionUrl {
    my $self = shift;

   return $self->getHostManager->getRemoteSessionURL(host => $self);
}

=head2

    Check if the host can be stopped, raise an exception otherwise

=cut

sub checkStoppable {
    return {};
}

1;
