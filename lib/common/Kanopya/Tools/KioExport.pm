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
use Kanopya::Config;
use Indicatorset;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );


my ($export_dir, $rrd_backup_dir, $rrd_dir);
my $cp_dir;
if ($^O eq 'MSWin32') {
    $export_dir     = 'C:\\tmp\\';
    $rrd_backup_dir = 'C:\\tmp\\monitor\\TimeData_old\\';
    $rrd_dir        = 'C:\\tmp\\monitor\\TimeData\\';
    $cp_dir         = 'cp -recurse';
}
elsif ($^O eq 'linux') {
    $export_dir     = '/vagrant/';
    $rrd_backup_dir = '/var/cache/kanopya/monitor_old/';
    $rrd_dir        = '/var/cache/kanopya/monitor/';
    $cp_dir         = 'cp -R';
}

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
        ],
    },
};

# backup monitoring data (folder to copy on machine to be restored)
`$cp_dir $rrd_dir $rrd_backup_dir`;

# save indicators created by user
my @user_indicators = Entity::Indicator->search(hash => {indicator_color => undef});
foreach my $user_indicator (@user_indicators) {
    my $tojson_user_indicator = $user_indicator->toJSON;
    $tojson_user_indicator->{indicatorset_name} = Indicatorset->find(
        hash => {
            indicatorset_id => $user_indicator->indicatorset_id
        }
    )->indicatorset_name;
    $export_data->{'user_indicators'}->{$user_indicator->indicator_id} = $tojson_user_indicator;
}

# save kanopya configuration
my $config = Kanopya::Config::get();
$export_data->{configuration} = $config;

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

                    #hardcode stuff to insert connector_type
                    if (ref ($obj_relation) =~ /Entity::Connector/) {
                        my $type = ConnectorType->find(hash => {
                            connector_type_id => $obj_relation->connector_type->id
                        });
                        $tojson_obj_relation->{connector_type} = $type->connector_name;
                    }

                    #hardcode stuff to insert collector_indicators and indicators
                    if (ref $obj_relation eq 'Entity::Connector::Scom') {
                        my @collector_indicators = Entity::CollectorIndicator->search(hash => {});
                        my @tojson_collector_indicators;
                        foreach my $collector_indicator (@collector_indicators) {
                            my $tojson_collector_indicator = $collector_indicator->toJSON;
                            $tojson_collector_indicator->{indicator_name} =
                                Entity::Indicator->find(
                                    hash => {
                                        indicator_id => $collector_indicator->indicator_id
                                    }
                                )->indicator_name;
                            push @tojson_collector_indicators, $tojson_collector_indicator;

                        }
                        $tojson_obj_relation->{collector_indicators} = \@tojson_collector_indicators;
                    }

                    #hardcode stuff to gather manager parameters from param_presets
                    if (ref $obj_relation eq 'ServiceProviderManager') {
                        $tojson_obj_relation->{manager_params} = $obj_relation->getParams();
                        my $origin_service_id = Entity::Connector->find( hash => {
                                                    connector_id => $obj_relation->manager_id
                                                })->service_provider_id;
                        $tojson_obj_relation->{origin_service_id} = $origin_service_id;
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

    open (my $FILE, '>', $export_bdd_file) or die 'could not open \'$export_bdd_file\' : $!\n';
    print $FILE $json_exported_items;
    close($FILE);
}

1;
