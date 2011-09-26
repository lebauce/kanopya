package Frontend;
use Dancer;

use Dancer::Plugin::Preprocess::Sass;
use Login;
use Dashboard;
use Log::Log4perl;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

before sub {
    my $eid = session('EID');

    if ( ! session('username') && request->path ne '/login' ) {
        return '/login';
    }
    elsif ( request->path eq '/login' ) {
        return pass;
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
