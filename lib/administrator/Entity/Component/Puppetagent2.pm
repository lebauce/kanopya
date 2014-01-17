# Puppetagent2.pm - Puppet agent (Adminstrator side)
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
# Created 4 sept 2010

package Entity::Component::Puppetagent2;
use base "Entity::Component";

use strict;
use warnings;

use Entity::ServiceProvider::Cluster;
use Kanopya::Exceptions;
use Kanopya::Config;

use Hash::Merge qw(merge);

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    puppetagent2_options => {
        label         => 'Puppet agent options',
        type          => 'string',
        pattern       => '^.*$',
        is_mandatory  => 0,
        is_editable   => 1,
    },
    puppetagent2_mode => {
        label         => 'Puppet Master to use',
        type          => 'enum',
        options       => ['kanopya','custom'],
        pattern       => '^.*$',
        is_mandatory  => 1,
        is_editable   => 1,
    },
    puppetagent2_masterip => {
        label         => 'Puppet Master IP',
        type          => 'string',
        pattern       => '^.*$',
        is_mandatory  => 0,
        is_editable   => 1,
    },
    puppetagent2_masterfqdn => {
        label         => 'Puppet Master FQDN',
        type          => 'string',
        pattern       => '^.*$',
        is_mandatory  => 0,
        is_editable   => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub priority { return 5; }

sub setConf {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};
    if ($conf->{puppetagent2_mode} eq 'kanopya') {
        my $master = $self->getPuppetMaster->getMasterNode;

        $conf->{puppetagent2_masterip}   = $master->adminIp;
        $conf->{puppetagent2_masterfqdn} = $master->fqdn;
    }
    $self->SUPER::setConf(conf => $conf);
}

sub getPuppetMaster {
    my $self = shift;
    my %args = @_;

    my $kanopya_cluster = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    return $kanopya_cluster->getComponent(name => "Puppetmaster");
}

sub getHostsEntries {
    my ($self) = @_;

    my $fqdn = $self->puppetagent2_masterfqdn;
    my @tmp = split(/\./, $fqdn);
    my $hostname = shift @tmp;

    return [ { ip         => $self->puppetagent2_masterip,
               fqdn       => $fqdn,
               aliases    => [ $hostname ] } ];
}

sub getBaseConfiguration {
    my ($class) = @_;

    my $master = $class->getPuppetMaster->getMasterNode;

    return $master ? {
        puppetagent2_options    => '--no-client',
        puppetagent2_mode       => 'kanopya',
        puppetagent2_masterip   => $master->adminIp,
        puppetagent2_masterfqdn => $master->fqdn
    } : { };
}

sub getPuppetDefinitions {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    my $node = $args{node};
    my $host = $node->host;
    my $cluster = $node->service_provider;
    my @components = sort { $a->priority <=> $b->priority } $node->components;
    my $cluster_name = $cluster->cluster_name;
    my $sourcepath = $cluster_name . '/' . $node->node_hostname;

    my $definition = {
        host_fqdn  => $node->fqdn,
        cluster    => $cluster_name,
        sourcepath => $sourcepath,
        admin_ip   => $node->adminIp,
    };
 
    foreach my $component (@components) {
        my $config_hash = {};
        my $component_name = lc($component->component_type->component_name);
        my $component_node = $component->find(related => 'component_nodes',
                                              hash    => { node_id => $node->id });

        my $puppet_definitions = $component->getPuppetDefinition(host    => $host,
                                                                 cluster => $cluster);

        my $listen = {};
        my $access = {};
        my $netconf = $component->getNetConf;

        my $configuration = {
            master => ($component_node->master_node == 1) ? 1 : 0,
            listen => $listen,
            access => $access
        };

        for my $service (keys %{$netconf}) {
            $listen->{$service} = {
                ip => $component->getListenIp(host => $host,
                                              port => $netconf->{$service}->{port})
            };
            $access->{$service} = {
                ip => $component->getAccessIp(host => $host,
                                              port => $netconf->{$service}->{port})
            };
        }

        for my $chunk (values %{$puppet_definitions}) {
            next if ! $chunk->{classes};

            for my $dependency (@{$chunk->{dependencies} || []},
                                @{$chunk->{optionals} || []}) {
                my $name = lc($dependency->component_type->component_name);
                my @nodes = map { $_->fqdn } $dependency->nodes;
                my $hash = { nodes => \@nodes, %{$chunk->{params} || {}} };

                if (($dependency->service_provider->id == $cluster->id) ||
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

            my @classes = keys %{$chunk->{classes}};
            my $data = {
                classes    => \@classes,
                components => { $component_name => $configuration },
                %{$chunk->{params} || {}}
            };

            for my $class (@classes) {
                my $parameters = $chunk->{classes}->{$class};
                for my $parameter (keys %{$parameters}) {
                    $data->{$class . '::' . $parameter} = $parameters->{$parameter};
                }
            }

            $definition = merge($definition, $data);
        }
    }

    return $definition;
}

1;
