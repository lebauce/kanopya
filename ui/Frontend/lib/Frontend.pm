package Frontend;
use Dancer ':syntax';

use Login;
use REST::api;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

hook 'before' => sub {
    $ENV{EID} = session('EID');
};

hook 'before_template' => sub {
    my $tokens = shift;

    $tokens->{username}  = session('username');
};

get '/' => sub {
    my $product = config->{kanopya_product};
    template $product . '/index';
};

get '/sandbox' => sub {
    template 'sandbox', {}, {layout => ''};
};

get '/dashboard' => sub {
    template 'dashboard', {}, {layout => ''};
};

true;
