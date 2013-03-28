=pod

=begin classdoc

Subroutines to upgrade KIO 

@since 2013-March-26

=end classdoc

=cut


package Kanopya::Tools::KioImport;

use strict;
use warnings;

use Data::Dumper;
use General;
use JSON;
use Kanopya::Exceptions;
use BaseDB;
use Entity::Component;
use Node;
use Entity::Rule::AggregateRule;
use ServiceProviderManager;
use Entity::Combination::AggregateCombination;
use Entity::AggregateCondition;
use Entity::ServiceProvider::Cluster;
use Entity::Clustermetric;
use Entity::CollectorIndicator;
use Entity::Combination;
use Entity::Combination::ConstantCombination;
use Dashboard;
use Entity::Host;
use Entity::Indicator;
use Entity::Combination::NodemetricCombination;
use Entity::NodemetricCondition;
use Entity::Rule::NodemetricRule;
use ParamPreset;
use Entity::User;
use UserProfile;
use VerifiedNoderule;
use Entity::WorkflowDef;
use Entity::ServiceProvider::Externalcluster;

BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

my $export_dir = '/vagrant/';
my $export_bdd_file = $export_dir . 'bdd.json';

open (my $FILE, '<', $export_bdd_file) or die 'could not open \'$export_bdd_file\' : $!\n';
my $import;
while (my $line  = <$FILE>) {
    $import .= $line;
}

my $json_imported_items = JSON->new->utf8->decode($import);

my @types = (
    'services',
    'connectors',
    'connector_types',
    'managers',
    'externalnodes',
    'aggregate_combinations',
    'aggregate_conditions',
    'aggregate_rules',
    'clustermetrics',
    'collector_indicators',
    'combinations',
    'constant_combinations',
    'dashboards',
    'indicators',
    'nodemetric_combinations',
    'nodemetric_conditions',
    'nodemetric_rules',
    'param_presets',
    'verified_noderules',
    'workflow_defs',
);

for my $type (@types) {
    my $function = '_register_' . $type;

    $function->(data => $json_imported_items->{$type});
}

sub _register_services {
    my %args = @_;

    General::checkParams(args => \%args, required => [ "data" ]);

    my @services = @{ $args{data} };

    foreach my $service (@services) {
        Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name       => $service->{externalcluster_name},
            externalcluster_desc       => $service->{externalcluster_desc},
            externalcluster_state      => $service->{externalcluster_state},
            externalcluster_prev_state => $service->{externalcluster_prev_state},
        );
    }
}

1;
