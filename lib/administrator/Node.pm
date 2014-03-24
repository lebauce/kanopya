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

package Node;
use base 'BaseDB';

use strict;
use warnings;

use ComponentNode;
use Entity::Indicator;
use Entity::Rule::NodemetricRule;

use TryCatch;

use Log::Log4perl 'get_logger';
my $log = get_logger("");

use constant ATTR_DEF => {
    service_provider_id => {
        pattern      => '^.*$',
        is_delegatee => 1,
        is_mandatory => 1,
    },
    host_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    node_hostname => {
        label        => 'Hostname',
        type         => 'string',
        pattern      => '^[\w\d\-\.]*$',
        is_mandatory => 0,
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

@constructor

Create a new Node.

=end classdoc
=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );

    $self->_undefRules();

    return $self;
}


=pod
=begin classdoc

A component to the Node instance

@optional component_types

=end classdoc
=cut

sub update {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'component_types' => undef });

    if (defined $args{component_types}) {
        my $component_types = delete $args{component_types};
        $self->service_provider->addComponents(
            nodes           => [ $self->id ],
            component_types => $component_types
        );
    }
}


=pod
=begin classdoc

Returns components linked to the Node instance.

@optional component_types

=end classdoc
=cut

sub getComponent {
    my ($self, %args) = @_;

    return $self->service_provider->getComponent(node => $self, %args);
}

sub rulestate {
    my $self = shift;
    my %args = @_;

    return grep { $_->verified_noderule_state eq "verified" } $self->verified_noderules;
}


=pod
=begin classdoc

Initialize all nodemetric rules related to the Node instance to undef.

@optional component_types

=end classdoc
=cut

sub _undefRules {
    my $self = shift;

    # my @nm_rules = $self->service_provider->nodemetric_rules;
    # TODO try to allow a direct relation

    my @nm_rules = Entity::Rule::NodemetricRule->search(hash => {service_provider_id => $self->service_provider_id});

    foreach my $nm_rule (@nm_rules) {
        try {
            VerifiedNoderule->new(
                verified_noderule_node_id            => $self->id,
                verified_noderule_state              => 'undef',
                verified_noderule_nodemetric_rule_id => $nm_rule->id,
            );
        }
        catch(Kanopya::Exception::DB::DuplicateEntry $err) {
            my $msg = 'Nodemetric rules <'.$nm_rule->id
                      .'> is already undef for node <'.$self->id.'>';
            $log->debug($msg);
        }
    }
}


=pod
=begin classdoc

Disable a Node instance by managing its state and its linked rules.

=end classdoc
=cut

sub disable {
    my $self = shift;

    my @verified_noderules = $self->verified_noderules;
    while(@verified_noderules) {
        (pop @verified_noderules)->delete();
    }
    $self->monitoring_state('disabled');
}


=pod
=begin classdoc

Enable a Node instance by managing its state and its linked rules.

=end classdoc
=cut

sub enable {
    my $self = shift;

    $self->_undefRules();
    $self->monitoring_state('enabled');
}


=pod
=begin classdoc

Retrieve monitoring data of a list of indicator given by their ids.

@param indicator_ids array ref of indicator ids

@return hash ref {indicator oid => indicator value}

=end classdoc
=cut

sub getMonitoringData {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'indicator_ids' ]);

    my $manager = $self->service_provider->getManager(manager_type => 'CollectorManager');

    # Construst indicators params as expected by CollectorManager
    my %indicators;
    for my $indic_id (@{$args{indicator_ids}}) {
        $indicators{$indic_id} = Entity::Indicator->get(id => $indic_id);
    }
    delete $args{indicator_ids};

    my $data = $manager->retrieveData(
        nodelist    => [ $self->node_hostname ],
        indicators  => \%indicators,
        %args
    );

    return $data->{$self->node_hostname} || {};
}


=pod
=begin classdoc

Remove node Instance by launching a 'StopNode' Workflow.

@optional dryrun do not remove the node if defined

=end classdoc
=cut

sub remove {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'dryrun' => undef });

    if (not defined $args{dryrun}) {
        $self->service_provider->removeNode('node_id' => $self->id);
    }

    my $manager;
    eval {
        $manager = $self->service_provider->getManager(manager_type => 'CollectorManager');
    };

    if (defined $manager) {
        my @collector_indicators = $manager->collector_indicators;

        for my $collector_indicator (@collector_indicators) {
            my $indicator = $collector_indicator->indicator;
            my $rrd_name = $indicator->id.'_'.$self->node_hostname;
            $log->info('delete '.$rrd_name);
            TimeData::RRDTimeData::deleteTimeDataStore(name => $rrd_name);
        }
    }
    return;
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

    return $self->node_hostname . '.' . $self->service_provider->cluster_domainname;
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
        $puppetagent = $self->service_provider->getComponent(name => "Puppetagent");
    };
    if ($@) {
        return { };
    }

    return $puppetagent->getPuppetDefinitions(node => $self);
}

1;
