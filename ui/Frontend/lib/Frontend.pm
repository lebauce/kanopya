package Frontend;
use Dancer;

use Dancer::Plugin::Preprocess::Sass;
use Login;
use Dashboard;
use Components;
use Log::Log4perl;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

before_template sub {
    my $tokens = shift;

    $tokens->{css_head} = [];
    $tokens->{js_head}  = [];
    $tokens->{username} = session('username');
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
