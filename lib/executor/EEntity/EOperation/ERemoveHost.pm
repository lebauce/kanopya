#    Copyright © 2011-2013 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EOperation::ERemoveHost;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::ServiceProvider;
use Entity::Host;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;


sub prepare {
    my ($self, %args) = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "host" ]);

    # check if host is not active
    if ($self->{context}->{host}->getAttr(name => 'active')) {
        $errmsg = "Host <" . $self->{context}->{host}->id . "> is still active";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    eval {
        $self->{context}->{host_manager} = $self->{context}->{host}->getHostManager;
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }
}

sub execute{
    my ($self, %args) = @_;
    $self->SUPER::execute();

    $self->{context}->{host_manager}->removeHost(host      => $self->{context}->{host},
                                                 erollback => $self->{erollback});
}

1;