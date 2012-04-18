package Vlans;

use Dancer ':syntax';
use General;
use Administrator;
use Entity::Network::Vlan;
use Entity::Poolip;

use Log::Log4perl "get_logger";
use Data::Dumper;

prefix '/networks';

my $log = get_logger('webui');

sub _vlans {
    my @evlans = Entity::Network::Vlan->search(hash => {});
    my $vlans = [];

    foreach my $vlan (@evlans) {
        my $tmp = {};
        $tmp->{vlan_id}     = $vlan->getAttr(name => 'entity_id');
        $tmp->{vlan_name}   = $vlan->getAttr(name => 'network_name');
        $tmp->{vlan_number} = $vlan->getAttr(name => 'vlan_number');
        $tmp->{vlan_desc}   = $vlan->getComment;

        push(@$vlans, $tmp);
    }

    return $vlans;
}

get '/vlans' => sub {
    template 'vlans', {
        vlans_list => _vlans(),
        #can_create => $methods->{'create'}->{'granted'}
    };
};

get '/vlans/add' => sub {
    template 'form_addvlan', {}, { layout => '' };
};

post '/vlans/add' => sub {
    my $evlan = Entity::Network::Vlan->new(
                    network_name => params->{'vlan_name'},
                    vlan_number  => params->{'vlan_number'},
                );
    $evlan->setComment(comment => params->{'vlan_desc'});

    redirect('/networks/vlans');
};

get '/vlans/:vlanid/remove' => sub {
    my $adm = Administrator->new();

    eval {
        my $evlan = Entity::Network::Vlan->get( id => params->{vlanid} );
        $evlan->delete();
    };
    if ( $@ ) {
        my $exception = $@;
        if ( Kanopya::Exception::Permission::Denied->caught() ) {
           $adm->addMessage(
               from    => 'Administrator',
               level   => 'error',
               content => $exception->error
           );

           redirect '/permission_denied';
        }
        else {
            $exception->rethrow();
        }
    }
    else {
        redirect '/networks/vlans';
    }
};

get '/vlans/:vlanid' => sub {
    my $vlan_id = param('vlanid');
    
    my $evlan = eval { Entity::Network::Vlan->get(id => $vlan_id) };
    my $poolipidassociated = $evlan->getAssociatedPoolips();
    my $poolips = [];
    foreach my $poolip (@$poolipidassociated) {
        my $tmpp = {};

        $tmpp->{poolip_id}   = $poolip->getAttr(name => 'entity_id');
        $tmpp->{poolip_name} = $poolip->getAttr(name => 'poolip_name');
        $tmpp->{url}         = "/networks/poolip/" . $tmpp->{poolip_id};

        push(@$poolips, $tmpp);
    }
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            my $adm = Administrator->new;
            $adm->addMessage(from => 'Administrator', level => 'warning', content => $exception->error);
            redirect('/permission_denied');
        }
        else {
            $exception->rethrow();
        }
    }

    template 'vlans_details', {
        vlan_id      => $evlan->getAttr('name' => 'entity_id'),
        vlan_number  => $evlan->getAttr('name' => 'vlan_number'),
        poolips_list => $poolips,
        nbpoolips    => scalar(@$poolips)+1,
        vlan_desc    => $evlan->getComment,
    };
};

get '/vlans/:vlanid/addpoolip' => sub {
    my @poolip = Entity::Poolip->getPoolip( hash => {} );
    my $poolips = [];
    foreach my $ep (@poolip)
    {
        my $poolip_id= $ep->getAttr(name => 'poolip_id');
        my $tmpp = {};
        $tmpp->{poolip_name} = $ep->getAttr(name => 'poolip_name');
        $tmpp->{poolip_id}   = $ep->getAttr(name => 'poolip_id');
        $tmpp->{url}         = "/networks/poolip/$poolip_id";
        push(@$poolips, $tmpp);
    }

    template 'form_associatepoolip', {
        vlan_id      => param('vlanid'),
        poolips_list => $poolips,
    }, { layout => '' };
};

post '/vlans/:vlanid/associate' => sub {
    my $adm = Administrator->new();
    eval {
        my $vlan   = Entity::Network::Vlan->get(id => param('vlanid'));
        my $poolip = Entity::Poolip->get(id => param('poolipid'));

        $vlan->associatePoolip(poolip => $poolip);
    };
    if($@) {
        my $exception = $@;
        if (Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else {
            $exception->rethrow();
        }
    }
    else {
        redirect '/networks/vlans/'.param('vlanid');
    }
};

get '/vlans/:vlanid/removepoolip/:poolipid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $vlan   = Entity::Network::Vlan->get(id => param('vlanid'));
        my $poolip = Entity::Poolip->get(id => param('poolipid'));

        $vlan->dissociatePoolip(poolip => $poolip);
     };
     if($@) {
         my $exception = $@;
         if (Kanopya::Exception::Permission::Denied->caught()) {
             $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
             redirect '/permission_denied';
         }
         else {
             $exception->rethrow();
         }
    }
    else {
        redirect '/networks/vlans/'.param('vlanid');
    }
};

1;
