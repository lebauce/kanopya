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

=head1 NAME

Entity::Poolip

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::Poolip;
use base "Entity";
use NetAddr::IP;

use constant ATTR_DEF => {
	poolip_name			=> { pattern      => '.*',
							 is_mandatory => 1,
                           },
    poolip_desc			=> { pattern      => '.*',
							 is_mandatory => 0,
                           },
    poolip_addr			=> { pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
							 is_mandatory => 1,
                           },
    poolip_mask			=> { pattern      => '[0-9]{1,2}',
							 is_mandatory => 1,
                           },
    poolip_netmask		=> { pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
							 is_mandatory => 1,
                           },
    poolip_gateway		=> { pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
							 is_mandatory => 1,
                           },                           
};

sub getAttrDef { return ATTR_DEF; }

sub getPoolip {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub create {
    my $self = shift;
    my %args = @_;

    my $addrip = new NetAddr::IP($args{poolip_addr});
    if(not defined $addrip) {
        $errmsg = "Poolip->create : wrong value for address!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $mask = $args{poolip_mask};
    if($mask > 32) {
        $errmsg = "Poolip->create : wrong value for mask!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $ip = new NetAddr::IP($args{poolip_addr});
    if(not defined $addrip) {
        $errmsg = "Poolip->create : wrong value for addrip!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $poolip = Entity::Poolip->new(
        poolip_name     => $args{poolip_name},
        poolip_desc     => $args{poolip_desc},
        poolip_addr     => $args{poolip_addr},
        poolip_mask     => $args{poolip_mask},
        poolip_netmask  => $args{poolip_netmask},
        poolip_gateway  => $args{poolip_gateway},
    );
}

sub remove {
    my $self = shift;
    $self->SUPER::delete(); 
};

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('poolip_name'). " ". $self->{_dbix}->get_column('poolip_addr');
    return $string;
}

1;
