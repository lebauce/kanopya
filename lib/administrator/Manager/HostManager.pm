# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Manager::HostManager;
use base "Manager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Host;
use Entity::Kernel;
use Entity::Tag;

my $log = get_logger("");
my $errmsg;

use constant BOOT_POLICIES => {
    pxe_nfs      => 'PXE Boot via NFS',
    pxe_iscsi    => 'PXE Boot via ISCSI',
    root_iscsi   => 'Boot on root ISCSI',
    virtual_disk => 'BootOnVirtualDisk',
    boot_on_san  => 'BootOnSan',
    local_disk   => 'BootOnLocalDisk'
};

sub getHostManagerParams {
    my $self = shift;
    my %args = @_;

    my $definition = $self->getManagerParamsDef();
    $definition->{tags}->{options} = {};
    $definition->{no_tags}->{options} = {};

    my @tags = Entity::Tag->search();
    for my $tag (@tags) {
        $definition->{tags}->{options}->{$tag->id} = $tag->tag;
        $definition->{no_tags}->{options}->{$tag->id} = $tag->tag;
    }

    return {
        cpu     => $definition->{cpu},
        ram     => $definition->{ram},
        tags    => $definition->{tags},
	no_tags => $definition->{no_tags},

    };
}

sub checkHostManagerParams {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ "cpu", "ram" ]);
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        cpu => {
            label        => 'Required CPU number',
            type         => 'integer',
            unit         => 'core(s)',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        ram => {
            label        => 'Required RAM amount',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        tags => {
            label        => 'Mandatory Tags',
            type         => 'enum',
            relation     => 'multi',
            is_mandatory => 0,
        },
        no_tags => {
            label        => 'Forbidden Tags',
            type         => 'enum',
            relation     => 'multi',
            is_mandatory => 0,
        },
        deploy_on_disk => {
            label        => 'Deploy on hard disk',
            type         => 'boolean',
            pattern      => '^\d*$',
            is_mandatory => 1
        }
    };
}


sub addHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "host_serial_number", "host_ram" ]);

    # Instanciate new Host Entity
    my $host;
    eval {
        $host = Entity::Host->new(host_manager_id => $self->id, %args);
    };
    if($@) {
        my $errmsg = "Wrong host attributes detected\n" . $@;
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Set initial state to down
    $host->setAttr(name => 'host_state', value => 'down:' . time);

    # Save the Entity in DB
    $host->save();

    return $host;
}


sub delHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    # Delete the host from db
    $args{host}->delete();
}


sub createHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "host_serial_number", "host_ram" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'AddHost',
        params   => {
            context  => {
                host_manager => $self,
            },
            %args
        }
    );
}

sub removeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'RemoveHost',
        params   => {
            context  => {
                host => $args{host},
            },
        },
    );
}

sub activateHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'ActivateHost',
        params   => {
            context => {
                host => $args{host},
           }
       }
   );
}

sub deactivateHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'DeactivateHost',
        params   => {
            context => {
                host_to_deactivate => $args{host},
            }
        }
    );
}

sub resubmitHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->run(
        name   => 'ResubmitNode',
        params => {
            context => {
                host => $args{host}
            }
        }
    );
}

sub getOvercommitmentFactors {
    my ($self) = @_;

    return {
        overcommitment_cpu_factor    => 1.0,
        overcommitment_memory_factor => 1.0,
    }
}


sub getFreeHosts {
    my ($self) = @_;

    my $where = {
        active          => 1,
        host_state      => {-like => 'down:%'},
        host_manager_id => $self->id
    };

    my @hosts = Entity::Host->search(hash => $where);
    my @free;
    foreach my $m (@hosts) {
        if(not $m->node) {
            push @free, $m;
        }
    }
    return @free;
}


sub getBootPolicies {
    throw Kanopya::Exception::NotImplemented();
}

sub hostType {
    return "Host";
}


sub getRemoteSessionURL {
    throw Kanopya::Exception::NotImplemented();
}

1;
