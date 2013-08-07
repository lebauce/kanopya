package REST::Documentation;

use Dancer ':syntax';
use Dancer::Plugin::FormValidator;
use Dancer::Plugin::EscapeHTML;

use Log::Log4perl "get_logger";

use REST::api;

my $log = get_logger("");

get '/doc' => sub {
    redirect '/doc/api/general';
};

get '/doc/api' => sub {
    redirect '/doc/api/general';
};

get '/doc/api/general' => sub {
    template 'API/general',
             {
                version   => $REST::api::API_VERSION,
             },
             {layout => 'api_doc'};
};

get '/doc/api/resources' => sub {
    my @resources = sort keys %REST::api::resources;

    template 'API/resources',
             {
                version   => $REST::api::API_VERSION,
                resources => \@resources
             },
             {layout => 'api_doc'};
};

get '/doc/api/resources/:resource' => sub {
    my $class = REST::api::classFromResource(resource => params->{resource});

    require (General::getLocFromClass(entityclass => $class));

    template 'API/resource',
             {
                resource_name => params->{resource},
                resource_info => $class->toJSON(model => 1)
             },
             {layout => ''};
};

1;
