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
package EEntity::EComponent::EPuppetagent2;
use base "EEntity::EComponent";

use strict;
use Template;
use General;
use EEntity;
use Entity::ServiceProvider::Cluster;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['cluster','host','mount_point']);
    
    my $conf = $self->_entity->getConf();

    # Generation of /etc/default/puppet
    my $data = { 
        puppetagent2_bootstart => 'yes',
        puppetagent2_options   => $conf->{puppetagent2_options},
    };
    
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/default/puppet',
        template_dir  => '/templates/components/puppetagent',
        template_file => 'default_puppet.tt',
        data          => $data
    );
    
    $self->_host->getEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/default'
    );
    
    # Generation of puppet.conf
    $data = { 
        puppetagent2_masterserver => $conf->{puppetagent2_masterfqdn},
    };
     
    $file = $self->generateNodeFile( 
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/puppet/puppet.conf',
        template_dir  => '/templates/components/puppetagent',
        template_file => 'puppet.conf.tt', 
        data          => $data
    );

     $self->_host->getEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/puppet'
    );

    $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/puppet/auth.conf',
        template_dir  => '/templates/components/puppetagent',
        template_file => 'auth.conf.tt',
        data          => $data
    );

    $self->_host->getEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/puppet'
    );
}

sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster','mount_point', 'host' ]);

    if ($self->puppetagent2_mode eq 'kanopya') {
        # create, sign and push a puppet certificate on the image
        $log->info('Puppent agent component configured with kanopya puppet master');
        my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);

        $puppetmaster->createHostCertificate(
            mount_point => $args{mount_point},
            host_fqdn   => $args{host}->node->fqdn
        );
    }

    $self->configureNode(
        cluster     => $args{cluster},
        mount_point => $args{mount_point},
        host        => $args{host}
    );
    
    $self->addInitScripts(    
        mountpoint => $args{mount_point}, 
        scriptname => 'puppet', 
    );    

    $self->generatePuppetDefinitions(%args);
}

sub generatePuppetDefinitions {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);
    my $fqdn = $args{host}->node->fqdn;
    my $puppet_definitions = "";
    my $cluster_components = $args{cluster}->getComponents(category => "all", order_by => "priority");
    foreach my $component (@{ $cluster_components }) {
        my $ecomponent = EEntity->new(entity => $component);
        $ecomponent->generateConfiguration(
            cluster => $args{cluster},
            host    => $args{host}
        );

        # retrieve puppet definition to create manifest
        $puppet_definitions .= $ecomponent->getPuppetDefinition(
            host    => $args{host},
            cluster => $args{cluster},
        );
    }

    if ($self->puppetagent2_mode eq 'kanopya') {
        # create, sign and push a puppet certificate on the image
        $log->info('Puppent agent component configured with kanopya puppet master');
        my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);

        $puppetmaster->createHostManifest(
            host_fqdn          => $args{host}->node->fqdn,
            puppet_definitions => $puppet_definitions,
            sourcepath         => $args{cluster}->cluster_name . '/' . $args{host}->node->node_hostname
        );
    }
}

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    $self->applyConfiguration(%args);
}

sub postStopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    $self->applyConfiguration(%args);
}

sub applyConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster' ]);

    EEntity->new(entity => $self->getPuppetMaster)->updateSite();

    my @ehosts = map { EEntity->new(entity => $_) } @{ $args{cluster}->getHosts() };
    for my $ehost (@ehosts) {
        $self->generatePuppetDefinitions(%args,
                                         host => $ehost);
        $self->applyManifest(%args,
                             host => $ehost);
    }
}

sub applyAllManifests {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster' ]);

    my @ehosts = map { EEntity->new(entity => $_) } @{  $args{cluster}->getHosts() };
    for my $ehost (@ehosts) {
        $self->applyManifest(host => $ehost);
    }
}

sub applyManifest {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['host']);
    my $node             = $args{host}->node;
    my $puppetmaster     =
        (Entity::ServiceProvider::Cluster->getKanopyaCluster)->getComponent(name => 'Puppetmaster');
    my $econtext         = (EEntity->new(data => $puppetmaster))->getEContext;
    my $hostname         = $node->node_hostname . '.' . $node->service_provider->cluster_domainname;
    my $ret              = undef;
    my $timeout          = 180;
    do {
        if ($ret != undef) {
            sleep 5;
            $timeout -= 5;
        }
        $ret = $econtext->execute(command => 'puppet kick --foreground ' . $hostname);
    } while ($ret->{exitcode} == 3 && $timeout > 0);
    # `puppet kick` returns 3 when puppet is already running on the target node
}

1;
