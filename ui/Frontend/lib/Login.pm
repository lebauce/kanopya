package Login;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
use Administrator;

my $log = get_logger('webui');

get qr(/.*) => sub {
    my $eid = session('EID');

    if ( request->path eq '/login' ) {
        return pass;
    }
    elsif ( ! $eid  ) {
        return redirect '/login';
    }
    else {
        $ENV{EID}      = $eid;
        var adm_object => Administrator->new();
        return pass;
    }
};

get '/login' => sub {
    template 'login', {},{ layout=>'login' };
};

post '/login' => sub {
    my $user     = param('login');
    my $password = param('password');

    eval {
        Administrator::authenticate(
            login    => $user,
            password => $password
        );
    };

    if ( $@ ) {
        $log->error('Authentication failed for login ', $user);
    }
    else {
        session EID      => $ENV{EID};
        session username => $user;
        $log->info('Authentication succeed for login ', $user);
        redirect '/dashboard';
    }
};

get '/logout' => sub {
    my $user = session('username');

    session->destroy;
    $log->info('Logout and session delete for login ', $user);
    redirect '/login';
};

1;
