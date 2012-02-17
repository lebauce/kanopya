use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use AggregateCondition;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

$params = {
    aggregate_combination_id          => 2,
    comparator            => '<',
    threshold             => 0.6,
    state                 => 'enabled',
    time_limit            => NULL,
};

#my $aggregate_rule = AggregateCondition->new(%$params);

my @aggregate_conditions = AggregateCondition->search(hash => {});
for my $aggregate_condition (@aggregate_conditions){
    #print $aggregate_condition->toString()."\n";
    $aggregate_condition->eval();
}


