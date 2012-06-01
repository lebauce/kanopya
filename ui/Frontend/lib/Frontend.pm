package Frontend;

use Dancer ':syntax';
#use Dancer::Plugin::Preprocess::Sass;
use Dancer::Plugin::Ajax;

use Login;
use KIO::Services;
use Messager;
use Monitoring;
use REST::api;

our $VERSION = '0.1';

prefix undef;

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

get '/kim' => sub {
    my $product = 'KIM';
    template $product . '/index';
};

get '/kio' => sub {
    my $product = 'KIO';
    template $product . '/index';
};

get '/sandbox' => sub {
    template 'sandbox', {}, {layout => ''};
};

get '/dashboard' => sub {
    template 'dashboard', {}, {layout => ''};
};

sub exception_to_status {
    my $exception = shift;
    my $status;

    return $status if not defined $exception; 

    if ($exception->isa("Kanopya::Exception::Permission::Denied")) {
        $status = 'forbidden';
    }
    elsif ($exception->isa("Kanopya::Exception::Internal::NotFound")) {
        $status = 'not_found';
    }
    else {
        $status = 'error';
    }

    # Really tricky : we store the status code in the request
    # as the exception is not available in the 'after_error_render' hook
    request->{status} = $status;

    return $status;
}

hook 'before_error_init' => sub {
    my $exception = shift;
    my $status = exception_to_status($exception->{exception});

    if (defined $status && request->is_ajax) {
        content_type "application/json";
        set error_template => '/json_error.tt';
    }
};

hook 'after_error_render' => sub {
    status request->{status};
};

true;
