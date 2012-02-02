use lib qw(/opt/kanopya/lib/monitor/);
use Administrator;
use General;
use Entity::Cluster;
use Aggregate;


my $cluster = {
    name => 'cluster',
};
print "$cluster->{name}\n";
                 
my $func = 'Mean';
                 
my $aggregate = Aggregate->new(
                cluster                              => $cluster,
                indicator                            => 'mem',
                descriptive_statistics_function_name => 'Mean',
                window_time                          => '60',
            );

my $aggregate2 = Aggregate->new(
                cluster                              => $cluster,
                indicator                            => 'mem',
                descriptive_statistics_function_name => 'StandardDeviation',
                window_time                          => '60',
            );
            
my $cluster2 = $aggregate->getCluster();

my @table = qw(2 4 4 4 5 5 7 9);

my $mean = $aggregate->callDescriptiveStatisticsFunction(values => \@table);
my $std = $aggregate2->callDescriptiveStatisticsFunction(values => \@table);


print "$cluster2->{name} $mean $std\n";