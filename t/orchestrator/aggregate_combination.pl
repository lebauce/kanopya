use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use AggregateCombination;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

$params = {
    aggregate_combination_formula   => 'id1 + id2',
};
my $aggregate_combination = AggregateCombination->new(%$params);

for my $aggregate_combination (AggregateCombination->search(hash=>{})){
    #my $res = $aggregate_combination->calculate();
    print $aggregate_combination->toString();
}

