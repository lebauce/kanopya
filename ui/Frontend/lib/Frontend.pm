package Frontend;
use Dancer ':syntax';
#use Login;
use Messager;

our $VERSION = '0.1';

prefix undef;

get '/' => sub {
    my $product = config->{kanopya_product};
    template $product . '/index';
};


get '/sandbox' => sub {
    template 'sandbox', {}, {layout => ''};
};


true;
