package Services;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Administrator;
use General;
use ServiceTemplate;

use Log::Log4perl "get_logger";
use Data::Dumper;


my $log = get_logger("webui");

prefix '/architectures';

sub _services {
    my @services = ServiceTemplate->search(hash => {});
    my $service_list = [];

    foreach my $service (@services){
        my $data = {
            route_base   => 'services',
            service_id   => $service->getAttr(name => 'service_template_id'),
            service_name => $service->getAttr(name => 'service_name'),
            service_desc => $service->getAttr(name=>'service_desc')
        };

        push (@$service_list, $data);
    }
    return $service_list;
}

# Services list display

get '/services' => sub {
    template 'services', {
        title_page    => 'Architectures - Services',
        services_list => [ @{ _services() } ],
    }, { layout => 'main' };
};


1;
