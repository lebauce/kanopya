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
        return pass;
    }
};

get '/login' => sub {
    redirect '/dashboard/status' if ( session('EID') );
    template 'login', {},{ layout=>'login' };
};

post '/login' => sub {
    my $user     = 'admin';#param('login');
    my $password = 'K4n0pY4';#param('password');
    my $redirect = session->{login_redirect_url} || '/dashboard/status';
    $redirect = '/dashboard/status' if $redirect eq '/';

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
        my $fail = {
            user => "Authentication failed for login $user"
        };
        $log->error('Authentication failed for login ', $user);
        return template 'login', { fail => $fail }, { layout => 'login' }
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
