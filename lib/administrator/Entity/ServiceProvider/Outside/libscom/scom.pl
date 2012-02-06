use ScomQuery;
use Data::Dumper;

my %counters = (
	'Memory' 	=> ['Available MBytes','PercentMemoryUsed'],
	'Process' 	=> ['% Processor Time'],
	'Processor' => ['% Processor Time'],
);

%all_counters = ( '*' => ['*']);

my $start_time = '1/18/2012 11:00:00 AM';
my $end_time = '1/18/2012 12:00:00 PM';

my $scom = ScomQuery->new( server_name => "WIN-U54NH1H3IRB.scom.com" );

my $res = $scom->getPerformance(
	counters => \%all_counters,
	start_time => $start_time,
	end_time => $end_time,
);

print Dumper $res;
