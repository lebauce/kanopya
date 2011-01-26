
use lib qw(/opt/kanopya/lib/monitor/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/common);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init();

use Monitor::Grapher;

my $grapher = Monitor::Grapher->new();

my $running = 1;
$grapher->run( \$running );

