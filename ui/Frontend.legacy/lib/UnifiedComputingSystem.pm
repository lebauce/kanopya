package UnifiedComputingSystem;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
use Administrator;
use Cisco::UCS;
use Entity::ServiceProvider::Outside::UnifiedComputingSystem;
use Entity::Connector::UcsManager;

my $log = get_logger('webui');

prefix '/equipments';

sub _ucs {
    my @eucs = Entity::ServiceProvider::Outside::UnifiedComputingSystem->getUcs(hash => {});
    my $ucs_list = [];

    foreach my $ucs (@eucs) {
        my $tmp = {};

        $tmp->{ucs_id}            = $ucs->getAttr('name' => 'ucs_id');
        $tmp->{ucs_name}          = $ucs->getAttr('name' => 'ucs_name');
        $tmp->{ucs_desc}          = $ucs->getAttr('name' => 'ucs_desc');
        $tmp->{ucs_addr}          = $ucs->getAttr('name' => 'ucs_addr');
        $tmp->{ucs_login}         = $ucs->getAttr('name' => 'ucs_login');
        $tmp->{ucs_passwd}        = $ucs->getAttr('name' => 'ucs_passwd');
        $tmp->{ucs_ou}            = $ucs->getAttr('name' => 'ucs_ou');

        push(@$ucs_list, $tmp);
    }

    return $ucs_list;
}

get '/ucs' => sub {
    my $can_create;

    $can_create = 1;

    template 'ucs', {
        ucs_list => _ucs(),
        can_create => $can_create,
    };
};

get '/ucs/add' => sub {
    template 'form_adducs', {}, { layout => '' };
};

post '/ucs/add' => sub {
    my $sp;
    my $adm = Administrator->new;
    eval {
        $sp = Entity::ServiceProvider::Outside::UnifiedComputingSystem->create(
            ucs_name         => param('name'),
            ucs_desc         => param('desc'),
            ucs_addr         => param('addr'),
            ucs_login        => param('login'),
            ucs_passwd       => param('passwd'),
            ucs_ou           => param('ou'),
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
        redirect('/equipments/ucs');
    }
};

get '/ucs/:ucsid/remove' => sub {
    my $adm = Administrator->new;
    my $ucs_id = param('ucsid');
    eval {
        my $eucs = Entity::ServiceProvider::Outside::UnifiedComputingSystem->get(id => $ucs_id);
        $eucs->delete();
    };
    if ($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { redirect '/equipments/ucs'; }
};

get '/ucs/:ucsid' => sub {
    my $ucs_id = param('ucsid');
    my $eucs = Entity::ServiceProvider::Outside::UnifiedComputingSystem->get(id => $ucs_id);
    my $eeucs = $eucs->getConnector(category => 'Cloudmanager');
    my @sps = $eeucs->get_service_profiles();
    my @templates = $eeucs->get_service_profile_templates(
                        dn => $eucs->getAttr('name' => 'ucs_ou')
                    );
    my @blades = $eeucs->get_blades();

    template 'ucs_details', {
        ucs_id              => $eucs->getAttr('name' => 'ucs_id'),
        ucs_name            => $eucs->getAttr('name' => 'ucs_name'),
        ucs_desc            => $eucs->getAttr('name' => 'ucs_desc'),
        ucs_addr            => $eucs->getAttr('name' => 'ucs_addr'),
        ucs_login           => $eucs->getAttr('name' => 'ucs_login'),
        ucs_passwd          => $eucs->getAttr('name' => 'ucs_passwd'),
        ucs_ou              => $eucs->getAttr('name' => 'ucs_ou'),
        ucs_state           => $eeucs->{state},
        ucs_serviceprofiles => \@sps,
        ucs_templates       => \@templates,
        ucs_blades          => \@blades,
        entity_comment      => $eucs->getComment(),
    };
};

get '/ucs/:ucsid/synchronize' => sub {
    my $ucs_id = param('ucsid');
    my $eucs = Entity::ServiceProvider::Outside::UnifiedComputingSystem->get(id => $ucs_id);
    my $eeucs = $eucs->getConnector(category => 'Cloudmanager');
    $eeucs->synchronize();
    redirect('/equipments/ucs/'.$ucs_id);
};

1;