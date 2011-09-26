package Frontend;
use Dancer;

use Dancer::Plugin::Preprocess::Sass;
use Login;
use Dashboard;
use Log::Log4perl;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

before_template sub {
    my $tokens = shift;

    $tokens->{css_head} = [];
    $tokens->{js_head}  = [];
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
