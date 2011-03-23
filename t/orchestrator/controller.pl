use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init();

use Controller;


my $controller = Controller->new();

$controller->update();

