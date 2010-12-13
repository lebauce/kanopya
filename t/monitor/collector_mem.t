
use lib qw(/opt/kanopya/lib/monitor/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/common);


#use Test::More;
#    eval 'use Test::Valgrind';
#    plan skip_all => 'Test::Valgrind is required to test your distribution with valgrind' if $@;
#    leaky();


    use strict;
    use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
    use Test::More HAS_LEAKTRACE ? (tests => 1) : (skip_all => 'require Test::LeakTrace');
    use Test::LeakTrace;

   # use Log::Log4perl "get_logger";
   # Log::Log4perl->init('/opt/kanopya/conf/log.conf');

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init();

use Monitor::Collector;

my $collector = Monitor::Collector->new();
    leaks_cmp_ok{
        #toto();
		$collector->updateHostData( host_ip => "127.0.0.1", host_state => "up", components => []);
        #$collector->update();
    } '<', 1;



sub toto {
	print "YYYEEAAAHHHH !!!!\n";
    my $t = 2;
    $t = \$t;
}


