# EActivateHost.pm - Operation class implementing Host activation operation

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

package EEntity::EOperation::EActivateHost;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EEntity;

use Entity::ServiceProvider::Cluster;
use Entity::Host;

my $log = get_logger("");
my $errmsg;
our $VERSION = '1.00';

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "host" ]);

    # check if host is not active
    if ($self->{context}->{host}->active) {
        $errmsg = "Host <" . $self->{context}->{host}->id . "> is already active";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute{
    my $self = shift;
    $self->SUPER::execute();

    # set host active in db
    $self->{context}->{host}->setAttr(name => 'active', value => 1, save => 1);

    $log->info("Host <" . $self->{context}->{host}->id . "> is now active");
}

1;
