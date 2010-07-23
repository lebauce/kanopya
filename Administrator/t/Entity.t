use FindBin qw($Bin);
use lib "$Bin/../Lib";
use Data::Dumper;

use Log::Log4perl;;
Log::Log4perl->init("../Conf/log.conf");

use Test::More 'no_plan';
use Administrator;

my $adm = Administrator->new( login =>'tortue', password => 'pass' );

my @users = $adm->getAllObjs(type => 'User');

my @targetgroups = ();


while (my $g = $users[0]->{_groups}->next) {
	my @groups = $adm->{db}->resultset('Entityright')->search(
		{ entityright_consumer_id => $g->get_column('entity_id') },
		
	);
	push @targetgroups, @groups;
	
} 

foreach my $i (@targetgroups) {
	print $i->get_column('entityright_entity_id');
}	



