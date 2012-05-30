package Poolip;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
use Administrator;
use Entity::Poolip;
use Data::Dumper;

my $log = get_logger('webui');

prefix '/networks';

sub _poolip {

    my @epoolip = Entity::Poolip->getPoolip(hash => {});
    my $poolip_list = [];

    foreach my $poolip (@epoolip) {
        my $tmp = {};

        $tmp->{poolip_id}       = $poolip->getAttr('name' => 'poolip_id');
        $tmp->{poolip_name}     = $poolip->getAttr('name' => 'poolip_name');
        $tmp->{poolip_addr}     = $poolip->getAttr('name' => 'poolip_addr');
        $tmp->{poolip_mask}     = $poolip->getAttr('name' => 'poolip_mask');
        $tmp->{poolip_netmask}  = $poolip->getAttr('name' => 'poolip_netmask');
        $tmp->{poolip_gateway}  = $poolip->getAttr('name' => 'poolip_gateway');
        $tmp->{poolip_desc}     = $poolip->getComment;

        push(@$poolip_list, $tmp);
    }

    return $poolip_list;
}

get '/poolip' => sub {
    my $can_create;

    $can_create = 1;

    template 'poolip', {
        poolip_list => _poolip(),
        can_create => $can_create,
    };
};

get '/poolip/add' => sub {
    template 'form_addpoolip', {}, { layout => '' };
};

post '/poolip/add' => sub {
    my $adm = Administrator->new;
    eval { 
        my $poolip = Entity::Poolip->create(
                      poolip_name     => param('name'),
                      poolip_addr     => param('addr'),
                      poolip_mask     => param('mask'),
                      poolip_netmask  => param('netmask'),
                      poolip_gateway  => param('gateway'),
                  );
        $poolip->setComment(comment => param('desc'));
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/networks/poolip'); }
};

get '/poolip/:poolid/remove' => sub {
    my $adm = Administrator->new;
    my $poolip_id = param('poolid');
    my $epoolip = eval {
        Entity::Poolip->get(id => $poolip_id)
    };

    $epoolip->remove();

    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { redirect '/networks/poolip'; }
};

get '/poolip/:poolid' => sub {
    my $poolip_id = param('poolid');
    my $epoolip = eval {
        Entity::Poolip->get(id => $poolip_id)
    };

    my $network_def = NetAddr::IP->new($epoolip->getAttr('name' => 'poolip_addr'),
                                       $epoolip->getAttr('name' => 'poolip_netmask'));

    template 'poolip_details', {
        poolip_id      => $epoolip->getAttr('name' => 'poolip_id'),
        poolip_name    => $epoolip->getAttr('name' => 'poolip_name'),
        poolip_desc    => $epoolip->getComment,
        poolip_addr    => $epoolip->getAttr('name' => 'poolip_addr'),
        poolip_net     => $network_def->network(),
        poolip_netmask => $epoolip->getAttr('name' => 'poolip_netmask'),
        poolip_gateway => $epoolip->getAttr('name' => 'poolip_gateway'),
        poolip_size    => $epoolip->getAttr('name' => 'poolip_mask'),
    };
};

1;
