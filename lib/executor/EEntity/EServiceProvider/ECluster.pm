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

    General::checkParams(args     => \%args,
                         required => [ 'managers' ],
                         optional => { 'interfaces' => {}, 'components' => {} });

    # Generate cluster base hostname
    # Who will dare using that pattern? $str =~ s/([_.])/${ \($1 eq q?_??"-":$,) }/g;
    if (!defined $self->cluster_basehostname || $self->cluster_basehostname eq '') {
        my $base_hostname = lc($self->cluster_name);
        $base_hostname =~ s/_/-/g;
        $base_hostname =~ s/\.//g;

        $self->cluster_basehostname($base_hostname);
    }

    # Create cluster directory
    my $dir = $self->_executor->getConf->{clusters_directory} . '/' . $self->cluster_name;
    my $command = "mkdir -p $dir";
    $self->_host->getEContext->execute(command => $command);

    # Add all the components provided by the master image
    if ($self->masterimage) {
        # Firstly set the service provider type from masterimage
        $self->service_provider_type_id($self->masterimage->masterimage_cluster_type->id);

        foreach my $component ($self->masterimage->components_provided) {
            $args{components}->{$component->component_type->component_name} = {
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
            components      => $args{components},
            interfaces      => $args{interfaces},
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
    my @systemimages = $self->systemimages;
    if (scalar(@systemimages) > 0 && ! $args{keep_systemimages}) {
        $log->info("Removing the <" . scalar(@systemimages) . "> cluster systemimage(s)");
        for my $systemimage (map {  EEntity->new(entity => $_)  } @systemimages) {
            $log->debug("Removing systemimage <" . $systemimage->systemimage_name . ">");
            $systemimage->remove(erollback => $args{erollback});
        }
    }

    # Remove cluster directory
    my $dir = $self->_executor->getConf->{clusters_directory} . '/' . $self->cluster_name;
    $self->_host->getEContext->execute(command => "rm -r $dir");

    $self->delete();
}


sub checkComponents {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my @components = sort { $a->priority <=> $b->priority } $args{host}->node->components;
    foreach my $component (@components) {
        my $component_name = $component->component_type->component_name;
        $log->debug("Browsing component: " . $component_name);

        my $ecomponent = EEntity->new(entity => $component);

        if (not $ecomponent->isUp(host => $args{host}, cluster => $self)) {
            $log->info("Component <$component_name> not yet operational on host <" . $args{host}->id .  ">");
            return 0;
        }
    }
    return 1;
}

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my @components = $self->getComponents(category => "all", order_by => "priority");

    $log->info('Processing cluster components configuration for this node');
    foreach my $component (@components) {
        EEntity->new(entity => $component)->postStartNode(
            cluster   => $self,
            host      => $args{host},
            erollback => $args{erollback}
        );
    }
}

sub stopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my @components = $self->getComponents(category => "all");
    $log->info('Processing cluster components configuration for this node');

    foreach my $component (@components) {
        EEntity->new(data => $component)->stopNode(
            host    => $args{host},
            cluster => $self
        );
    }
}

sub readyNodeRemoving {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    # Ask to all cluster component if they are ready for node addition.
    my @components = $self->getComponents(category => "all");
    foreach my $component (@components) {
        if (not EEntity->new(entity => $component)->readyNodeRemoving(host_id => $args{host}->id)) {
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
        EEntity->new(data => $component)->postStopNode(
            host    => $args{host},
            cluster => $self
        );
    }
}

sub reconfigure {
    my ($self, %args) = @_;

    my $agent = $self->getComponent(category => "Configurationagent");
    my $eagent = EEntity->new(data => $agent);
    $eagent->applyConfiguration(%args, cluster => $self);
}

sub unregisterNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    # remove the node working directory where generated files are
    # stored.
    my $dir = $self->_executor->getConf->{clusters_directory} . '/' .
              $self->cluster_name . '/' . $args{node}->node_hostname;

    $self->_host->getEContext->execute(command => "rm -r $dir");
    $self->_host->getEContext->execute(
        command => "rm /var/lib/puppet/yaml/node/" . $args{node}->fqdn . ".yaml"
    );

    $args{node}->setAttr(name => "node_hostname", value => undef, save => 1);
    $args{node}->host->setAttr(name => "host_initiatorname", value => undef, save => 1);

    return $self->_entity->unregisterNode(%args);
}

1;
