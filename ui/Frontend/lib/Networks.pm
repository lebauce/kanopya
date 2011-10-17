package Networks;

use Dancer ':syntax';

use Administrator;

prefix '/architectures/networks';

get '/' => sub {
    redirect('/architectures/networks/ips/public');
};

get '/ips/public' => sub {
    my $adm_object = Administrator->new();

    template 'publicips', {
        publicips => $adm_object->{manager}->{network}->getPublicIPs(),
        title_page => 'Public IPs View',
     };
};

get '/ips/public/:id/remove' => sub {
    my $adm_object = Administrator->new();

    eval {
        $adm_object->{manager}->{network}->delPublicIP( publicip_id => params->{id} );
    };
    if ($@) {
       my $error = $@;
       $adm_object->addMessage(
           from    => 'Administrator',
           level   => 'error',
           content => $error
       );
    }

    else {
       $adm_object->addMessage(
           from    => 'Administrator',
           level   => 'info',
           content => 'public ip removed'
       );
    }

    redirect('/architectures/networks/ips/public');
};


get '/ips/public/add' => sub {
    template 'form_addpublicip', {
        title_page  => "Network - Public ip creation",
    }, { layout => '' };
};


post '/ips/public/add' => sub {
    my $adm_object = Administrator->new();
    my $input_hash = {
        ip_address => params->{ip_address},
        ip_mask    => params->{ip_mask}
    };

    #my $error = form_validator_error('public_ip_add', $input_hash);
    #return if ( $error );

    eval {
        $adm_object->{manager}->{network}->newPublicIP(
            ip_address => params->{ip_address},
            ip_mask    => params->{ip_mask},
            gateway    => params->{gateway} ne '' ? params->{gateway} : undef,
        );
    };
    if ( $@ ) {
        my $error = $@;
        $adm_object->addMessage(
            from    => 'Administrator',
            level   => 'error',
            content => $error
        );
    }
    else {
        $adm_object->addMessage(
            from    => 'Administrator',
            level   => 'info',
            content => 'New public ip added'
        );
    }
    
    redirect '/architectures/networks';
};

1;
