
use lib qw(/opt/kanopya/lib/monitor/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/common);


#use Test::More;
#    eval 'use Test::Valgrind';
#    plan skip_all => 'Test::Valgrind is required to test your distribution with valgrind' if $@;
#    leaky();










    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init();

use Monitor::Collector;

my $collector = Monitor::Collector->new();

        #toto();
		$collector->updateHostData( host_ip => "127.0.0.1", host_state => "up", components => []);
        #$collector->update();



# This sub result in a memory leak (for testing)
sub memLeak {
	print "Entering sub\n";
    my $t = 2;
    $t = \$t;
}


