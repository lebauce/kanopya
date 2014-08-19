#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EServiceProvider::ECluster;
use base EEntity;

use strict;
use warnings;

use Entity;
use Entity::ServiceProvider::Cluster;
use General;
use Kanopya::Config;
use EEntity;
use EEntity;
use Entity::NetconfRole;
use Entity::Systemimage;

use TryCatch;
use Template;
use String::Random;
use IO::Socket;
use Net::Ping;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub create {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'managers' ]);

    # Generate cluster base hostname
    # Who will dare using that pattern? $str =~ s/([_.])/${ \($1 eq q?_??"-":$,) }/g;
    if (!defined $self->cluster_basehostname || $self->cluster_basehostname eq '') {
        my $base_hostname = lc($self->cluster_name);
        $base_hostname =~ s/_/-/g;
        $base_hostname =~ s/\.//g;

        $self->cluster_basehostname($base_hostname);
    }

    # Create cluster directory
    my $dir = $self->_executor->getConf->{clusters_directory};
    my $command = "mkdir -p $dir";
    $self->_host->getEContext->execute(command => $command);

    # Add all the components provided by the master image
    if ($self->masterimage && defined $args{managers}->{deployment_manager}) {
        # Firstly set the service provider type from masterimage
        $self->service_provider_type_id($self->masterimage->masterimage_cluster_type->id);

        my $params = $args{managers}->{deployment_manager}->{manager_params};
        foreach my $component ($self->masterimage->components_provided) {
            $params->{components}->{$component->component_type->component_name} = {
                component_type => $component->component_type_id
            };
        }

        if ($self->masterimage->masterimage_defaultkernel && ! $self->kernel) {
            $self->kernel_id($self->masterimage->masterimage_defaultkernel->id);
        }
    }
    $self->save();

    # Set default permissions on this cluster for the related customer
    $self->propagatePermissions(related => $self);

    # Use the method for policy applying to configure manager, components, and interfaces.
    $self->applyPolicies(
        pattern => {
            managers        => $args{managers},
            billing_limits  => $args{billing_limits},
            orchestration   => $args{orchestration},
        }
    );
}

sub remove {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'keep_systemimages' => 0, 'erollback' => undef });

    # Check if cluster is active
    if ($self->active) {
        throw Kanopya::Exception::Internal(error => "Cluster <" . $self->label . "> is active");
    }

    # Delete the cluster remaning systemimages
    try {
        # TODO: Ensure we are not retrieving systemimage of oather clusters
        my @systemimages =  Entity::Systemimage->search(hash => {
                                systemimage_name => { 'LIKE' => $self->cluster_name . '_%' }
                            });

        if (scalar(@systemimages) > 0 && ! $args{keep_systemimages}) {
            $log->info("Removing the <" . scalar(@systemimages) . "> cluster systemimage(s)");
            for my $systemimage (map {  EEntity->new(entity => $_)  } @systemimages) {
                $log->debug("Removing systemimage <" . $systemimage->systemimage_name . ">");
                $systemimage->remove(erollback => $args{erollback});
            }
        }
    }
    catch ($err) {
        $log->warn("Unable to remove system iamges of the cluster: $err");
    }

    $self->delete();
}


sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    my @components = $self->getComponents(category => "all", order_by => "priority");

    $log->info('Processing cluster components configuration for this node');
    foreach my $component (@components) {
        EEntity->new(entity => $component)->postStartNode(node      => $args{node},
                                                          erollback => $args{erollback});
    }
}

sub readyNodeAddition {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    # Ask to all cluster component if they are ready for node addition.
    my @components = $self->getComponents(category => "all");
    foreach my $component (map { EEntity->new(entity => $_) } @components) {
        if (! $component->readyNodeAddition(node => $args{node})) {
            $log->info("Component " . $component->label . " not ready for node addition");
            return 0;
        }
    }
    return 1;
}

sub readyNodeRemoving {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    # Ask to all cluster component if they are ready for node addition.
    my @components = $self->getComponents(category => "all");
    foreach my $component (map { EEntity->new(entity => $_) } @components) {
        $log->info("Component " . $component->label . " not ready for node removing");
        if (! $component->readyNodeRemoving(host_id => $args{host}->id)) {
            return 0;
        }
    }
    return 1;
}


sub postStopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    # Ask to all cluster component if they are ready for node addition.
    my @components = $self->getComponents(category => "all");
    foreach my $component (@components) {
        EEntity->new(data => $component)->postStopNode(host => $args{host});
    }
}

sub reconfigure {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'host' => undef, 'tags' => [] });

    my $agent = $self->getComponent(category => "Configurationagent");
    my @nodes = map { $_->node } defined($args{host}) ? ($args{host}) : @{ $self->getHosts() };
    EEntity->new(data => $agent)->applyConfiguration(nodes => \@nodes, tags => $args{tags});
}

sub unregisterNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    # remove the node working directory where generated files are
    # stored.
    my $dir = $self->_executor->getConf->{clusters_directory} . '/' . $args{node}->node_hostname;

    $self->_host->getEContext->execute(command => "rm -r $dir");
    $self->_host->getEContext->execute(
        command => "rm /var/lib/puppet/yaml/node/" . $args{node}->fqdn . ".yaml"
    );

    $args{node}->host->setAttr(name => "host_initiatorname", value => undef, save => 1);

    return $self->_entity->unregisterNode(%args);
}

1;
