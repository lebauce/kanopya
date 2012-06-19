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
        if (not $path =~ /^\/api/) {
            session login_redirect_url => $path;
        }
        return redirect '/login';
    }
    else {
        return pass;
    }
};

get '/login' => sub {
    redirect '/' if ( session('EID') );
    template 'login', {},{ layout=>'login' };
};

post '/login' => sub {
    my $user     = param('login');
    my $password = param('password');
    my $redirect = session->{login_redirect_url} || '/';
    #$redirect = '/dashboard/status' if $redirect eq '/';

    my $input_hash = {
        login    => $user,
        password => $password
    };

    my $error = form_validator_error('login', $input_hash);
    if ( $error ) {
        if (request->is_ajax) {
            return to_json({ status => 'error', 'reason' => $error }, { allow_nonref => 1, convert_blessed => 1, allow_blessed => 1 });
        } else {
            return template 'login', { errors => $error }, { layout => 'login' };
        }
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
        if (request->is_ajax) {
            return to_json({ status => 'error', 'reason' => $fail }, { allow_nonref => 1, convert_blessed => 1, allow_blessed => 1 });
        } else {
            return template 'login', { fail => $fail }, { layout => 'login' };
        }
    }
    else {
        session EID      => $ENV{EID};
        session username => $user;
        $log->info('Authentication succeed for login ', $user);
        delete session->{login_redirect_url};
        if (request->is_ajax) {
            return to_json({ status => 'success' }, { allow_nonref => 1, convert_blessed => 1, allow_blessed => 1 });
        } else {
            redirect $redirect;
        }
    }
};

get '/logout' => sub {
    my $user = session('username');

    session->destroy;
    $log->info('Logout and session delete for login ', $user);
    redirect '/login';
};

1;
