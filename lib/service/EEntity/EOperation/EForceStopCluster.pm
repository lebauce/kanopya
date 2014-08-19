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

package EEntity::EOperation::EForceStopCluster;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity;
use EEntity;

use TryCatch;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);
}


sub execute {
    my $self = shift;
 
    # Force stop all nodes of the cluster
    foreach my $node (reverse $self->{context}->{cluster}->nodesByWeight()) {
        try {
            # Ask to the deployment manager t release the node
            # Merge all manager parameters for the deployment manager
            my $managers_params = $self->{context}->{cluster}->getManagerParameters();
            my $deployer = $self->{context}->{cluster}->getManager(manager_type => 'DeploymentManager');
            EEntity->new(entity => $deployer)->releaseNode(node     => $node,
                                                           workflow => $self->workflow,
                                                           %{ $managers_params });
        }
        catch ($err) {
            $log->warn($err);
        }

        # component migration
        $log->info('Processing cluster components quick remove for node <' . $node->host->id . '>');

        my $ehost = EEntity->new(entity => $node->host);
        my @components = $self->{context}->{cluster}->getComponents(category => "all");
        foreach my $component (@components) {
            EEntity->new(data => $component)->cleanNode(host => $ehost);
        }

        $node->host->host_initiatorname(undef);
        $self->{context}->{cluster}->unregisterNode(node => $node);
    }

    $self->{context}->{cluster}->setState(state => "down");
}

1;
