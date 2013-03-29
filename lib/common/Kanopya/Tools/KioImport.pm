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

my %register_methods = (
    'services' => \&_registerServices,
);

for my $type (keys %register_methods) {
    $register_methods{$type}->(data => $json_imported_items->{$type});
}

sub _registerServices {
    my %args = @_;

    General::checkParams(args => \%args, required => [ "data" ]);
    my $services = $args{data};

    for my $old_service (@$services) {
        my $new_externalcluster = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name       => $old_service->{externalcluster_name},
            externalcluster_desc       => $old_service->{externalcluster_desc},
            externalcluster_state      => $old_service->{externalcluster_state},
            externalcluster_prev_state => $old_service->{externalcluster_prev_state}
        );

        if (defined @{ $old_service->{externalnodes} }) {
            for my $old_externalnode ( @{$old_service->{externalnodes}} ) {
                my $new_node = Node->new(
                    node_hostname       => $old_externalnode->{externalnode_hostname},
                    node_number         => 0,
                    monitoring_state    => $old_externalnode->{externalnode_state},
                    service_provider_id => $new_externalcluster->id
                );
            }
        }
    }
}

1;