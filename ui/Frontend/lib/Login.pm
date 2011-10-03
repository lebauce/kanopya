package Login;

use Dancer ':syntax';
use Dancer::Plugin::FormValidator;

use Log::Log4perl "get_logger";
use Administrator;

my $log = get_logger('webui');

get qr(/.*) => sub {
    my $eid  = session('EID');
    my $path = request->path;

    if ( $path eq '/login' ) {
        return pass;
    }
    elsif ( ! $eid  ) {
        session login_redirect_url => $path;
        return redirect '/login';
    }
    else {
        $ENV{EID} = $eid;
        return pass;
    }
};

get '/login' => sub {
    redirect '/dashboard' if ( session('EID') );
    template 'login', {},{ layout=>'login' };
};

post '/login' => sub {
    my $user     = param('login');
    my $password = param('password');
    my $redirect = session->{login_redirect_url} || '/dashboard';

    my $input_hash = {
        login    => $user,
        password => $password
    };

    my $error = form_validator_error('login', $input_hash);
    if ( $error ) {
        return template 'login', { errors => $error }, { layout => 'login' };
    }

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
        delete session->{login_redirect_url};
        redirect $redirect;
    }
};

get '/logout' => sub {
    my $user = session('username');

    session->destroy;
    $log->info('Logout and session delete for login ', $user);
    redirect '/login';
};

1;
