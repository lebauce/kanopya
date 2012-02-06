use ScomQuery;
use Data::Dumper;

my $management_server_name = "WIN-09DSUKS61DT.hedera.forest";

my %counters = (
	'Memory' 	=> ['Available MBytes','PercentMemoryUsed'],
	'Process' 	=> ['% Processor Time'],
	'Processor' => ['% Processor Time'],
);

my $start_time = '2/2/2012 11:00:00 AM';
my $end_time = '2/2/2012 12:00:00 PM';

my $scom = ScomQuery->new( server_name => $management_server_name );

my $res = $scom->getPerformance(
	counters => \%all_counters,
	start_time => $start_time,
	end_time => $end_time,
);

print Dumper $res;
