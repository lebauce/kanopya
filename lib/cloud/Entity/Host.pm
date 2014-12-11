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

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Entity::Host;
use base "Entity";

use strict;
use warnings;

use General;
use Harddisk;
use Entity::Iface;

use TryCatch;
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
        is_mandatory => 0,
        is_editable  => 0,
        description  => 'It is the manager of this host (IaaS for a vm, BladeManager for a blade, ...)',
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
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'Some servers need specific Kernel, if it is your case, choose one',
    },
    host_serial_number => {
        label        => 'Serial number',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'This is your UUID, it identifies your server.' .
                        ' It could be your internal id, the vendor id, ...',
    },
    host_desc => {
        label        => 'Description',
        type         => 'text',
        pattern      => '^.*$',
        is_mandatory => 0,
        description  => 'Describe your host here. Where is it rack ? DC, room, chassis, ...',
        is_editable  => 1,
    },
    active => {
        label        => 'Active',
        type         => 'boolean',
        pattern      => '^[01]$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    host_ram => {
        label        => 'RAM capability',
        description  => 'Amount of Ram on the server',
        type         => 'integer',
        unit         => 'byte',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
        default      => 1<<30,
    },
    host_core => {
        label        => 'CPU capability',
        description  => 'number of Core in your server (CPU x Core x Hyperthreading)',
        type         => 'integer',
        unit         => 'core(s)',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
        default      => 1,
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
        description  => 'add the different network interfaces of your server',
    },
    harddisks => {
        label        => 'Hard disks',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'add the different hard disks of your server',
    },
    ipmi_credentials => {
        label        => 'IPMI',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'add your ipmi credentials, HCM will be able to start and stop your server',
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
        },
        deactivate => {
            description => 'deactivate this host',
        },
        resubmit => {
            description => 'resubmit the corresponding node',
        },
        removeIface => {
            description => 'remove an interface from this host',
        },
        addIface => {
            description => 'add one or more interface to  this host',
        },
    };
}

sub create {
    my $class = shift;
    my %args  = @_;

    General::checkParams(args   => \%args,
                         required => [ 'host_manager_id', 'host_core', 'host_ram', 'host_serial_number' ]);

    return Entity::Component->get(id => $args{host_manager_id})->createHost(%args);
}

sub resubmit {
    my $self = shift;
    $self->host_manager->resubmitHost(host => $self);
}


=pod
=begin classdoc

Return the component/conector that manage this host.

@return the component/conector that manage this host.

=end classdoc
=cut

sub getHostManager {
    my $self = shift;

    if ( ! defined $self->host_manager) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => 'Host <' . $self->label . '> does not have an HostManager'
              );
    }

    return $self->host_manager;
}

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

sub getNodeState {
    my $self = shift;
    return $self->node->getState();
}

sub getPrevNodeState {
    my $self = shift;
    return $self->node->getPrevState();
}

sub setNodeState {
    my ($self, %args) = @_;

    return $self->node->setState(%args);
}


sub updateCPU {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cpu_number' ]);

    # If the host is a node, then it is used in a cluster
    # belonging to a user, so update quota
    if ($self->node) {
        my $user = $self->node->owner;

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

sub updateMemory {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'memory' ]);

    # If the host is a node, then it is used in a cluster
    # belonging to a user, so update quota
    if ($self->node) {
        my $user = $self->node->owner;

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

sub configuredIfaces {
    my $self = shift;
    my %args = @_;

    my @configured;
    for my $iface ($self->ifaces) {
        if (scalar $iface->netconfs > 0) {
            push @configured, $iface;
        }
    }

    return wantarray ? @configured : \@configured;
}


sub addIface {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'iface_name' ],
                         optional => { 'iface_mac_addr' => undef, 'iface_pxe' => 0 });

    my $iface = Entity::Iface->new(iface_name     => $args{iface_name},
                                   iface_mac_addr => $args{iface_mac_addr},
                                   iface_pxe      => $args{iface_pxe},
                                   host_id        => $self->id);
    return $iface;
}

sub getIfaces {
    my $self = shift;
    my %args = @_;
    my @ifaces = ();

    General::checkParams(args => \%args, optional => { 'role' => undef });

    # Make sure to have all pxe ifaces before non pxe ones within the resulting array
    foreach my $pxe (1, 0) {
        my @ifcs = Entity::Iface->search(hash => {
                       host_id   => $self->id,
                       iface_pxe => $pxe,
                       # Do not search bonding slave ifaces
                       master    => ''
                   });

        IFACE:
        for my $iface (@ifcs) {
            if (defined $args{role}) {
                my $hasrole = 0;

                NETCONFROLE:
                for my $netconf ($iface->netconfs) {
                    if(! $netconf->netconf_role) {
                        last NETCONFROLE;
                    }
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

sub getPXEIface {
    my $self = shift;

    my $pxe_iface;
    eval {
        $pxe_iface = Entity::Iface->find(hash => {
                         host_id   => $self->id,
                         iface_pxe => 1,
                         # Do not search bonding slave ifaces
                         master    => ''
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
                  error => "Host <" . $self->id . "> could not find any iface associate to a admin role."
              );
    }
    return $ifaces[0];
}

sub adminIp {
    my $self = shift;
    my %args = @_;

    my $iface = $self->getAdminIface();
    if (defined $iface and $iface->hasIp) {
        return $iface->getIPAddr;
    }

    return undef;
}

sub getFreeHosts {
    my $class = shift;
    my %args = @_;

    my $hash = { active => 1, host_state => {-like => 'down:%'} };

    if (defined $args{host_manager_id}) {
        $hash->{host_manager_id} = $args{host_manager_id}
    }

    my @hosts = $class->search(hash => $hash);
    my @free;
    foreach my $m (@hosts) {
        if(not $m->node) {
            push @free, $m;
        }
    }
    return @free;
}

sub remove {
    my $self = shift;

    return $self->host_manager->removeHost(host => $self);
}

sub addHarddisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['device']);

    return Harddisk->create(host_id         => $self->id,
                            harddisk_device => $args{device});
}

sub removeHarddisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['harddisk_id']);

    $self->findRelated(filters => [ 'harddisks' ], hash => { harddisk_id => $args{harddisk_id} })->remove();
}

sub activate{
    my $self = shift;

    # check if host is not active
    if ($self->active) {
        throw Kanopya::Exception::Internal(error => "Host <" . $self->label. "> is already active");
    }

    $self->active(1);

    $log->info("Host <" . $self->label . "> is now active");
}

sub deactivate{
    my $self = shift;

    # Check if host is not active
    if (not $self->active) {
        throw Kanopya::Exception::Internal(error => "Host <" . $self->label . "> is not active");
    }

    # Check if host is used as a node
    if ($self->node) {
        throw Kanopya::Exception::Internal(error => "Host <" . $self->label . "> is a node");
    }

    # set host active in db
    $self->active(0);

    $log->info("Host <" . $self->label . "> deactivated");
}

=pod
=begin classdoc

Return a string representation of the entity

@return string representation of the entity

=end classdoc
=cut

sub label {
    my $self = shift;

    try {
        return $self->node->node_hostname;
    }
    catch ($err) {
        return $self->host_serial_number;
    }
}


sub remoteSessionUrl {
    my $self = shift;

    try {
        return $self->host_manager->getRemoteSessionURL(host => $self);
    }
    catch {
        # Host not manager
        return "";
    }
}


=pod
=begin classdoc

    Check if the host can be stopped, raise an exception otherwise

=end classdoc
=cut

sub checkStoppable {
    return 1;
}

1;
