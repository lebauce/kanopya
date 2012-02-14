use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use AggregateRule;

use Orchestrator;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

$params = {
    rule_id               => 3,
    aggregate_id          => 1,
    comparator            => '<',
    threshold             => 0.1,
    state                 => 'enabled',
    time_limit            => NULL,
};

#my $aggregate_rule = AggregateRule->new(%$params);

my @aggregate_rules = AggregateRule->search(hash => {});
for my $aggregate_rule (@aggregate_rules){
    print $aggregate_rule->toString()."\n";
    $aggregate_rule->eval();
}


