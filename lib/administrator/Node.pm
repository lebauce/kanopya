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

package Node;
use base 'BaseDB';

use strict;
use warnings;

use ComponentNode;
use Entity::Indicator;
use Entity::Rule::NodemetricRule;

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


sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );

    $self->_undefRules();

    return $self;
}

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

sub getComponent {
    my ($self, %args) = @_;

    return $self->service_provider->getComponent(node => $self, %args);
}

sub rulestate {
    my $self = shift;
    my %args = @_;

    return grep { $_->verified_noderule_state eq "verified" } $self->verified_noderules;
}

sub _undefRules {
    my $self = shift;

    # my @nm_rules = $self->service_provider->nodemetric_rules;
    # TODO try to allow a direct relation

    my @nm_rules = Entity::Rule::NodemetricRule->search(hash => {service_provider_id => $self->service_provider_id});

    foreach my $nm_rule (@nm_rules) {
        VerifiedNoderule->new(
            verified_noderule_node_id            => $self->id,
            verified_noderule_state              => 'undef',
            verified_noderule_nodemetric_rule_id => $nm_rule->id,
        );
    }
}

sub disable {
    my $self = shift;

    my @verified_noderules = $self->verified_noderules;
    while(@verified_noderules) {
        (pop @verified_noderules)->delete();
    }
    $self->monitoring_state('disabled');
}

sub enable {
    my $self = shift;

    $self->_undefRules();
    $self->monitoring_state('enabled');
}

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

sub remove {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'dryrun' => undef });

    if (not defined $args{dryrun}) {
        $self->service_provider->removeNode('node_id' => $self->id);
    }
    return;
}

sub adminIp {
    my $self = shift;

    return $self->host->adminIp;
}

sub fqdn {
    my $self = shift;

    return $self->node_hostname . '.' . $self->service_provider->cluster_domainname;
}

sub getMasterComponents {
    my $self = shift;

    my @masters = $self->searchRelated(filters => ['component_nodes'], hash => { master_node => 1 });
    return @masters;
}

1;
