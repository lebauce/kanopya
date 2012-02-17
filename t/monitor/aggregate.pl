use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use Aggregate;
use AggregateCombination;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

my $aggregate_params = {
    cluster_id               => '54',
    indicator_id             => '16',
    statistics_function_name => 'max',
    window_time              => '1200',
};

my $aggregate = Aggregate->new(%$aggregate_params);


my $aggregate_combination_params = {
    aggregate_combination_formula => 'id'.$aggregate->getAttr(name => 'aggregate_id')
};
my $aggregate = AggregateCombination->new(%$aggregate_combination_params);


#my @table = qw(2.12 4 4 4 5 5 7 9);

#my $calc = $aggregate->calculate(values => \@table);

#print "calc = $calc \n";