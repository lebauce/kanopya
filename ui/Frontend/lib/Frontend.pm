package Frontend;
use Dancer ':syntax';

use Login;

use Log::Log4perl;

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

true;
