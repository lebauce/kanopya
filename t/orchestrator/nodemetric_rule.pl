use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Administrator;
use General;
use NodemetricRule;
use NodemetricCombination;
use NodemetricCondition;
use Data::Dumper;
use strict;
use warnings;


#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

my $pcombination = {
    nodemetric_combination_formula => ' id15 + id16',
};

my $comb = NodemetricCombination->new(%$pcombination);


my $pcondition = {
    nodemetric_condition_combination_id => $comb->getAttr(name=>'nodemetric_combination_id'),
    nodemetric_condition_comparator     => ">",
    nodemetric_condition_threshold      => 666,
};


my $condition = NodemetricCondition->new(%$pcondition);


my $conditionid = $condition->getAttr(name => 'nodemetric_condition_id');
my $prule = {
    nodemetric_rule_formula             => 'id'.$conditionid,
    nodemetric_rule_state               => 'enabled',
    nodemetric_rule_action_id           => '1',
    nodemetric_rule_service_provider_id => 57,
};


my $rule = NodemetricRule->new(%$prule);

