use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use Aggregate;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

$params = {
    cluster_id               => '1',
    indicator_id             => '1',
    statistics_function_name => 'standard_deviation',
    window_time              => '0',
};

my $aggregate = Aggregate->new(%$params);

my @table = qw(2 4 4 4 5 5 7 9);

my $mean = $aggregate->calculate(values => \@table);

print "$mean \n";