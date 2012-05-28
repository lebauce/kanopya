package Lans;

use Dancer ':syntax';
use General;
use Administrator;
use Entity::Network;
use Entity::Network::Vlan;
use Entity::Poolip;

use Log::Log4perl "get_logger";
use Data::Dumper;

prefix '/networks';

my $log = get_logger('webui');

sub _lans {
    my @elans = Entity::Network->search(hash => {});
    my $lans = [];

    foreach my $lan (@elans) {
        # Do not handle vlans
        if (not $lan->isa('Entity::Network::Vlan')) {
            my $tmp = {};
            $tmp->{lan_id}     = $lan->getAttr(name => 'entity_id');
            $tmp->{lan_name}   = $lan->getAttr(name => 'network_name');
            $tmp->{lan_desc}   = $lan->getComment;
    
            push(@$lans, $tmp);
        }
    }

    return $lans;
}

get '/lans' => sub {
    template 'lans', {
        lans_list => _lans(),
        #can_create => $methods->{'create'}->{'granted'}
    };
};

get '/lans/add' => sub {
    template 'form_addlan', {}, { layout => '' };
};

post '/lans/add' => sub {
    my $elan = Entity::Network->new(
                    network_name => params->{'lan_name'},
                );
    $elan->setComment(comment => params->{'lan_desc'});

    redirect('/networks/lans');
};

get '/lans/:lanid/remove' => sub {
    my $adm = Administrator->new();

    eval {
        my $elan = Entity::Network->get( id => params->{lanid} );
        $elan->delete();
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
        redirect '/networks/lans';
    }
};

get '/lans/:lanid' => sub {
    my $lan_id = param('lanid');
    
    my $elan = eval { Entity::Network->get(id => $lan_id) };
    my $poolipidassociated = $elan->getAssociatedPoolips();
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

    template 'lans_details', {
        lan_id       => $elan->getAttr('name' => 'entity_id'),
        poolips_list => $poolips,
        nbpoolips    => scalar(@$poolips)+1,
        lan_desc     => $elan->getComment,
    };
};

get '/lans/:lanid/addpoolip' => sub {
    my @poolip = Entity::Poolip->getPoolip( hash => {} );
    my $lan    = Entity::Network->get(id => param('lanid'));

    my $associated = $lan->getAssociatedPoolips();
    my $poolips    = [];
    foreach my $ep (@poolip) {
        my $poolip_id = $ep->getAttr(name => 'poolip_id');

        if (grep {$_->getAttr(name => 'entity_id') == $poolip_id} @$associated) { next; }

        my $tmpp = {};
        $tmpp->{poolip_name} = $ep->getAttr(name => 'poolip_name');
        $tmpp->{poolip_id}   = $ep->getAttr(name => 'poolip_id');
        $tmpp->{url}         = "/networks/poolip/$poolip_id";
        push(@$poolips, $tmpp);
    }

    template 'form_associatepoolip', {
        lan_id      => param('lanid'),
        poolips_list => $poolips,
    }, { layout => '' };
};

post '/lans/:lanid/associate' => sub {
    my $adm = Administrator->new();
    my ($lan, $poolip);
    eval {
        $lan    = Entity::Network->get(id => param('lanid'));
        $poolip = Entity::Poolip->get(id => param('poolipid'));

        $lan->associatePoolip(poolip => $poolip);
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
        my $type = $lan->isa('Entity::Network::Vlan') ? 'vlans' : 'lans';
        redirect '/networks/' .$type . '/' . param('lanid');
    }
};

get '/lans/:lanid/removepoolip/:poolipid/remove' => sub {
    my $adm = Administrator->new;
    my ($lan, $poolip);
    eval {
        $lan   = Entity::Network->get(id => param('lanid'));
        $poolip = Entity::Poolip->get(id => param('poolipid'));

        $lan->dissociatePoolip(poolip => $poolip);
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
        my $type = $lan->isa('Entity::Network::Vlan') ? 'vlans' : 'lans';
        redirect '/networks/' .$type . '/'.param('lanid');
    }
};

1;
