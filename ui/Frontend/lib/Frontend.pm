package Frontend;

use strict;
use warnings;

use Dancer ':syntax';
#use Dancer::Plugin::Preprocess::Sass;
use Dancer::Plugin::Ajax;

use Kanopya::Config;
use Kanopya::Version;

use Login;
use KIO::Services;
use Monitoring;
use Validation;
use REST::api;

use KIM::Consommation;
use KIM::MasterImage;
use KIM::WorkflowLogs;
use Services;
use REST::Documentation;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

our $VERSION = '0.1';

prefix undef;

my $dir = Kanopya::Config::getKanopyaDir();
Log::Log4perl->init($dir . '/conf/webui-log.conf');

hook 'before' => sub {
    $ENV{EID} = session('EID');
};

hook 'before_template' => sub {
    my $tokens = shift;

    $tokens->{username}  = session('username');
};

get '/' => sub {
    my $product = config->{kanopya_product};
    template $product . '/index', config();
};

get '/kim' => sub {
    my $product = 'KIM';
    template $product . '/index', config();
};

get '/kio' => sub {
    my $product = 'KIO';
    template $product . '/index', config();
};

get '/conf' => sub {
    content_type "application/json";
    return to_json {
        'messages_update'   => defined config->{'messages_update'}  ? int(config->{'messages_update'})  : 10,
        'show_gritters'     => defined config->{'show_gritters'}    ? int(config->{'show_gritters'})    : 1,
    };
};

get '/sandbox' => sub {
    template 'sandbox', {}, {layout => ''};
};

get '/dashboard' => sub {
    template 'dashboard', {}, {layout => ''};
};

get '/about' => sub {
    template 'about', { version => Kanopya::Version::version }, { layout => '' };
};

sub exception_to_status {
    my $exception = shift;
    my $status;

    return "error" if not defined $exception;

    # Log the execption
    $log->error("$exception");

    if ($exception->isa("Kanopya::Exception::Permission::Denied")) {
        $status = 'forbidden';
    }
    elsif ($exception->isa("Kanopya::Exception::Internal::NotFound")) {
        $status = 'not_found';
    }
    elsif ($exception->isa("Kanopya::Exception::NotImplemented")) {
        $status = "method_not_allowed";
    }
    elsif ($exception->isa("Kanopya::Exception::DB::DeleteCascade")) {
        $status = 'conflict';
    }
    elsif ($exception->isa("Kanopya::Exception::DB::DuplicateEntry")) {
        $status = 'conflict';
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
    my $status = exception_to_status($exception->exception);

    my $message = {"status" => "error", "reason" => $exception->exception->user_message};
    $exception->{message} = $message;

};

hook 'after_error_render' => sub {
    status request->{status};
};

true;
