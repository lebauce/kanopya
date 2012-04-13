use lib qw(/opt/kanopya/lib/monitor/);
use DescriptiveStatisticsFunction::Mean;
use General;

use DescriptiveStatisticsFunction::StandardDeviation;

my @table = (0, 1, 12);

print "Call Mean calculate()\n";

my $mean = DescriptiveStatisticsFunction::Mean->calculate('values' => \@table);

print "table = @table ; mean = $mean\n";

