package Components;

use Dancer ':syntax';

use Entity::Component;
use Entity::Cluster;
use Operation;

use Log::Log4perl "get_logger";

my $log = get_logger("webui");

get '/components' => sub {
    my $components = Entity::Component->getComponentsByCategory();
    template 'components', {
        title_page       => 'Systems - Components',
        eid              => session('EID'),
        components_list  => $components,
        object           => vars->{adm_object}
    };
};

