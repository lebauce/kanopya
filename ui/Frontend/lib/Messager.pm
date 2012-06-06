package Messager;

use Dancer ':syntax'; 
use Dancer::Plugin::Ajax;
use Administrator;
use POSIX qw/ceil/;

prefix '/messager';

ajax '/operation/queue' => sub {
    my $adm = Administrator->new();
    my @operation_queue = $adm->getOperations();
    content_type('application/json');
    return to_json(@operation_queue);
};

ajax '/operation/quantity' => sub {
    my $adm = Administrator->new();
    my $operation_quantity = $adm->getOperationSum();
    content_type('application/json');
    return $operation_quantity;
};

1;
