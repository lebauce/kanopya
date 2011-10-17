package Messager;

use Dancer ':syntax'; 
use Dancer::Plugin::Ajax;
use Administrator;

prefix '/';

ajax '/messages' => sub {
    my $adm = Administrator->new();
    my @messages   = $adm->getMessages();
    content_type('application/json');
    return to_json(\@messages);
};

ajax '/operation/queue' => sub {
    my $adm      = Administrator->new();
    my @operation_queue = $adm->getOperations();
    content_type('application/json');
    return to_json(@operation_queue);
};

1;
