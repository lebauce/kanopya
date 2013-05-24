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

package EEntity::EOperation::EUpdatePuppetCluster;
use base "EEntity::EOperation";

use Kanopya::Exceptions;
use strict;
use warnings;
use EEntity;

use Log::Log4perl 'get_logger';

my $log = get_logger("");
my $errmsg;

sub prepare {
    my ($self, %args) = @_;
    $self->SUPER::prepare();

    # check if this cluster has a puppet agent component
    my $puppetagent = eval {
        $self->{context}->{cluster}->getComponent(category => 'Configurationagent');
    };
    if (not $puppetagent) {
        my $errmsg = "UpdatePuppetCluster Operation cannot be used without a puppet " .
                     "agent component configured on the cluster";
        $log->error($errmsg);
        thow Kanopya::Exception::Internal(error => $errmsg);
    } else {
        $self->{context}->{puppetagent} = EEntity->new(
            data => $puppetagent
        );
    }
}

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute();

    $self->{context}->{puppetagent}->applyConfiguration(
        cluster => $self->{context}->{cluster}
    );
}

1;
