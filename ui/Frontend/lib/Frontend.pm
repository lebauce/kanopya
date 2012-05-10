package Frontend;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    my $product = config->{kanopya_product};
    template $product . '/index';
};

get '/sandbox' => sub {
    template 'sandbox', {}, {layout => ''};
};


true;
