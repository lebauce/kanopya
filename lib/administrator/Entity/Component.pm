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
use ComponentNode;

use Data::Dumper;
use TryCatch;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
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
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 0,
        is_editable  => 0,
    },
    param_presets => {
        is_virtual   => 1,
        is_editable  => 1,
        on_demand    => 1,
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
        synchronize => {
            description => 'synchronize the component infrastructure.',
        },
    };
}

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


sub label {
    my $self = shift;

    my $label = $self->component_type->component_name;
    try {
        $label .= " (on " . $self->getMasterNode->label . ")";
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
       # Component not installed on any node yet
    }
    catch ($err) { $err->rethrow() }

    return $label;
}


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

Overrided to remove associated param presets.

=end classdoc
=cut

sub remove {
    my $self = shift;

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

    try {
        ComponentNode->new(component_id => $self->id,
                           node_id      => $args{node}->id,
                           master_node  => $args{master_node});
    }
    catch(Kanopya::Exception::DB::DuplicateEntry $err) {
        #pass
    }
    catch($err) {
        $err->rethrow();
    }
}

sub getMasterNode {
    my $self = shift;

    try {
        return $self->findRelated(filters => [ 'component_nodes' ],
                                  hash    => { master_node => 1 })->node;
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Component <" . $self->component_type->component_name .
                           "> has no master node yet."
              );
    }
    catch ($err) { $err->rethrow(); }
}

sub getActiveNodes {
    my ($self, %args)   = @_;

    my @component_nodes = $self->component_nodes;
    my @nodes           = ();
    for my $component_node (@component_nodes) {
        my $node = $component_node->node;
        if (($node->getState())[0] =~ m/^(in|pregoingin|goingin)$/) {
            push @nodes, $node;
        }
    }

    return \@nodes;
}

sub toString {
    my $self = shift;

    my $component_name = $self->component_type->component_name;
    my $component_version = $self->component_type->component_version;

    return $component_name . " " . $component_version;
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

@optional ignore a list of component to ignore

=end classdoc
=cut

sub checkConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'ignore' => [] });

    try {
        $log->debug("Checking dependency for related components of " . $self->label);
        for my $component (@{ $self->getDependentComponents() }) {
            $log->debug("Checking dependency for related component $component");
            if (scalar(grep { $component->id == $_->id } @{ $args{ignore} }) == 0) {
                $self->checkDependency(component => $component);
            }
            else {
                $log->debug("Ignore the check of the dependent component $component");
            }
        }
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(error => "$err");
    }

}


=pod
=begin classdoc

Check the exitance of the attribute givne in parameter.

@param attribute the attribute name to check existance.

=end classdoc
=cut

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

        throw Kanopya::Exception::InvalidConfiguration(error     => $error,
                                                       component => $self);
    }
}


=pod
=begin classdoc

Check the state of component dependency.

@param component the component that we depend on

=end classdoc
=cut

sub checkDependency {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'component' ]);

    my ($state, $uptime) = $args{component}->getState();
    # The state is the node state no "in" seems "up"
    if ($state ne "in") {
        throw Kanopya::Exception::InvalidConfiguration(
                  error     => $args{component}->label . " has to be up (in) to start " .
                               $self->label . " (not $state)",
                  component => $self
              );
    }
}


=pod
=begin classdoc

Assuming that the state of a component is the state of the master node of the component.

=end classdoc
=cut

sub getState {
    my ($self, %args) = @_;

    return $self->getMasterNode->getState();
}


sub getExecToTest {}

sub getNetConf {}


=pod
=begin classdoc

Return the hosts entries required for the component efficiency.
Basically a component require all hosts entries of the nodes on which it is distributed.

Conrete components could override this method to add entries of the hosts
of the components that it depends on.

@return ip address

=end classdoc
=cut

sub getHostsEntries {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { "dependencies" => 0 });

    # Basically return the entries of the hosts where is distributed the component
    my $entries = {};
    for my $node ($self->nodes) {
        my $adminip = $node->adminIp;
        my $system = $node->getComponent(category => "System");
        if (! defined $adminip) {
            $log->warn("Skipping node <" .  $node->label . "> as it has not admin ip.");
            next;
        }
        $entries->{$node->adminIp} = {
            fqdn    => $node->fqdn,
            # Use a hash to store aliases as Hash::Marge module do not merge arrays
            aliases => {
                'hostname.domainname' => $node->node_hostname . "." . $system->domainname,
                'hostname'            => $node->node_hostname,
            },
        }
    }

    if ($args{dependencies}) {
        for my $dependency (@{ $self->getDependentComponents }) {
            $entries = $merge->merge($entries, $dependency->getHostsEntries);
        }
    }
    return $entries;
}


=pod
=begin classdoc

Override in sub classes to return the conrete component dependecencies.

@return the list of dependent components.

=end classdoc
=cut

sub getDependentComponents {
    my ($self, %args) = @_;

    return [];
}


=pod
=begin classdoc

getListenIp gives ip address to use as "bind address" for this component configuration.
Today, Hard coded behaviors are:
component is not loadbalanced : 0.0.0.0
component is loadbalanced : node adminIp

@return ip address

=end classdoc
=cut

sub getListenIp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node', 'port' ]);

    if ($self->getBalancerAddress(port => $args{port})) {
        return $args{node}->adminIp;
    }
    else {
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

    my $keepalived = eval { $self->getMasterNode->getComponent(name => 'Keepalived') };
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

    General::checkParams(args => \%args, required => [ 'node' ]);

    my $manifest = "";
    my $dependencies = [];
    my $listens = { };

    LISTEN:
    for my $listen ($self->haproxy1s_listen) {
        next LISTEN if $self->id != $listen->listen_component_id;    

        $listens->{$listen->listen_name . '-'.$args{node}->node_hostname} = {
            listening_service => $listen->listen_name,
            ports             => $listen->listen_component_port,
            server_names      => $args{node}->node_hostname,
            ipaddresses       => $args{node}->adminIp,
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


=pod
=begin classdoc

Implemented in concrete components classes, this method should qurry
the correponding midelware to register available ressources, options,
exsting infrastructure managed by the component.

=end classdoc
=cut

sub synchronize {
    my ($self, @args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Forbid to access to the service provider from the component.

=end classdoc
=cut

sub service_provider {
    my ($self, @args) = @_;

    # throw Kanopya::Exception::Internal::Deprecated(
    #           error => "Accessing to the service provider from a component is deprecated"
    #       );
    $log->warn("Accessing to the service provider from a component is deprecated");

    if (scalar(@args)) {
        return $self->setAttr(name => 'service_provider', value => pop(@args));
    }
    return $self->SUPER::service_provider;
};

1;
