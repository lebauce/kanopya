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
mkdir $export_dir unless (-d $export_dir);

my $export_data;
my $matrix = {
    services     => {
        ref       => 'Entity::ServiceProvider::Outside::Externalcluster',
        relations => [ 
            'connectors', 
            'externalnodes', 
            'service_provider_managers',  
            'combinations',
            'nodemetric_rules',
            'nodemetric_conditions',
            'clustermetrics',
            'aggregate_rules',
            'aggregate_conditions',
            'combinations',
        ],
    },
    dashboard    => {
        ref       => 'Dashboard',
        relations => [],
    },
    param_preset => {
        ref       => 'ParamPreset',
        relations => [],
    },
    workflow_def => {
        ref       => 'WorkflowDef',
        relations => [],
    },
    indicator   => {
        ref       => 'Entity::Indicator',
        relations => [],
    }
};

while (my ($resource,$details) = each %$matrix) {

    my @objects = $details->{ref}->search(hash => {});
    my @objects_rdy_to_export;

    foreach my $object (@objects) {
        my $tojson_object = $object->toJSON;

        foreach my $relation ( @{ $details->{relations} } ) {
#            print "DEBUG RELATION = $relation \n";

            if ($object->$relation > 0) {
                my @tojson_relation;
                foreach my $obj_relation ($object->$relation) {
                    my $tojson_obj_relation = $obj_relation->toJSON;

                    #hardcode stuff to insert collector_indicators and indicators
                    if (ref $obj_relation eq 'Entity::Connector::Scom') {
                        my @collector_indicators = Entity::CollectorIndicator->search(hash => {});
                        my @tojson_collector_indicators;
                        foreach my $collector_indicator (@collector_indicators) {
                            push @tojson_collector_indicators, $collector_indicator->toJSON;
                        }
                        $tojson_obj_relation->{collector_indicators} = \@tojson_collector_indicators;
                    }

                    push @tojson_relation, $tojson_obj_relation;
                }
                $tojson_object->{$relation} = \@tojson_relation;
            }
        }
        push @objects_rdy_to_export, $tojson_object;
    }

    $export_data->{$resource} = \@objects_rdy_to_export;
}



_writeJsonFile(data =>$export_data);

sub _writeJsonFile {
    my %args = @_;
   
    General::checkParams(args => \%args, required => [ "data" ]);
   
    my $json_exported_items = JSON->new->utf8->encode($args{data});
    
    open (my $FILE, '>>', $export_bdd_file) or die 'could not open \'$export_bdd_file\' : $!\n';
    print $FILE $json_exported_items; 
    close($FILE);
}

1;
