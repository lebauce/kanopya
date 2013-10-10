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

package EEntity::EComponent::EDhcpd3;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";
use General;

my $log = get_logger("");
my $errmsg;

sub addHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
    
    my $erollback = $args{erollback};
    delete $args{erollback};
    $self->_entity->addHost(%args);

    if ($erollback) {
        $erollback->add(function   => $self->can('removeHost'),
                        parameters => [ $self, $args{host} ]);
    }
}

sub removeHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $ret = $self->_entity->removeHost(%args);
    
    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('addHost'),
            parameters => [ $self, $args{host} ]
        );
    }
}

1;
