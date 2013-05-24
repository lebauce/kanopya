# EUpdateComponent.pm - Operation class implementing component files 
# regeneration and cluster Nodes reconfiguration via puppet

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
# Created 29 may 2012

package EEntity::EOperation::EUpdateComponent;
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

    # check if this cluster has a puppet agent component
    my $cluster       = $self->{context}->{component}->service_provider;
    my $puppetagent   = $cluster->getComponent(name    => 'Puppetagent',
                                               version => 2);
    
    if (not $puppetagent) {
        my $errmsg = "UpdateComponent Operation cannot be used without a " .
                     "puppet agent component configured on the cluster";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    else {
        $self->{context}->{puppetagent} = EEntity->new(data => $puppetagent);
    }
    
    # Instanciate the bootserver Cluster
    my $bootserver       = EEntity->new(entity => Entity::ServiceProvider::Cluster->getKanopyaCluster);
          
    my $puppetmaster  = $self->{context}->{bootserver}->getComponent(name => 'Puppetmaster', version => 2);
    $self->{context}->{puppetmaster} = EEntity->new(data => $puppetmaster);
}

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    my $cluster = $self->{context}->{component}->service_provider;
    for my $host ($cluster->getHosts()) {
        my $ehost              = EEntity->new(data => $host);
        my $puppet_definitions = "";
        $self->{context}->{component}->generateConfiguration(
            cluster => $cluster,
            host    => $ehost
        );
        $puppet_definitions   .= $self->{context}->{component}->getPuppetDefinition(
            host    => $host,
            cluster => $cluster
        )->{manifest};

        $self->{context}->{puppetmaster}->createHostManifest(
                host_fqdn          => $host->node->fqdn,
                puppet_definitions => $puppet_definitions,
                sourcepath         => $cluster->cluster_name
                                      . '/' . $host->node->node_hostname
        );
    }
    $self->{context}->{puppetagent}->applyManifest(cluster => $cluster);
}

1;
