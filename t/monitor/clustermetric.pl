use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use ClusterMetric;
use AggregateCombination

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

my $cm_params = {
    clustermetric_cluster_id               => '54',
    clustermetric_indicator_id             => '15',
    clustermetric_statistics_function_name => 'min',
    clustermetric_window_time              => '1200',
};

my $cm = ClusterMetric->new(%$cm_params);

#Create combination with identity

$params = {
    aggregate_combination_formula   => 'id'.($cm->getAttr(name => 'clustermetric_id'))
};
my $aggregate_combination = AggregateCombination->new(%$params);


print (ClusterMetric->get('id'=>1)->toString())."\n";

my @table = qw(2.12 4 4 4 5 5 7 9);
my $calc = $cm->calculate(values => \@table);
print "calc = $calc \n";
