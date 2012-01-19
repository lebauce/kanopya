
use lib qw(/opt/kanopya/lib/orchestrator/ /opt/kanopya/lib/monitor/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/common);


#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init();
use Log::Log4perl "get_logger";
Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');

use Controller;

my $controller = Controller->new();

my $running = 1;
$controller->run( \$running );
