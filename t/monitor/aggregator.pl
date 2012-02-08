use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use Aggregate;
use Aggregator;
use Entity::ServiceProvider::Inside::Cluster;
use Data::Dumper;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

my $aggregator = Aggregator->new();

$aggregator->_create_aggregates_db();
#$aggregator->_update();
#my $host_indicator_for_retriever = $aggregator->_contructRetrieverOutput();
#
#print Dumper $host_indicator_for_retriever;
#
#my $answer_from_retriever = {
#              '56' => {
#                    '1' => 10.5,
#                    '2' => 2.5
#                  },
#              '55' => {
#                    '1' => 3.4,
#                    '2' => 5.2
#                  }
#};
#
#my $aggregates_for_timedb = $aggregator->_computeAggregates(indicators => $answer_from_retriever);
#print Dumper $aggregates_for_timedb;