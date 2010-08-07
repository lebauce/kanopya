use FindBin qw($Bin);
use lib "$Bin/../Lib", "$Bin/../../Common/Lib";
use Data::Dumper;

use Log::Log4perl;;
Log::Log4perl->init("$Bin/../Conf/log.conf");

use Test::More 'no_plan';
use Administrator;

my $adm = Administrator->new( login =>'tortue', password => 'pass' );

my @users = $adm->getEntities(type => 'User');

my @targetgroups = ();


print $proctemplate->getAttr(name => 'processor_brand'), "\n";
print $proctemplate->getAttr(name => 'processor_model'), "\n";
print $proctemplate->getAttr(name => 'processor_FSB'), "\n";
print $proctemplate->getAttr(name => 'processor_max_consumption'), "\n";

while (my $g = $users[0]->{_groups}->next) {
	my @groups = $adm->{db}->resultset('Entityright')->search(
		{ entityright_consumer_id => $g->get_column('entity_id') },
		
	);
	push @targetgroups, @groups;
	
} 

foreach my $i (@targetgroups) {
	print $i->get_column('entityright_entity_id');
}	



