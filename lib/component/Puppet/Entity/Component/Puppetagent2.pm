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

use TryCatch;
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

    # Get the puppet master on kanopya
    # TOD: Set the puppet master to the puppet agent attributes
    my $kanopya_cluster = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    return $kanopya_cluster->getComponent(name => "Puppetmaster");
}


=begin classdoc

Override the parent method to manually add the puppet master ip and fqdn,
as the puppet agent do not have regular ref to tis master.

=end classdoc
=cut

sub getHostsEntries {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { "dependencies" => 0 });

    # Get the entries of the hosts on which the puppet agent is installed
    my $entries = $self->SUPER::getHostsEntries(%args);

    # Manually add the puppet master in hosts entries
    if ($args{dependencies}) {
        my $fqdn = $self->puppetagent2_masterfqdn;
        my @names = split(/\./, $fqdn);
        $entries->{$self->puppetagent2_masterip} = {
            fqdn    => $fqdn,
            aliases => {
                'hostname' => shift(@names)
            }
        };
    }
    return $entries;
}


sub getBaseConfiguration {
    my ($class) = @_;

    try {
        my $master = $class->getPuppetMaster->getMasterNode;
        return {
            puppetagent2_options    => '--no-client',
            puppetagent2_mode       => 'kanopya',
            puppetagent2_masterip   => $master->adminIp,
            puppetagent2_masterfqdn => $master->fqdn
        }
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        return {};
    }
    catch ($err) { $err->rethrow() }
}

sub getPuppetDefinitions {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    my $definition = {
        host_fqdn  => $args{node}->fqdn,
        sourcepath => $args{node}->node_hostname,
        admin_ip   => $args{node}->adminIp,
    };
 
    my @components = sort { $a->priority <=> $b->priority } $args{node}->components;
    foreach my $component (@components) {
        my $component_name = lc($component->component_type->component_name);
        my $component_node = $component->find(related => 'component_nodes',
                                              hash    => { node_id => $args{node}->id });

        my $puppet_definitions = $component->getPuppetDefinition(node => $args{node});

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
                ip => $component->getListenIp(node => $args{node},
                                              port => $netconf->{$service}->{port})
            };
            $access->{$service} = {
                ip => $component->getAccessIp(node => $args{node},
                                              port => $netconf->{$service}->{port})
            };
        }

        for my $chunk (values %{ $puppet_definitions }) {
            next if ! $chunk->{classes};

            for my $dependency (@{ $chunk->{dependencies} || [] },
                                @{ $chunk->{optionals} || [] }) {
                my $name = lc($dependency->component_type->component_name);
                my @nodes = map { $_->fqdn } $dependency->nodes;
                my $hash = { nodes => \@nodes, %{$chunk->{params} || {}} };

                # TODO: test the state of the component instead of the node
                if (($dependency->getMasterNode->getState)[0] =~ m/^(in|goingin)$/) {
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

            my @classes = keys %{ $chunk->{classes} };
            my $data = {
                # Keep the classes hash for merge, witch to list bofore returning the manifest
                classes    => $chunk->{classes},
                components => { $component_name => $configuration },
                %{$chunk->{params} || {}}
            };

            for my $class (@classes) {
                my $parameters = $chunk->{classes}->{$class};
                for my $parameter (keys %{$parameters}) {
                    $data->{$class . '::' . $parameter} = $parameters->{$parameter};
                }
                # Remove the classe hash values to avoid to merge them
                # $chunk->{classes}->{$class} = undef;
            }

            $definition = merge($definition, $data);
        }
    }

    # Return the classes as a list
    my @classes = keys %{ $definition->{classes} };
    $definition->{classes} = \@classes;

    return $definition;
}

1;
