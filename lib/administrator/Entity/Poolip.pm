# Entity::Poolip.pm  

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
# Created 14 february 2012

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Entity::Poolip;
use base "Entity";

use Ip;
use NetAddr::IP;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    poolip_name => {
        label        => 'Name',
        pattern      => '.*',
        is_mandatory => 1,
        is_editable  => 1,
    },
    poolip_first_addr => {
        label        => 'First Address',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    poolip_size => {
        label        => 'Size',
        pattern      => '[0-9]{1,2}',
        is_mandatory => 1,
        is_editable  => 1,
    },
    network_id => {
        label        => 'Network',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub popIp {
    my $self = shift;
    my %args = @_;

    my $network = NetAddr::IP->new($self->poolip_first_addr,
                                   $self->network->network_netmask);

    # Firstly iterate until the first ip of the range.
    # TODO: make it smarter...
    my $ipaddr;
    my $index = 0;
    while ($ipaddr = $network->nth($index)) {
        $index++;

        # If current ip is lower than the starting ip, continue
        if ($ipaddr < $network) {
            next;
        }
        # If current ip index is higher than poolip size, exit loop
        elsif (($ipaddr - $network + 1) > $self->poolip_size) {
            last;
        }

        # Check if the current ip isn't already used
        eval {
            Ip->find(hash => { ip_addr => $ipaddr->addr, poolip_id => $self->id });
        };
        if ($@) {
            # Create a new Ip instead.
            $log->debug("New ip <" . $ipaddr->addr . "> from pool <" . $self->poolip_name . ">");

            return Ip->new(ip_addr => $ipaddr->addr, poolip_id => $self->id);
        }
        next;
    }
    throw Kanopya::Exception::Internal::NotFound(
              error => "No free ip in pool <" . $self->poolip_name . ">"
          );
}

sub freeIp {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['ip']);

    # Need other stuff ?
    $args{ip}->delete();
}

sub getPoolip {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub new {
    my ($class, %args) = @_;

    my $addrip = new NetAddr::IP($args{poolip_first_addr});
    if(not defined $addrip) {
        $errmsg = "Wrong value for poolip_first_addr!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $class->SUPER::new(%args);
}

sub remove {
    my $self = shift;
    $self->SUPER::delete(); 
};

sub toString {
    my $self = shift;
    my $string = $self->poolip_name . " ". $self->poolip_first_addr;
    return $string;
}


sub getAllIps {
    my $self = shift;
    my $ips = [];

    my $ip = new NetAddr::IP($self->poolip_first_addr, $self->network->network_netmask);
        for (my $i = 0; $i < $self->poolip_size; ++$i) {
        push(@{$ips}, $ip);
        ++$ip;
    }
    return $ips;
}

1;
