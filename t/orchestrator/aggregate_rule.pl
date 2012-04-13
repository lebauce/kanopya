use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use AggregateRule;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

$params = {
    aggregate_rule_formula   => '(not 1) | (not 2)',
    aggregate_rule_state     => 'enabled',
    aggregate_rule_action_id => '1',
};


#my $aggregate_rule = AggregateRule->new(%$params);

for my $aggregate_rule (AggregateRule->search(hash=>{})){
    $aggregate_rule->eval();
}

