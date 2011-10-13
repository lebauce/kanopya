package Networks;

use Dancer ':syntax';

get '/public/ips' => sub {
	template 'publicips', {
		publicips => $adm_object->{manager}->{network}->getPublicIP(),
        titlepage => 'Public IPs View',
		};
};

get '/public/ip/remove/:id' => sub {
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
    
    redirect('/public/ips');
};


post '/public/ip/add' sub {
    my $adm_object = Administrator->new();
    my $input_hash = {
        ip_address => params->{ip_address},
        ip_mask    => params->{ip_mask}
    };

    my $error = form_validator_error('public_ip_add', $input_hash);

    return if ( $error );

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
};

