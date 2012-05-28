package Netapp;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
use Administrator;
use Entity::ServiceProvider::Outside::Netapp;
use Entity::Connector::NetappVolumeManager;
use Entity::Connector::NetappLunManager;
use EntityComment;

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
        redirect('/equipments/netapp');
    }
};

get '/netapp/:netappid/remove' => sub {
    my $adm = Administrator->new;
    my $netapp_id = param('netappid');
    eval {
        my $enetapp = Entity::ServiceProvider::Outside::Netapp->get(id => $netapp_id);
        $enetapp->delete();
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
    my $netapp = Entity->get(id => $netapp_id);
    my $eenetapp = $netapp->getConnector(category => 'Storage');
    #my $entity_comment = EntityComment->find(hash => { entity_id => $netapp_id });
    
    # Connectors
    my @connectors = map { 
        {
            'connector_id'              => $_->getAttr(name => 'connector_id'),
            'link_configureconnector'   => 1,
            %{$_->getConnectorType()},
        }
    } $netapp->getConnectors();
    
    my @volumes = $eenetapp->volumes;
    my @aggregates = $eenetapp->aggregates;

    template 'netapp_details', {
        netapp_id              => $netapp->getAttr('name' => 'netapp_id'),
        netapp_name            => $netapp->getAttr('name' => 'netapp_name'),
        netapp_desc            => $netapp->getAttr('name' => 'netapp_desc'),
        netapp_addr            => $netapp->getAttr('name' => 'netapp_addr'),
        netapp_login           => $netapp->getAttr('name' => 'netapp_login'),
        netapp_passwd          => $netapp->getAttr('name' => 'netapp_passwd'),
        netapp_state           => $eenetapp->{state},
        connectors_list        => \@connectors,
        #entity_comment         => $entity_comment->getAttr('name' => 'entity_comment'),
        entity_comment         => $netapp->getComment(),
        netapp_volumes         => \@volumes,
        netapp_aggregates      => \@aggregates,
    };
};

get '/netapp/:netappid/synchronize' => sub {
    my $netapp_id = param('netappid');
    my $netapp = Entity::ServiceProvider::Outside::Netapp->get(id => $netapp_id);
    $netapp->synchronize();
    redirect('/equipments/netapp/'.$netapp_id);
};

1;
