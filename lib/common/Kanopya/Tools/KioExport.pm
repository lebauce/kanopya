=pod

=begin classdoc

Subroutines to upgrade KIO 

@since 2013-March-26

=end classdoc

=cut


package Kanopya::Tools::KioExport;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use Kanopya::Exceptions;
use Administrator;
use Entity::Connector;
use ConnectorType;
use ServiceProviderManager;
use Externalnode;
use Entity::Combination::AggregateCombination;
use Entity::AggregateCondition;
use Entity::AggregateRule;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Clustermetric;
use Entity::CollectorIndicator;
use Entity::Combination;
use Entity::Combination::ConstantCombination;
use Dashboard;
use Entity::Host;
use Entity::Indicator;
use Externalnode::Node;
use Entity::Combination::NodemetricCombination;
use Entity::NodemetricCondition;
use Entity::NodemetricRule;
use ParamPreset;
use Entity::User;
use UserProfile;
use VerifiedNoderule;
use WorkflowDef;
use Entity::ServiceProvider::Outside::Externalcluster;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );

my $export_dir = '/vagrant/';
my $export_bdd_file = $export_dir . 'bdd.json';
my $export_data;
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

mkdir $export_dir unless (-d $export_dir);



for my $type (@types) {
    $export_data->{$type} = _exportDataToJson(data_type => $type);
}
_writeJsonFile(data => $export_data);

sub _exportDataToJson {
    my %args = @_;

    General::checkParams(args => \%args, required => [ "data_type" ]);

    my $data_matrix = {
        services                => 'Entity::ServiceProvider::Outside::Externalcluster',
        connectors              => 'Entity::Connector',
        connector_types         => 'ConnectorType',
        managers                => 'ServiceProviderManager',
        externalnodes           => 'Externalnode',
        aggregate_combinations  => 'Entity::Combination::AggregateCombination',
        aggregate_conditions    => 'Entity::AggregateCondition',
        aggregate_rules         => 'Entity::AggregateRule',
        clustermetrics          => 'Entity::Clustermetric',
        collector_indicators    => 'Entity::CollectorIndicator',
        combinations            => 'Entity::Combination',
        constant_combinations   => 'Entity::Combination::ConstantCombination',
        dashboards              => 'Dashboard',
        indicators              => 'Entity::Indicator',
        nodemetric_combinations => 'Entity::Combination::NodemetricCombination',
        nodemetric_conditions   => 'Entity::NodemetricCondition',
        nodemetric_rules        => 'Entity::NodemetricRule',
        param_presets           => 'ParamPreset',
        verified_noderules      => 'VerifiedNoderule',
        workflow_defs           => 'WorkflowDef',

    };

$DB::single = 1;
    my @items = $data_matrix->{ $args{data_type} }->search(hash => {});

    my @exported_items;
    foreach my $item (@items) {
        push @exported_items, $item->toJSON;
    }
    
    return \@exported_items;
}

sub _writeJsonFile {
    my %args = @_;

    General::checkParams(args => \%args, required => [ "data" ]);

    my $json_exported_items = JSON->new->utf8->encode($args{data});

    open (my $FILE, '>>', $export_bdd_file) or die 'could not open \'$export_bdd_file\' : $!\n';
    print $FILE $json_exported_items; 
    close($FILE);
}

1;
