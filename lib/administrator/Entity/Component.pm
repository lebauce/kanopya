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

=pod
=begin classdoc

This module is components abstract class.

=end classdoc
=cut

package Entity::Component;
use base Entity;

use strict;
use warnings;

use Kanopya::Exceptions;
use General;
use ClassType::ComponentType;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    service_provider_id => {
        pattern        => '^\d*$',
        is_mandatory   => 1,
        is_extended    => 0,
        is_editable    => 0
    },
    component_type_id => {
        label          => 'Component type',
        pattern        => '^\d*$',
        type           => 'relation',
        relation       => 'single',
        is_mandatory   => 1,
        is_extended    => 0,
        is_editable    => 1
    },
    component_template_id => {
        pattern        => '^\d*$',
        is_mandatory   => 0,
        is_extended    => 0,
        is_editable    => 0
    },
    priority => {
        is_virtual => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getConf => {
            description => 'get configuration of the component.',
        },
        setConf => {
            description => 'set configuration of the component.',
        },
    };
}

sub label {
    my $self = shift;

    return $self->component_type->component_name . " (on " .
           $self->service_provider->label . ")";
}

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod
=begin classdoc

@constructor

Create a new component from a component type name and version. 

@return the component instance.

=end classdoc
=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Avoid abstract Entity::Component instanciation
    if ($class !~ /Entity::Component.*::(\D+)(\d*)/) {
        $errmsg = "Entity::Component->new : Entity::Component must not " .
                  "be instanciated without a concret component class.";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $component_name    = $1;
    my $component_version = $2;

    # Merge the base configuration with args
    %args = %{ $merge->merge(\%args, $class->getBaseConfiguration()) };

    # We set the corresponding component_type
    my $hash = { component_name => $component_name };
    if (defined $component_version && $component_version) {
        $hash->{component_version} = $component_version;
    }
    $args{component_type_id} = ClassType::ComponentType->find(hash => $hash)->id;

    return $class->SUPER::new(%args);
}

sub search {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'hash' => {} });

    if (defined $args{custom}) {
        if (defined $args{custom}->{category}) {
            # TODO: try to use the many-to-mnay relation name 'component_type.component_categories.category_name'
            my $filter = 'component_type.component_type_categories.component_category.category_name';
            $args{hash}->{$filter} = delete $args{custom}->{category};
        }
        delete $args{custom};
    }
    return $class->SUPER::search(%args);
}


=pod
=begin classdoc

Generic method for getting simple component configuration.

=end classdoc
=cut

sub getConf {
    my $self = shift;
    my $conf = {};

    my $class = ref($self) || $self;
    my @relations;
    my $attrdefs = $class->getAttrDefs();
    while (my ($name, $attr) = each %{$attrdefs}) {
        if (defined $attr->{type} and $attr->{type} eq "relation") {
            push @relations, $name;
        }
    }

    return $self->toJSON(raw => 1, deep => 1, expand => \@relations);
}


=pod
=begin classdoc

Generic method for setting simple component configuration.
If a value differs from db contents, the attr is set, and the object saved.

=end classdoc
=cut

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    $self->update(%{ $args{conf} });
}


=pod
=begin classdoc

@return this component instance Template dir from database.

=end classdoc
=cut

sub getTemplateDirectory {
    my $self = shift;

    if (defined $self->component_template_id) {
        return $self->component_template->component_template_directory;
    }
}


=pod
=begin classdoc

Overrided to remove associated service_provider_manager.
Managers can't be cascade deleted because they are linked either to a a connector or a component.

=end classdoc
=cut

sub remove {
    my $self = shift;

    my @managers = ServiceProviderManager->search(hash => { manager_id => $self->id });
    for my $manager (@managers) {
        $manager->remove();
    }
    $self->SUPER::remove();
}

sub registerNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node' ],
                         optional => { 'master_node' => 0 });

    ComponentNode->new(component_id => $self->id,
                       node_id      => $args{node}->id,
                       master_node  => $args{master_node});
}

sub getMasterNode {
    my $self = shift;

    return $self->findRelated(filters => [ 'component_nodes' ], hash => { master_node => 1 })->node;
}

sub getActiveNodes {
    my ($self, %args)   = @_;

    my @component_nodes = $self->component_nodes;
    my @nodes           = ();
    for my $component_node (@component_nodes) {
        my $n = $component_node->node;
        if ($n->host->host_state =~ /^up:\d+$/ &&
            ($n->host->getNodeState())[0] eq "in") {
            push @nodes, $n;
        }
    }

    return @nodes;
}

sub toString {
    my $self = shift;

    my $component_name = $self->component_type->component_name;
    my $component_version = $self->component_type->component_version;

    return $component_name . " " . $component_version;
}

sub supportHotConfiguration {
    return 0;
}

sub priority {
    return 50;
}


=pod
=begin classdoc

Method to be overrided to get component basic configuration

@return %base_configuration

=end classdoc
=cut

sub getBaseConfiguration { return {}; }


=pod
=begin classdoc

Method to be overrided to insert in db default configuration for tables linked to component.

=end classdoc
=cut

sub insertDefaultExtendedConfiguration {}

=pod
=begin classdoc

Check that the configuration of the component is correct, raise an exception otherwise

=end classdoc
=cut

sub checkConfiguration {}

sub checkAttribute {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'attribute' ]);

    my $attribute = $args{attribute};
    my $error = $args{error};
    if (! $error) {
        my $attrs = $self->getAttrDefs();
        $attribute .= "_id" if ! defined $attrs->{$attribute};
        $error = "There is no " . lcfirst($attrs->{$attribute}->{label}) .
                 " configured for component ". $self->label;
    }

    if (! $self->$attribute) {
        throw Kanopya::Exception::InvalidConfiguration(
            error => $error,
            component => $self
        );
    }
}

sub getClusterizationType {}

sub getExecToTest {}

sub getNetConf {}

sub getHostsEntries { return; }

=pod
=begin classdoc

getListenIp gives ip address to use as "bind address" for this component configuration.
Today, Hard coded behaviors are:
component is not loadbalance : 0.0.0.0
component is loadbalanced : adminIp   

@return ip address

=end classdoc
=cut

sub getListenIp {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['host','port']);
    my $ip = $self->getBalancerAddress(port => $args{port});
    if(defined $ip) {
        return $ip;
    } else {
        return $args{host}->adminIp;
    }
}

=pod
=begin classdoc

getAccessIp gives ip address needed to contact this component.
Today, Hard coded behaviors are:
component is not highly available (no keepalived component) : masternode adminIp
component is highly available : first keepalived vip

@return ip address

=end classdoc
=cut

sub getAccessIp {
    my ($self, %args) = @_;
    my $keepalived = eval { $self->service_provider->getComponent(name => 'Keepalived') };
    my $ip;
    if($keepalived) {
        my @vrrpinstances = $keepalived->keepalived1_vrrpinstances;
        return $vrrpinstances[0]->virtualip->ip_addr;
    } else {
        return $self->getMasterNode->adminIp;
    }
}

=pod
=begin classdoc

@return loadbalancer ip address for this component on this port or undef if not balanced.

=end classdoc
=cut

sub getBalancerAddress {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['port']);
    my $comp_name = $self->component_type->component_name;
    if($comp_name eq 'Haproxy') {
        return undef;
    }
    
    my $listen_addr = 0;
    my @haproxy_entries = $self->haproxy1s_listen;
    LISTEN:
    for my $listen (@haproxy_entries) {
        if($listen->listen_component_port ne $args{port}) {
            next LISTEN;
        } else {
            if($listen->listen_ip ne '0.0.0.0') {
                $listen_addr = $listen->listen_ip;
                last;
            } else {
                $listen_addr = $listen->haproxy1->getMasterNode->fqdn;
                last;
            }
        }
    }
    if(! $listen_addr) {
        $log->warn("No loalbalancer entry found for port $args{port} for ".$comp_name);
        return undef;
    } else {
        return $listen_addr;
    }
}

sub isBalanced {
    my ($self, %args) = @_;
    my $comp_name = $self->component_type->component_name;
    if($comp_name eq 'Haproxy') {
        return 0;
    }
    my @haproxy_entries = $self->haproxy1s_listen;
    if(scalar(@haproxy_entries)) {
        return 1;
    }
    return 0;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;
    my $manifest = "";
    my $dependencies = [];
    my @listens = $self->haproxy1s_listen;
    LISTEN:
    for my $listen (@listens) {
        next LISTEN if $self->id != $listen->listen_component_id;    
        $manifest .=  $self->instanciatePuppetResource(
                             resource => '@@haproxy::balancermember',
                             name => $listen->listen_name .'-'.$args{host}->node->node_hostname,
                             params => {
                                listening_service => $listen->listen_name,
                                ports             => $listen->listen_component_port,
                                server_names      => $args{host}->node->node_hostname,
                                ipaddresses       => $args{host}->adminIp,
                                options           => 'check'
                             }
                          );
        push @$dependencies, $listen->haproxy1;
    }
    
    
    return {
        loadbalanced => {
            manifest     => $manifest,
            dependencies => $dependencies
        }
    }
}

sub instanciatePuppetResource {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'name' ],
                                         optional => { 'params' => {},
                                                       'resource' => 'class',
                                                       'require' => undef });

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Quotekeys = 0;

    my @dumper = split('\n', Dumper($args{params}));
    shift @dumper;
    pop @dumper;

    return "$args{resource} { '$args{name}':\n" .
           ($args{require} ? "  require => [ " . join(' ,', @{$args{require}}) . " ],\n" : '') .
           join("\n", @dumper) . "\n" .
           "}\n";
}

1;
