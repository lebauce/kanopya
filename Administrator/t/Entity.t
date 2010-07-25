use FindBin qw($Bin);
use lib "$Bin/../Lib";
use Data::Dumper;

use Log::Log4perl;;
Log::Log4perl->init("../Conf/log.conf");

use Test::More 'no_plan';
use Administrator;

my $adm = Administrator->new( login =>'tortue', password => 'pass' );

while(my $g = $adm->{_rightschecker}->{_groups}->next) {
	print $g->groups_name, "\n";
};

my $proctemplate = $adm->getObj(type => 'Processortemplate', id => 19);

print $proctemplate->getAttr(name => 'processor_brand'), "\n";
print $proctemplate->getAttr(name => 'processor_model'), "\n";
print $proctemplate->getAttr(name => 'processor_FSB'), "\n";
print $proctemplate->getAttr(name => 'processor_max_consumption'), "\n";





#is( "test", "test", "test");