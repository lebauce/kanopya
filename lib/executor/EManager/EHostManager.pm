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

package EManager::EHostManager;
use base "EManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use DecisionMaker::HostSelector;

use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Kernel;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


sub createHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "host_serial_number", "host_ram" ]);

    if (defined $args{erollback}) { delete $args{erollback}; }

    my $host = $self->_entity->addHost(%args);

    #TODO: insert erollback ?
    return $host;
}


sub removeHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $host = $self->_entity->delHost(host => $args{host}->_entity);

    #TODO: insert erollback ?
}


=pod
=begin classdoc

This function starts a host in a cluster
@param host host to start

=end classdoc
=cut

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

This function halt a host by execution poweroff command.

@param host the host to stop

=end classdoc
=cut

sub haltHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

   return $args{host}->getEContext->execute(command => 'poweroff')->{exitcode};
}


=pod
=begin classdoc

This function stops a host in a cluster

@param host host to stop

=end classdoc
=cut

sub stopHost {
    my $self = shift;
    my %args = @_;

	General::checkParams(args => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}


sub releaseHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    $args{host}->setState(state => "down");
}


=pod
=begin classdoc

This function is called once a host has started

@param host host to post Start

=end classdoc
=cut

sub postStart {
    my $self = shift;
    my %args = @_;

	General::checkParams(args => \%args, required => [ "host" ]);
}


=pod
=begin classdoc

This function dynamically scales a host

=end classdoc
=cut

sub scaleHost {
    $log->debug("Scaling is not implemented by this host manager, doing nothing");
}


=pod
=begin classdoc

Return one free host that match the criterias

@param interfaces the network interfaces constraints
@param core the core number constraints
@param ram the ram amount constraint

@optional deploy_on_disk the on disk deployable constraints
@optional tags the tag list constraints
@optional no_tags the no_tag list constraints

@return the found free host

=end classdoc
=cut

sub getFreeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "interfaces", "ram" ],
                         optional => { "deploy_on_disk" => 0, "tags" => [], "no_tags" => [],
                                       "core" => undef, "cpu" => undef });

    # We are not consistent yet for the arg "core"
    if (! (defined($args{core}) || defined($args{cpu}))) {
        General::checkParams(args => \%args, required => [ "core" ]);
    }
    elsif (defined($args{cpu})) {
        $args{core} = delete $args{cpu};
    }

    return DecisionMaker::HostSelector->getHost(host_manager => $self, %args);
}

=pod
=begin classdoc

Apply a VLAN on an interface of a host

@param vlan
@param iface

=end classdoc
=cut

sub applyVLAN {
    $log->debug("VLAN are not supported by this host manager, doing nothing");
}


sub getHypervisorVMs {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ "host" ]);
    throw Kanopya::Exception::NotImplemented();
}

sub resubmitHost {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ "host" ]);
    throw Kanopya::Exception::NotImplemented();
}

1;
