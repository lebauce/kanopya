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

package Entity::ServiceProvider::Netapp;
use base 'Entity::ServiceProvider';

use NetAddr::IP;
use Entity::Component::NetappLunManager;
use Entity::Component::NetappVolumeManager;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
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

sub methods {
    return {
        getState    => {
            description => 'get the state',
            perm_holder => 'entity'
        },
        synchronize => {
            description => 'synchronize',
            perm_holder => 'entity'
        }
    };
}

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    my $component = Entity::Component::NetappLunManager->new();
    $self->addComponent(component => $component);

    $component = Entity::Component::NetappVolumeManager->new();
    $self->addComponent(component => $component);

    return $self;
}

sub remove {
    my $self = shift;
    $self->SUPER::delete();
};

sub getMasterNodeIp {
    my $self = shift;

    return $self->netapp_addr;
}

sub toString {
    my $self = shift;

    my $string = $self->netapp_name;
    $string .= ' (NetApp Equipement)';
    return $string;
}

sub getState {
    return 'up';
}

sub synchronize {
    my ($self) = @_;
    my @components = $self->getComponents();
    
    foreach my $component (@components) {
        if ($component->isa("Entity::Component::NetappVolumeManager") ) {
            $component->synchronize();
        }
    }

    foreach my $component (@components) {
        if ($component->isa("Entity::Component::NetappLunManager") ) {
            $component->synchronize();
        }
    }
}

1;
