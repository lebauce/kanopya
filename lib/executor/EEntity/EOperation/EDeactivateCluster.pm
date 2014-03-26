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

package EEntity::EOperation::EDeactivateCluster;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;
use Entity::Systemimage;

my $log = get_logger("");
my $errmsg;


sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);
}


sub execute{
    my $self = shift;

    # Check if cluster is active
    if (not $self->{context}->{cluster}->getAttr(name => 'active')) {
        $errmsg = "Cluster <" . $self->{context}->{cluster}->getAttr(name => 'entity_id') . "> is not active";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Check the cluster state
    my ($cluster_state, $timestamp) = split ':', $self->{context}->{cluster}->getAttr(name => 'cluster_state');

    if ($cluster_state eq 'up') {
        $errmsg = "Cluster <" . $self->{context}->{cluster}->getAttr(name => 'entity_id') . "> is not down";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # set cluster active in db
    $self->{context}->{cluster}->setAttr(name => 'active', value => 0, save => 1);
    $log->info("Cluster <" . $self->{context}->{cluster}->cluster_name . "> deactivated");
}

1;
