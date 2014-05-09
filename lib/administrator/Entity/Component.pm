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
use Kanopya::Config;
use General;
use ParamPreset;
use ClassType::ComponentType;

use Data::Dumper;
use TryCatch;

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
    param_presets => {
        is_virtual   => 1,
        is_editable  => 1,
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

    return $self->component_type->component_name .
               (defined $self->service_provider ? " (on " . $self->service_provider->label . ")" : "");
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

    # Avoid abstract Entity::Component instantiation
    if ($class eq "Entity::Component") {
        throw Kanopya::Exception::Internal::AbstractClass();
    }

    $class =~ /Entity::Component.*::(\D+)(\d*)/;
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
    my $attrdefs = $class->_attributesDefinition(trunc => "Entity::Component");
    while (my ($name, $attr) = each %{ $attrdefs }) {
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
    return $self->update(%{ $args{conf} });
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

Call the General method, but change the included path to
the component template directory.

=end classdoc
=cut

sub getTemplateConfiguration {
    my $self = shift;

    my $conf = General::getTemplateConfiguration();
    $conf->{INCLUDE_PATH} = Kanopya::Config::getKanopyaDir() . '/templates/';

    return $conf;
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

    if (defined $self->param_preset) {
        $self->param_preset->remove();
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
    my $masternode;

    try {
        $masternode = $self->findRelated(filters => [ 'component_nodes' ],
                                         hash => { master_node => 1 })->node;
    } catch($err) {
        $masternode = undef;
    }

    return $masternode;
}

sub getActiveNodes {
    my ($self, %args)   = @_;

    my @component_nodes = $self->component_nodes;
    my @nodes           = ();
    for my $component_node (@component_nodes) {
        my $n = $component_node->node;
        if ($n->host->host_state =~ /^up:\d+$/ &&
            ($n->host->getNodeState())[0] =~ m/^(in|pregoingin|goingin)$/) {
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
    if (! $self->$attribute) {
        my $error = $args{error};
        if (!$error) {
            my $attrs = $self->toJSON();
            $attribute .= "_id" if ! defined $attrs->{$attribute};
            $error = "There is no " . lcfirst($attrs->{$attribute}->{label}) .
                     " configured for component ". $self->label;
        }

        throw Kanopya::Exception::InvalidConfiguration(
            error => $error,
            component => $self
        );
    }

}

sub checkDependency {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'component' ]);

    my $component = $args{component};
    my ($state, $uptime) = $component->service_provider->getState();
    if ($component->service_provider->id != $self->service_provider->id &&
        $state ne "up" && $state ne "updating") {
        throw Kanopya::Exception::InvalidConfiguration(
            error => "$component on ".$component->service_provider->cluster_name." has to be up to start $self (not $state)",
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
component is not loadbalanced : 0.0.0.0
component is loadbalanced : host adminIp   

@return ip address

=end classdoc
=cut

sub getListenIp {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['host','port']);
    if($self->getBalancerAddress(port => $args{port})) {
        return $args{host}->adminIp;
    } else {
        return '0.0.0.0';
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

    General::checkParams(args => \%args, optional => { 'port' => undef, 'service' => undef });

    my $keepalived = eval { $self->service_provider->getComponent(name => 'Keepalived') };
    if ($keepalived) {
        my @vrrpinstances = $keepalived->keepalived1_vrrpinstances;
        return $vrrpinstances[0]->virtualip->ip_addr;
    }
    else {
        try {
            my $ip = $self->getBalancerAddress(port    => $args{port},
                                               service => $args{service});
            if ($ip) {
                return $ip;
            }
        }
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

    if (defined ($args{service})) {
        my $conf = $self->getNetConf;
        SERVICE:
        for my $service (keys %{$conf}) {
            if ($service eq $args{service}) {
                $args{port} = $conf->{$service}->{port};
                last SERVICE;
            }
        }
    }

    General::checkParams(args => \%args, required => [ 'port' ],
                                         optional => { service => undef });

    my $comp_name = $self->component_type->component_name;
    if($comp_name eq 'Haproxy') {
        return undef;
    }
    
    my $listen_addr = undef;
    my @haproxy_entries = $self->haproxy1s_listen;
    for my $listen (@haproxy_entries) {
        if ($listen->listen_component_port eq $args{port}) {
            if ($listen->listen_ip ne '0.0.0.0') {
                $listen_addr = $listen->listen_ip;
                last;
            } else {
                $listen_addr = $listen->haproxy1->getMasterNode->fqdn;
                last;
            }
        }
    }

    if (! $listen_addr) {
        $log->warn("No loalbalancer entry found for port $args{port} for $comp_name");
    }

    return $listen_addr;
}

sub isBalanced {
    my ($self, %args) = @_;
    my $comp_name = $self->component_type->component_name;

    return 0 if $comp_name eq 'Haproxy';

    my @haproxy_entries = $self->haproxy1s_listen;
    return scalar(@haproxy_entries) ? 1 : 0;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $manifest = "";
    my $dependencies = [];
    my $listens = { };

    LISTEN:
    for my $listen ($self->haproxy1s_listen) {
        next LISTEN if $self->id != $listen->listen_component_id;    

        $listens->{$listen->listen_name . '-'.$args{host}->node->node_hostname} = {
            listening_service => $listen->listen_name,
            ports             => $listen->listen_component_port,
            server_names      => $args{host}->node->node_hostname,
            ipaddresses       => $args{host}->adminIp,
            options           => 'check',
            tag               => 'kanopya::haproxy'
        },

        push @$dependencies, $listen->haproxy1;
    }
    
    return {
        loadbalanced => {
            classes => {
                'kanopya::loadbalanced' => {
                    members => $listens
                }
            },
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

    my $title = ref($args{name}) eq 'ARRAY' ?
                '[ ' . join(', ', map { "'" . $_ . "'" } @{$args{name}}) . ' ]' :
                "'" . $args{name} . "'";

    return "$args{resource} { $title:\n" .
           ($args{require} ? "  require => [ " . join(' ,', @{$args{require}}) . " ],\n" : '') .
           join("\n", @dumper) . "\n" .
           "}\n";
}


=pod
=begin classdoc

User friendly shortcut to get/set the extra configuration stored in param presets. 

=end classdoc
=cut

sub extraConfiguration {
    my ($self, @args) = @_;

    return $self->paramPresets(@args);
}


=pod
=begin classdoc

Set/get the virtual attribute param_preset.

=end classdoc
=cut

sub paramPresets {
    my ($self, @args) = @_;
    if (scalar(@args)) {
        if (defined $self->param_preset) {
            $self->param_preset->remove();
        }
        my $value = pop(@args);
        if ($value eq '') {
            $log->warn("Ignoring empty string for 'param_preset'");
            return;
        }
        my $pp = ParamPreset->new(params => $value);
        $self->param_preset_id($pp->id);
    }
    else {
        try {
            return $self->param_preset->load();
        }
        catch ($err) {
            return {};
        }
    }
}

1;
