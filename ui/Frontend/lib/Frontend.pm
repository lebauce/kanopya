package Frontend;
use Dancer;

use Dancer::Plugin::Preprocess::Sass;
use Login;
use Dashboard;
use Log::Log4perl;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

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

get '/' => sub {
    if ( session('username') ) {
        redirect '/dashboard';
    }
    else {
        redirect '/login';
    }
};

true;
