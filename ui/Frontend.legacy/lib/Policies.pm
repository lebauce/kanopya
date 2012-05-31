package Policies;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Administrator;
use General;
use ServiceTemplate;
use Policy;

use Log::Log4perl "get_logger";
use Data::Dumper;


my $log = get_logger("webui");

prefix '/architectures';

sub _policies {
    my @policies = Policy->search(hash => {});
    my $policy_list = [];

    foreach my $policy (@policies){
        my $data = {
            route_base  => 'policies',
            policy_id   => $policy->getAttr(name => 'policy_id'),
            policy_name => $policy->getAttr(name => 'policy_name'),
            policy_desc => $policy->getAttr(name => 'policy_desc')
        };

        push (@$policy_list, $data);
    }
    return $policy_list;
}

# Services list display

get '/policies' => sub {
    template 'policies', {
        title_page    => 'Architectures - Services',
        policies_list => [ @{ _policies() } ],
    }, { layout => 'main' };
};


1;
