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

package EEntity::EOperation::EDeactivateHost;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "host_to_deactivate" ]);
}

sub execute{
    my $self = shift;

    # Check if host is not active
    if (not $self->{context}->{host_to_deactivate}->active) {
        $errmsg = "Host <" . $self->{context}->{host_to_deactivate}->id . "> is not active";
        $log->debug($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Check if host is used as a node
    if ($self->{context}->{host_to_deactivate}->node) {
        $errmsg = "Host <" . $self->{context}->{host_to_deactivate}->id . "> is a node";
        $log->debug($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # set host active in db
    $self->{context}->{host_to_deactivate}->setAttr(name => 'active', value => 0, save => 1);

    $log->info("Host <" . $self->{context}->{host_to_deactivate}->id . "> deactivated");
}

1;