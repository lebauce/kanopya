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
use Kanopya::Exceptions;
use Data::Dumper;

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

    my $manifest = "";
    my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);
    my $fqdn = $args{host}->node->fqdn;
    my @components = sort { $a->component->priority <=> $b->component->priority }
                     $args{host}->node->component_nodes;

    my $config_hash = { };
    foreach my $component_node (@components) {
        my $component = $component_node->component;
        my $component_name = lc($component->component_type->component_name);
        my $ecomponent = EEntity->new(entity => $component);
        $ecomponent->generateConfiguration(
            cluster => $args{cluster},
            host    => $args{host}
        );

        my $puppet_definitions = $ecomponent->getPuppetDefinition(
            host    => $args{host},
            cluster => $args{cluster},
        );

        my $listen = {};
        my $access = {};
        my $netconf = $component->getNetConf;
        for my $service (keys %{$netconf}) {
            $listen->{$service} = {
                ip => $component->getListenIp(host => $args{host},
                                              port => $netconf->{$service}->{port})
            };
            $access->{$service} = {
                ip => $component->getAccessIp(host => $args{host},
                                              port => $netconf->{$service}->{port})
            };
        }

        my $configuration = {
            master => ($component_node->master_node == 1 ? 1 : 0),
            listen => $listen,
            access => $access
        };

        for my $chunk (keys %{$puppet_definitions}) {
            $manifest .= $puppet_definitions->{$chunk}->{manifest} . "\n";
            for my $dependency (@{$puppet_definitions->{$chunk}->{dependencies} || []},
                                @{$puppet_definitions->{$chunk}->{optionals} || []}) {
                my $name = lc($dependency->component_type->component_name);
                my @nodes = map { $_->fqdn } $dependency->nodes;
                my $hash = { nodes => \@nodes, %{$puppet_definitions->{$chunk}->{params} || {}} };

                if (($dependency->service_provider->id == $self->service_provider->id) ||
                    (($dependency->service_provider->getState)[0] eq "up")) {
                    $netconf = $dependency->getNetConf;
                    for my $service (keys %{$netconf}) {
                        $hash->{$service} = {
                            ip    => $dependency->getAccessIp(port => $netconf->{$service}->{port}),
                            tag   => $dependency->getMasterNode->fqdn,
                        };
                    }
                    $configuration->{$name} = $hash;
                }
            }
        }

        $config_hash->{$component_name} = $configuration;
    }

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Quotekeys = 0;

    my @dumper = split('\n', Dumper($config_hash));
    shift @dumper; pop @dumper;
    $manifest = '$components = { ' . join("\n", @dumper) . " }\n" . $manifest;

    if ($self->puppetagent2_mode eq 'kanopya') {
        # create, sign and push a puppet certificate on the image
        $log->info('Puppent agent component configured with kanopya puppet master');
        my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);

        $puppetmaster->createHostManifest(
            host_fqdn          => $args{host}->node->fqdn,
            puppet_definitions => $manifest,
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

    General::checkParams(args => \%args, required => [ 'cluster' ],
                                         optional => { 'host' => undef,
                                                       'tags' => [ ] });

    my @ehosts = ($args{host}) || (map { EEntity->new(entity => $_) } @{ $args{cluster}->getHosts() });
    for my $ehost (@ehosts) {
        $self->generatePuppetDefinitions(%args,
                                         host => $ehost);
    }

    my $ret = -1;
    my $timeout = 180;
    my @hosts = (defined $args{host}) ? ($args{host}->node->fqdn) : (map { $_->node->fqdn } @{ $args{cluster}->getHosts() });
    my $puppetmaster = (Entity::ServiceProvider::Cluster->getKanopyaCluster)->getComponent(name => 'Puppetmaster');
    my $econtext = (EEntity->new(data => $puppetmaster))->getEContext;

    do {
        if ($ret != -1) {
            sleep 5;
            $timeout -= 5;
        }

        my $command = "puppet kick --foreground --parallel " . (scalar @hosts);
        map { $command .= " --tag " . $_; } @{$args{tags}};
        map { $command .= " --host $_" } @hosts;

        $ret = $econtext->execute(command => $command);

        while ($ret->{stdout} =~ /([\w.\-]+) finished with exit code (\d+)/g) {
            # If the host is down or not reachable, the exit code is 2
            # If the host is already applying manifest, the exit code is 3
            # In both cases, puppet kick returns 3 so we filter the broken hosts
            # and the hosts that have already applied the manifest
            if ($2 != 3) {
                @hosts = grep{ $_ ne $1 } @hosts;
            }
        }
    } while ($timeout > 0 && (scalar @hosts));
}

sub isUp {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );

    my $puppetmaster = (Entity::ServiceProvider::Cluster->getKanopyaCluster)->getComponent(name => 'Puppetmaster');
    my $econtext     = (EEntity->new(data => $puppetmaster))->getEContext;
    # Check if /var/lib/puppet/yaml/node/FQDN.yaml exists on puppet master
    # (means that the catalog has been applied at least one time on that node).
    my $ret          = $econtext->execute(command => '[ -f /var/lib/puppet/yaml/node/' . $args{host}->node->fqdn . '.yaml ]');
    if ($ret->{exitcode} == 0) {
        my $reconfigure = { };
        $self->applyConfiguration(cluster => $args{cluster},
                                  host    => $args{host},
                                  tags    => [ 'finished' ]);
        my @components  = $args{cluster}->getComponents(category => "all");
        # Sort the components by service provider
        for my $component (@components) {
            my $defs = $component->getPuppetDefinition(%args);
            for my $chunk (keys %{$defs}) {
                my @dependencies = @{$defs->{$chunk}->{dependencies} || []};
                for my $dependency (@dependencies) {
                    my $key = $dependency->service_provider->id;
                    if (! defined ($reconfigure->{$key})) {
                        $reconfigure->{$key} = [ $dependency ];
                    } else {
                        push @{$reconfigure->{$key}}, $dependency;
                    }
                }
            }
        }

        # Reconfigure the required components for each cluster
        for my $cluster_id (keys %{$reconfigure}) {
            my $cluster = $reconfigure->{$cluster_id}->[0]->service_provider;
            my @tags = map {
                           'kanopya::' . lc($_->component_type->component_name)
                       } @{$reconfigure->{$cluster_id}};
            EEntity->new(entity => $cluster)->reconfigure(tags => \@tags);
        }

        if (scalar (keys %{$reconfigure})) {
            $self->applyConfiguration(cluster => $args{cluster},
                                      host    => $args{host});
        }

        return 1;
    }
    else {
        return 0;
    }
}

1;
