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

package Entity::ServiceProvider::UnifiedComputingSystem;
use base 'Entity::ServiceProvider';

use strict;
use warnings;

use NetAddr::IP;
use Entity::Component::UcsManager;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    ucs_name => {
        pattern      => '.*',
        is_mandatory => 1,
    },
    ucs_desc => {
        pattern      => '.*',
        is_mandatory => 0,
    },
    ucs_addr => {
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
    },
    ucs_login => {
        pattern      => '.*',
        is_mandatory => 1,
    },
    ucs_passwd => {
        pattern      => '.*',
        is_mandatory => 1,
    },
    ucs_ou => {
        pattern      => '.*',
        is_mandatory => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        synchronize => {
            description => 'synchronize Kanopya width the UCS device.',
        }
    };
}

sub getUcs {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    my $ucsmanager = ClassType::ComponentType->find(hash => { component_name => 'UcsManager' });
    $self->addComponent(component_type_id => $ucsmanager->id);

    return $self;
}

sub remove {
    my $self = shift;
    $self->SUPER::delete(); 
};


sub toString {
    my $self = shift;

    return $self->ucs_name . ' (UCS Equipment)';
}

sub synchronize {
    my ($self) = @_;
    my @components = $self->getComponents();

    foreach my $component (@components) {
        if ($component->isa("Entity::Component::UcsManager") ) {
            $component->synchronize();
        }
    }
}

1;
