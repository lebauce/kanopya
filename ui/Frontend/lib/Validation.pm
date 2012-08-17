package Validation;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Data::Dumper;

use Administrator;
use Operation;

use Log::Log4perl "get_logger";

my $log = get_logger("webui");

prefix '/validation';

get '/operation/:spid/:action' => sub {
    my $operation = params->{spid};
    my $action    = params->{action};

    Operation->get(id => $operation)->$action();
    return redirect '/';
};

1;