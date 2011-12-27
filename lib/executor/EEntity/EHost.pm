# EHost.pm - Abstract class of EHosts object

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

=head1 NAME

EHost - execution class of host entities

=head1 SYNOPSIS



=head1 DESCRIPTION

EHost is the execution class of host entities

=head1 METHODS

=cut
package EEntity::EHost;
use base "EEntity";

use Entity::Powersupplycard;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use IO::Socket;
use Net::Ping;

my $log = get_logger("executor");
my $errmsg;

=head2 new

    my comp = EHost->new();

EHost::new creates a new component object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

EHost::_init is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;

    return;
}

sub start {
    my $self = shift;
    my %args = @_;
    
    if ((! exists $args{econtext} or ! defined $args{econtext})){
        $errmsg = "EEntity::EHost->start need a econtext named argument!";
        $log->error($errmsg);    
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $powersupplycard_id = $self->_getEntity()->getPowerSupplyCardId();
    if (!$powersupplycard_id) {
        if(not -e '/usr/sbin/etherwake') {
            $errmsg = "EOperation::EStartNode->startNode : /usr/sbin/etherwake not found";
            $log->error($errmsg);
            throw Kanopya::Exception::Execution(error => $errmsg);
        }
        my $command = "/usr/sbin/etherwake ".$self->_getEntity()->getAttr(name => 'host_mac_address');
        my $result = $args{econtext}->execute(command => $command);
    }
    else {
        my $powersupplycard = Entity::Powersupplycard->get(id=> $powersupplycard_id);
        my $powersupply_ip = $powersupplycard->getAttr(name => "powersupplycard_ip");
        $log->debug("Start host with power supply which ip is : <$powersupply_ip>");
        my $sock = new IO::Socket::INET (
                                  PeerAddr => $powersupply_ip,
                                  PeerPort => '1470',
                                  Proto => 'tcp',
                                 );
        $sock->autoflush(1);
        die "Could not create socket: $!\n" unless $sock;
        my $powersupply_port_number = $powersupplycard->getHostPort(host_powersupply_id=> $self->{_objs}->{host}->getAttr(name => "host_powersupply_id"));
        my $pos = $powersupply_port_number;
        my $s = "R";
        $s .= pack "B16", ('0'x($pos-1)).'1'.('0'x(16-$pos));
        $s .= pack "B16", "000000000000000";
        printf $sock $s;
        close($sock);
    }
    my $entity = $self->_getEntity();
    my $current_state = $self->_getEntity()->getState();
    $self->_getEntity()->setState(state => 'starting');
    if(exists $args{erollback}) {
        $args{erollback}->add(function   =>$entity->can('save'),
                              parameters => [$entity]);
        $args{erollback}->add(function   =>$entity->can('setAttr'),
                              parameters => [$entity, "name" ,"host_state",
                                            "value", $current_state]);
    }
}

sub halt {
    my $self = shift;
    my %args = @_;
    
    if ((! exists $args{node_econtext} or ! defined $args{node_econtext})){
        $errmsg = "EEntity::EHost->halt need a node_econtext named argument!";
        $log->error($errmsg);    
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $command = 'halt';
    my $result = $args{node_econtext}->execute(command => $command);
    $self->_getEntity()->setState(state => 'stopping');
}

sub stop {
    my $self = shift;
    
    my $powersupply_id = $self->_getEntity()->getAttr(name=>"host_powersupply_id");
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

        my $pos = $powersupplycard->getHostPort(host_powersupply_id => $powersupply_id);
        my $s = "R";
        $s .= pack "B16", "000000000000000";
        $s .= pack "B16", ('0'x($pos-1)).'1'.('0'x(16-$pos));
        printf $sock $s;
        close($sock);
    }

}

sub postStart {}

sub checkUp {
    my $self = shift;
    my $ip = $self->_getEntity()->getInternalIP()->{ipv4_internal_address};
    my $p = Net::Ping->new();
    my $pingable = $p->ping($ip);
    $p->close();
    
    if ($pingable) {
        eval {
            my $node_econtext = EFactory::newEContext(ip_source => '127.0.0.1', ip_destination => $ip);
            $log->debug("In checkUP test if host <$ip> is pingable <$pingable>\n");
        };
        if($@) {
            $errmsg = "Ehost->checkUp for host <$ip>, host pingable but not sshable";
            $log->info($errmsg);
            return 0;
        }
    }

    return $pingable;
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
