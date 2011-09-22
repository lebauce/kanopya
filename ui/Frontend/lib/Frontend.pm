package Frontend;
use Dancer;

use Login;
use Dashboard;
use Log::Log4perl;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

before sub {
    if ( ! session('username') && request->path ne '/login' ) {
        return '/login';
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
