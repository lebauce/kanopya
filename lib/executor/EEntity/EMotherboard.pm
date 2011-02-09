# EMotherboard.pm - Abstract class of EMotherboards object

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

EMotherboard - execution class of motherboard entities

=head1 SYNOPSIS



=head1 DESCRIPTION

EMotherboard is the execution class of motherboard entities

=head1 METHODS

=cut
package EEntity::EMotherboard;
use base "EEntity";

use Entity::Powersupplycard;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use IO::Socket;

my $log = get_logger("executor");
my $errmsg;

=head2 new

    my comp = EMotherboard->new();

EMotherboard::new creates a new component object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
	$self->_init();
    
    return $self;
}

=head2 _init

EMotherboard::_init is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;

	return;
}

sub start {
    my $self = shift;
	my %args = @_;
	
    if ((! exists $args{econtext} or ! defined $args{econtext})){
		$errmsg = "EEntity::EMotherboard->start need a econtext named argument!";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $powersupplycard_id = $self->_getEntity()->getPowerSupplyCardId();
	if (!$powersupplycard_id) {
		if(not -e '/usr/sbin/etherwake') {
			$errmsg = "EOperation::EStartNode->startNode : /usr/sbin/etherwake not found";
			$log->error($errmsg);
			throw Kanopya::Exception::Execution(error => $errmsg);
		}
		my $command = "/usr/sbin/etherwake ".$self->_getEntity()->getAttr(name => 'motherboard_mac_address');
		my $result = $args{econtext}->execute(command => $command);
	}
	else {
	    my $powersupplycard = Entity::Powersupplycard->get(id=> $powersupplycard_id);
		my $powersupply_ip = $powersupplycard->getAttr(name => "powersupplycard_ip");
		$log->debug("Start motherboard with power supply which ip is : <$powersupply_ip>");
		my $sock = new IO::Socket::INET (
                                  PeerAddr => $powersupply_ip,
                                  PeerPort => '1470',
                                  Proto => 'tcp',
                                 );
		$sock->autoflush(1);
		die "Could not create socket: $!\n" unless $sock;
	    my $powersupply_port_number = $powersupplycard->getMotherboardPort(motherboard_powersupply_id=> $self->{_objs}->{motherboard}->getAttr(name => "motherboard_powersupply_id"));
		my $pos = $powersupply_port_number;
		my $s = "R";
		$s .= pack "B16", ('0'x($pos-1)).'1'.('0'x(16-$pos));
		$s .= pack "B16", "000000000000000";
		printf $sock $s;
		close($sock);
	}
	my $state = "starting:".time;
	$self->_getEntity()->setAttr(name => 'motherboard_state', value => $state);
	$self->_getEntity()->save();
}

sub halt {
    my $self = shift;
	my %args = @_;
	
    if ((! exists $args{node_econtext} or ! defined $args{node_econtext})){
		$errmsg = "EEntity::EMotherboard->halt need a node_econtext named argument!";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal(error => $errmsg);
	}
    my $command = 'halt';
	my $result = $args{node_econtext}->execute(command => $command);
	my $state = 'stopping:'.time;
	$self->_getEntity()->setAttr(name => 'motherboard_state', value => $state);
	$self->_getEntity()->save();
}

sub stop {
    my $self = shift;
	
    my $powersupply_id = $self->_getEntity()->getAttr(name=>"motherboard_powersupply_id");
    if ($powersupply_id) {
    	my $powersupplycard_id = $self->_getEntity()->getPowerSupplyCardId();
#$adm->getEntity(type => "Powersupplycard",id => $powersupply_id);                                                                                          
       	use IO::Socket;
        my $powersupplycard = Entity::Powersupplycard->get(id => $powersupplycard_id);
#$adm->findPowerSupplyCard(powersupplycard_id => $powersupply->{powersupplycard_id});                                                                       
        my $sock = new IO::Socket::INET (
                                  PeerAddr => $powersupplycard->getAttr(name => "powersupplycard_ip"),
                                  PeerPort => '1470',
                                  Proto => 'tcp',
                                 );
        $sock->autoflush(1);
        die "Could not create socket: $!\n" unless $sock;

        my $pos = $powersupplycard->getMotherboardPort(motherboard_powersupply_id => $powersupply_id);
        my $s = "R";
        $s .= pack "B16", "000000000000000";
        $s .= pack "B16", ('0'x($pos-1)).'1'.('0'x(16-$pos));
        printf $sock $s;
		close($sock);
	}

}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut