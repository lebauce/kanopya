
use lib qw(/opt/kanopya/lib/orchestrator/ /opt/kanopya/lib/monitor/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/common);


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init();

use Orchestrator;

my $orchestrator = Orchestrator->new();

my $running = 1;
$orchestrator->run( \$running );
