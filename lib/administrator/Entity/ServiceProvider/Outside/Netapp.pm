#    NetApp.pm - NetApp storage equipment
#    Copyright 2012 Hedera Technology SAS
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

package Entity::ServiceProvider::Outside::Netapp;
use base 'Entity::ServiceProvider::Outside';

use NetAddr::IP;
use Entity::Connector::NetappLunManager;
use Entity::Connector::NetappVolumeManager;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    netapp_name            => { pattern      => '.*',
                             is_mandatory => 1,
                           },
    netapp_desc            => { pattern      => '.*',
                             is_mandatory => 0,
                           },
    netapp_addr            => { pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
                             is_mandatory => 1,
                           },
    netapp_login           => { pattern    => '.*',
                             is_mandatory => 1,
                           },
    netapp_passwd          => { pattern    => '.*',
                             is_mandatory => 1,
                           },
};

sub getAttrDef { return ATTR_DEF; }

sub getDefaultManager {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['category']);

    if ($args{category} eq 'DiskManager') {
        return $self->getConnector(category => "Storage", version => "1");
    }

    elsif ($args{category} eq 'ExportManager') {
        return $self->getConnector(category => "Export", version => "1");
    }
}

sub getNetapp {
    my $class = shift;
    my %args = @_;
    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub create {
    my $self = shift;
    my %args = @_;

    my $addrip = new NetAddr::IP($args{netapp_addr});
    if (not defined $addrip) {
        $errmsg = "Netapp->create : wrong value for ip address!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $netapp = Entity::ServiceProvider::Outside::Netapp->new(
        netapp_name            => $args{netapp_name},
        netapp_desc            => $args{netapp_desc},
        netapp_addr            => $args{netapp_addr},
        netapp_login           => $args{netapp_login},
        netapp_passwd          => $args{netapp_passwd},
    );

    my $connector = Entity::Connector::NetappLunManager->new();
    $netapp->addConnector('connector' => $connector);
    $connector = Entity::Connector::NetappVolumeManager->new();
    $netapp->addConnector('connector' => $connector);

    return $netapp;

}

sub remove {
    my $self = shift;
    $self->SUPER::delete();
};

sub getMasterNodeIp {
    my $self = shift;
    return $self->{_dbix}->get_column('netapp_addr');
}

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('netapp_name');
    $string .= ' (NetApp Equipement)';
    return $string;
}

sub getState {
    return 'up';
}

sub synchronize {
    my ($self) = @_;
    my @connectors = $self->getConnectors();
    
    foreach my $connector (@connectors) {
        $connector->synchronize();
    }
}

1;
