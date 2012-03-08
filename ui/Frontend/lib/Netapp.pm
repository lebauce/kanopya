package Netapp;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
use Administrator;
use NetApp::Filer;
use Entity::ServiceProvider::Outside::Netapp;
use Entity::Connector::NetappManager;

my $log = get_logger('webui');

prefix '/equipments';

sub _netapp {
    my @enetapp = Entity::ServiceProvider::Outside::Netapp->getNetapp(hash => {});
    my $netapp_list = [];

    foreach my $netapp (@enetapp) {
        my $tmp = {};

        $tmp->{netapp_id}            = $netapp->getAttr('name' => 'netapp_id');
        $tmp->{netapp_name}          = $netapp->getAttr('name' => 'netapp_name');
        $tmp->{netapp_desc}          = $netapp->getAttr('name' => 'netapp_desc');
        $tmp->{netapp_addr}          = $netapp->getAttr('name' => 'netapp_addr');
        $tmp->{netapp_login}         = $netapp->getAttr('name' => 'netapp_login');
        $tmp->{netapp_passwd}        = $netapp->getAttr('name' => 'netapp_passwd');

        push(@$netapp_list, $tmp);
    }

    return $netapp_list;
}

get '/netapp' => sub {
    my $can_create;

    $can_create = 1;

    template 'netapp', {
        netapp_list => _netapp(),
        can_create => $can_create,
    };
};

get '/netapp/add' => sub {
    template 'form_addnetapp', {}, { layout => '' };
};

post '/netapp/add' => sub {
    my $serviceProvider;
    my $adm = Administrator->new;
    eval {
        $serviceProvider = Entity::ServiceProvider::Outside::Netapp->create(
            netapp_name         => param('name'),
            netapp_desc         => param('desc'),
            netapp_addr         => param('addr'),
            netapp_login        => param('login'),
            netapp_passwd       => param('passwd'),
        );
    };
    if ($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        my $connector = Entity::Connector::NetappManager->new();
        $serviceProvider->addConnector('connector' => $connector);
        redirect('/equipments/netapp');
    }
};

get '/netapp/:netappid/remove' => sub {
    my $adm = Administrator->new;
    my $netapp_id = param('netappid');
    my $enetapp = Entity::ServiceProvider::Outside::Netapp->get(id => $netapp_id);

    eval {
        $enetapp->remove();
    };
    if ($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { redirect '/equipments/netapp'; }
};

get '/netapp/:netappid' => sub {
    my $netapp_id = param('netappid');
    my $enetapp = Entity::ServiceProvider::Outside::Netapp->get(id => $netapp_id);
    my $eenetapp = $enetapp->getConnector(category => 'Storage');
    my @volumes = $eenetapp->volumes;

    template 'netapp_details', {
        netapp_id              => $enetapp->getAttr('name' => 'netapp_id'),
        netapp_name            => $enetapp->getAttr('name' => 'netapp_name'),
        netapp_desc            => $enetapp->getAttr('name' => 'netapp_desc'),
        netapp_addr            => $enetapp->getAttr('name' => 'netapp_addr'),
        netapp_login           => $enetapp->getAttr('name' => 'netapp_login'),
        netapp_passwd          => $enetapp->getAttr('name' => 'netapp_passwd'),
        netapp_state           => $eenetapp->{state},
        netapp_volumes         => \@volumes
    };
};

1;
