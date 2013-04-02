#    Copyright © 2009-2012 Hedera Technology SAS
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

package EEntity::EOperation::ERemoveCluster;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::Systemimage;
use EEntity;

my $log = get_logger("");
my $errmsg;

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    # Check if cluster is active
    if ($self->{context}->{cluster}->active) {
        $errmsg = "Cluster <" . $self->{context}->{cluster}->id . "> is active";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    # Remove cluster directory
    my $dir = $self->_executor->getConf->{clusters_directory} . '/' . 
              $self->{context}->{cluster}->cluster_name;

    my $command = "rm -r $dir";
    $self->getEContext->execute(command => $command);

    $self->{context}->{cluster}->delete();
}

1;
