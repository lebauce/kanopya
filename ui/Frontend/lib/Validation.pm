package Validation;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Data::Dumper;

use Entity::Operation;

use Log::Log4perl "get_logger";

my $log = get_logger("webui");

prefix '/validation';

get '/operation/:spid/:action' => sub {
    my $operation = params->{spid};
    my $action    = params->{action};

    Entity::Operation->get(id => $operation)->methodCall(method => $action);

    return redirect '/';
};

1;