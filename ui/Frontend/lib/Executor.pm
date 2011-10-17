package Executor;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
my $log = get_logger("webui");

get "/execution" => sub {
    template 'execution', {
        title_page  => 'Dashboard - Operations queue',
        username    => session('username'),
        object      => vars->{adm_object}->getOperations(),
    };
}
