package Frontend;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/sandbox' => sub {
    template 'sandbox', {}, {layout => ''};
};


true;
