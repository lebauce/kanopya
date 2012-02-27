package Vlans;

use Dancer ':syntax';
use General;
use Log::Log4perl "get_logger";
use Administrator;
use Entity::Vlan;
use Entity::Poolip;
use Data::Dumper;

prefix '/networks';

my $log = get_logger('webui');

sub _vlans {

    my @evlans = Entity::Vlan->getVlans(hash => {});
    my $vlans = [];

    foreach my $vlan (@evlans) {
        my $tmp = {};

        $tmp->{vlan_id}   = $vlan->getAttr('name' => 'vlan_id');
        $tmp->{vlan_name} = $vlan->getAttr('name' => 'vlan_name');
        $tmp->{vlan_desc}  = $vlan->getAttr('name' => 'vlan_desc');
        $tmp->{vlan_number}=$vlan->getAttr('name'=>'vlan_number');
        push(@$vlans, $tmp);
    }

    return $vlans;
}

get '/vlans' => sub {
   # my $methods = Entity::Vlan->getPerms();
    template 'vlans', {
        vlans_list => _vlans(),
        #can_create => $methods->{'create'}->{'granted'}
    };
};

get '/vlans/add' => sub {
    template 'form_addvlan', {}, { layout => '' };
};

post '/vlans/add' => sub {
    my $adm = Administrator->new;
    my $evlan = Entity::Vlan->new( 
            vlan_name => params->{'vlan_name'}, 
            vlan_desc => params->{'vlan_desc'},
            vlan_number => params->{'vlan_number'},
    );
    eval { $evlan->create(); };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/networks/vlans'); }
};

get '/vlans/:vlanid/remove' => sub {
    my $adm = Administrator->new();

    eval {
        my $evlan = Entity::Vlan->get( id => params->{vlanid} );
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
    
    my $evlan = eval { Entity::Vlan->get(id => $vlan_id) };
    my $poolipidassociated =$evlan->getassociatedPoolip();
    my $poolips = [];
    foreach my $ep (@$poolipidassociated)
    {
		my $poolip_id= $ep->{poolip_id};
	    my $poolip = Entity::Poolip->get(id => $poolip_id);
		my $tmpp = {};
        $tmpp->{poolip_name} = $poolip->getAttr(name => 'poolip_name');
        $tmpp->{url}         = "/networks/poolip/$poolip_id";
        $tmpp ->{poolip_id}=$poolip_id;
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
    
   
    
  # my $methods = Entity::Vlan->getPerms();
    
    template 'vlans_details', {
        vlan_id            => $evlan->getAttr('name' => 'vlan_id'),
        vlan_desc          => $evlan->getAttr('name' => 'vlan_desc'),
        vlan_number        => $evlan->getAttr('name' => 'vlan_number'),
        poolips_list       => $poolips,
        nbpoolips          => scalar(@$poolips)+1,
       #can_associate      => $methods->{'associateVlanpoolip'}->{'granted'},
       #can_delete         => $methods->{'removePoolip'}->{'granted'},
       #can_setperm       => $methods->{'setperm'}->{'granted'},
    };
};
get '/vlans/:vlanid/addpoolip' => sub {
	my @poolip = Entity::Poolip->getPoolip( hash => {} );
    my $poolips = [];
    foreach my $ep (@poolip)
    {
		my $poolip_id= $ep->getAttr(name => 'poolip_id');
		my $tmpp = {};
        $tmpp->{poolip_name}     = $ep->getAttr(name => 'poolip_name');
        $tmpp->{poolip_id}       = $ep->getAttr(name => 'poolip_id');
        $tmpp->{url}             = "/networks/poolip/$poolip_id";
        push(@$poolips, $tmpp);
	}
	
    template 'form_associatepoolip', {
        vlan_id => param('vlanid'),
        poolips_list =>$poolips,
    }, { layout => '' };
};
post '/vlans/:vlanid/associate' => sub {
	 my $adm = Administrator->new();
	 eval {
           my $host = Entity::Vlan->get(id => param('vlanid'));
           $host->associateVlanpoolip(poolip_id => param('poolipid'),vlan_id=>param('vlanid'));
          };
    if($@) {
            my $exception = $@;
            if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
           }
           else { $exception->rethrow(); }
       }  else { redirect '/networks/vlans/'.param('vlanid'); }
};
get '/vlans/:vlanid/removepoolip/:poolipid/remove' => sub {
     my $adm = Administrator->new;
       eval  {
            my $evlan = Entity::Vlan->get(id => param('vlanid'));
            $evlan->removePoolip(poolip_id => param('poolipid'));
            };
     if($@) {
             my $exception = $@;
             if(Kanopya::Exception::Permission::Denied->caught()) {
             $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
             redirect '/permission_denied';
            }
        else { $exception->rethrow(); }
           }
    else { redirect '/networks/vlans/'.param('vlanid'); }
};


1;
