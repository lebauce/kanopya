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
        template_dir  => 'components/puppetagent',
        template_file => 'default_puppet.tt',
        data          => $data,
        mount_point   => $args{mount_point}
    );

    # Generation of puppet.conf
    $data = { 
        puppetagent2_masterserver => $conf->{puppetagent2_masterfqdn},
    };
     
    $file = $self->generateNodeFile( 
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/puppet/puppet.conf',
        template_dir  => 'components/puppetagent',
        template_file => 'puppet.conf.tt',
        data          => $data,
        mount_point   => $args{mount_point}
    );

    $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/puppet/auth.conf',
        template_dir  => 'components/puppetagent',
        template_file => 'auth.conf.tt',
        data          => $data,
        mount_point   => $args{mount_point}
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

sub stopNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    $log->info('Remove the certificate on the puppet master');
    my $puppetmaster = EEntity->new(entity => $self->getPuppetMaster);
    $puppetmaster->removeHostCertificate(host_fqdn => $args{host}->node->fqdn);
}

sub applyConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'cluster' ],
                         optional => { 'host' => undef,
                                       'hosts' => undef,
                                       'tags' => [] });

    my @ehosts;
    if (defined $args{host}) {
        @ehosts = ($args{host});
    }
    elsif (defined $args{hosts}) {
        @ehosts = @{ $args{hosts} };
    }
    else {
        @ehosts = map { EEntity->new(entity => $_->host) }
                  $self->getActiveNodes();
    }

    my $ret = -1;
    my $timeout = 360;
    my @hosts = (defined $args{host}) ? ($args{host}->node->fqdn) : (map { $_->node->fqdn } @{ $args{cluster}->getHosts() });
    my $puppetmaster = (Entity::ServiceProvider::Cluster->getKanopyaCluster)->getComponent(name => 'Puppetmaster');
    my $econtext = (EEntity->new(data => $puppetmaster))->getEContext;

    do {
        if ($ret != -1) {
            sleep 5;
            $timeout -= 5;
        }

        my $command = "puppet kick --configtimeout=900 --ignoreschedules --foreground --parallel " . (scalar @hosts);
        map { $command .= " --tag " . $_; } @{$args{tags}};
        map { $command .= " --host $_" } @hosts;

        $ret = $econtext->execute(command => $command,
                                  timeout => 900);

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

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    my $puppetmaster = (Entity::ServiceProvider::Cluster->getKanopyaCluster)->getComponent(name => 'Puppetmaster');
    my $econtext     = (EEntity->new(data => $puppetmaster))->getEContext;

    my $reconfigure = { };
    $self->applyConfiguration(cluster => $args{cluster},
                              host    => $args{host});

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

1;
