# UnifiedComputingSystem.pm - This object allows to manipulate cluster configuration
#    Copyright 2012 Hedera Technology SAS
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

package Entity::ServiceProvider::Outside::UnifiedComputingSystem;
use base 'Entity::ServiceProvider::Outside';

use strict;
use warnings;

use NetAddr::IP;
use Entity::Connector::UcsManager;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	ucs_name            => { pattern      => '.*',
							 is_mandatory => 1,
                           },
    ucs_desc            => { pattern      => '.*',
							 is_mandatory => 0,
                           },
    ucs_addr            => { pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
							 is_mandatory => 1,
                           },
    ucs_login           => { pattern    => '.*',
                             is_mandatory => 1,
                           },
    ucs_passwd          => { pattern    => '.*',
                             is_mandatory => 1,
                           },
    ucs_dataprovider    =>  { pattern   => '.*',
                             is_mandatory => 0,
                            },
    ucs_ou              =>  { pattern => '.*',
                             is_mandatory => 0,
                            },
};

sub getAttrDef { return ATTR_DEF; }

sub getUcs {
    my $class = shift;
    my %args = @_;
    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub create {
    my $self = shift;
    my %args = @_;

    my $addrip = new NetAddr::IP($args{ucs_addr});
    if(not defined $addrip) {
        $errmsg = "Ucs->create : wrong value for ip address!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $ucs = Entity::ServiceProvider::Outside::UnifiedComputingSystem->new(
        ucs_name            => $args{ucs_name},
        ucs_desc            => $args{ucs_desc},
        ucs_addr            => $args{ucs_addr},
        ucs_login           => $args{ucs_login},
        ucs_passwd          => $args{ucs_passwd},
        ucs_dataprovider    => $args{ucs_dataprovider},
        ucs_ou              => $args{ucs_ou},
    );

    my $connector = Entity::Connector::UcsManager->new();
    $ucs->addConnector('connector' => $connector);

    return $ucs;

}

sub remove {
    my $self = shift;
    $self->SUPER::delete(); 
};

sub getMasterNodeIp {
    my $self = shift;
    return $self->{_dbix}->get_column('ucs_addr');
}

sub toString {
    my $self = shift;
    return $self->{_dbix}->get_column('ucs_name') . " ".
           $self->{_dbix}->get_column('ucs_addr');
}

1;
