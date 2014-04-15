# Copyright © 2011-2013 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

A Node is a started host. It might refers to a started physical computer or a started virtual machine.

=end classdoc
=cut

package Entity::Node;
use base Entity;

use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Entity::Indicator;

use TryCatch;

use Log::Log4perl 'get_logger';
my $log = get_logger("");

use constant ATTR_DEF => {
    host_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    node_hostname => {
        label        => 'Hostname',
        type         => 'string',
        pattern      => '^[\w\d\-\.]*$',
        is_mandatory => 1,
    },
    node_number => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    systemimage_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    node_state => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    node_prev_state => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    monitoring_state => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    rulestate       => {
        is_virtual   => 1
    },
    puppet_manifest => {
        is_virtual   => 1,
        on_demand    => 1
    },
    components => {
        label        => 'Components',
        type         => 'enum',
        relation     => 'multi',
        link_to      => 'component',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods { return {}; }


=pod
=begin classdoc

Find a component with name or version on the node.

@optional name search components by name
@optional version search components by version
@optional category search components by category

=end classdoc
=cut

sub getComponent {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         optional => { 'name' => undef, 'version' => undef, 'category' => undef });

    # Build the search pattern from args
    my $searchpattern = { hash => {} };
    if (defined $args{name}) {
        $searchpattern->{hash}->{'component_type.component_name'} = $args{name};
        if (defined $args{version}) {
            $searchpattern->{hash}->{'component_type.component_version'} = $args{version};
        }
    }
    elsif (defined $args{category}) {
        $searchpattern->{custom}->{category} = $args{category};
    }
    else {
        throw Kanopya::Exception::Internal::MissingParam(
                  error => "You must specify <name> or <version> parameter."
              )
    }
    return $self->find(related => 'components', %{ $searchpattern });
}


sub getState {
    my $self = shift;
    my $state = $self->node_state;
    return wantarray ? split(/:/, $state) : $state;
}


sub getPrevState {
    my $self = shift;
    my $state = $self->node_prev_state;
    return wantarray ? split(/:/, $state) : $state;
}


sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'state' ]);

    my $new_state = $args{state};
    my $current_state = $self->getState();

    $self->node_prev_state($current_state || "");
    $self->node_state($new_state . ":" . time);
}


sub rulestate {
    my $self = shift;
    my %args = @_;

    return grep { $_->verified_noderule_state eq "verified" } $self->verified_noderules;
}


=pod
=begin classdoc

Disable a Node instance

=end classdoc
=cut

sub disable {
    my $self = shift;

    $self->monitoring_state('disabled');
}


=pod
=begin classdoc

Enable a Node instance

=end classdoc
=cut

sub enable {
    my $self = shift;

    $self->monitoring_state('enabled');
}


=pod
=begin classdoc

Returns Node instance admin ip.

@return admin ip

=end classdoc
=cut

sub adminIp {
    my $self = shift;

    return (defined $self->host_id) ? $self->host->adminIp : undef;
}


=pod
=begin classdoc

Concat Node hostname to node domain in order to get fqdn.

@return String fqdn

=end classdoc
=cut

sub fqdn {
    my $self = shift;

    try {
        return $self->node_hostname . '.' . $self->getComponent(category => "System")->domainname;
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        throw Kanopya::Exception::Internal::NotFound(
                 error => "No \"System\" component found on node <" . $self->label .
                          ">, required to build the fqdn of the node."
              );
    }
    catch ($err) {
        $err->rethrow();
    }
}

=pod
=begin classdoc

Return array of linked ComponentNode instances which are master nodes.

@return array of linked ComponentNode instances which are master nodes.

=end classdoc
=cut

sub getMasterComponents {
    my $self = shift;

    my @masters = $self->searchRelated(filters => ['component_nodes'], hash => { master_node => 1 });
    return @masters;
}

=pod
=begin classdoc

Return the Puppet definitions for the node

@return hash with a 'classes' key and the classes arguments to be fetched by Puppet

=end classdoc
=cut

sub puppetManifest {
    my $self = shift;

    my $puppetagent;
    eval {
        $puppetagent = $self->getComponent(name => "Puppetagent");
    };
    if ($@) {
        return { };
    }

    return $puppetagent->getPuppetDefinitions(node => $self);
}


=pod
=begin classdoc

Browse the node components to find any loadbalanced one

=end classdoc
=cut

sub isLoadBalanced {
    my $self = shift;

    # Search for a potential 'loadbalanced' component
    my $is_loadbalanced = 0;
    foreach my $component ($self->components) {
        my $clusterization_type = $component->getClusterizationType();
        if ($clusterization_type && ($clusterization_type eq 'loadbalanced')) {
            $is_loadbalanced = 1;
            last;
        }
    }
    return $is_loadbalanced;
}


=pod
=begin classdoc

Use the hostname as label.

=end classdoc
=cut

sub _labelAttr { return 'node_hostname'; }


=pod
=begin classdoc

Forbid to access to the service provider from the node.

=end classdoc
=cut

sub service_provider {
    my ($self, @args) = @_;

    # throw Kanopya::Exception::Internal::Deprecated(
    #           error => "Accessing to the service provider from a node is deprecated"
    #       );
    if (scalar(@args)) {
        return $self->setAttr(name => 'service_provider', value => pop(@args));
    }
    return $self->getAttr(name => 'service_provider');
}

1;
