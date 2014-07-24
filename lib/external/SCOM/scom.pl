# SSCOM Query sample/test script
#
# Must be adapted according to the deployed SCOM (server name, counters, start and end time)

use SCOM::Query;
use Data::Dumper;

my $management_server_name = "SCOM.hedera.tech.corp";

my %counters = (
    'Memory'    => ['Available MBytes','PercentMemoryUsed'],
    'Process'   => ['% Processor Time'],
    'Processor' => ['% Processor Time'],
);

my $start_time = '16/6/2012 11:00:00 AM';
my $end_time = '16/6/2012 12:00:00 PM';

my $scom = SCOM::Query->new( server_name => $management_server_name );

print "# Test simple scom request\n";

my $res = $scom->getPerformance(
    counters            => \%counters,
    start_time          => $start_time,
    end_time            => $end_time,
    monitoring_object   => [$management_server_name]
);

print Dumper $res;

print "# Test huge scom request (needs to be splitted)\n";

my @monit_objects = ();
for (1..1000) {
    push @monit_objects, $management_server_name;
}

$res = $scom->getPerformance(
    counters            => \%counters,
    start_time          => $start_time,
    end_time            => $end_time,
    monitoring_object   => \@monit_objects
);

print Dumper $res;
