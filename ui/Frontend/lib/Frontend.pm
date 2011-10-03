package Frontend;
use Dancer;

use Dancer::Plugin::Preprocess::Sass;
use Dancer::Plugin::Ajax;
use Login;
use Dashboard;
use Components;
use Log::Log4perl;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

before sub {
    $ENV{EID} = session('EID');
};

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

ajax '/messages' => sub {
    my $adm_object = Administrator->new();
    my @messages   = $adm_object->getMessages();

    content_type('application/json');
    return to_json(@messages);
};

any qr{.*} => sub {
    status 'not_found';
    template 'special_404', { path => request->path };
};

true;
