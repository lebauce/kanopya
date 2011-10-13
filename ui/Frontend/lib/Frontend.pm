package Frontend;
use Dancer;

use Dancer::Plugin::Preprocess::Sass;
use Dancer::Plugin::Ajax;
use Login;
use Dashboard;
use Components;
use Distributions;
use Kernels;
use Images;
use Models;
use Log::Log4perl;

our $VERSION = '0.1';

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

before sub {
    $ENV{EID} = session('EID');
};

before_template sub {
    my $tokens = shift;

    $tokens->{css_head}  = [];
    $tokens->{js_head}   = [];
    $tokens->{username}  = session('username');
    $tokens->{menu_selection} = sub {
        my $url = shift;

        return 'class="selected"' if ( $url eq (split '/', request->path())[-2] );
    };
    $tokens->{is_menu_selected} = sub {
        my $url = shift;

        return ( $url eq (split '/', request->path())[-2] );
    };
    $tokens->{submenu_selection} = sub {
        my $url = shift;
        
        # Doing this we can't have submenu with the same name in different menu
        return 'class="selected"' if ( $url eq (split '/', request->path())[-1] );
    };
};

get '/' => sub {
    if ( session('username') ) {
        redirect '/dashboard/status';
    }
    else {
        redirect '/login';
    }
};

get '/permission_denied' => sub {
    template 'permission_denied';
};

ajax '/messages' => sub {
    my $adm_object = Administrator->new();
    my @messages   = $adm_object->getMessages();
    content_type('application/json');
    return to_json(\@messages);
};

ajax '/operation/queue' => sub {
    my $adm_object      = Administrator->new();
    my @operation_queue = $adm_object->getOperations();

    content_type('application/json');
    return to_json(@operation_queue);
};

any qr{.*} => sub {
    status 'not_found';
    template 'special_404', { path => request->path };
};

true;
