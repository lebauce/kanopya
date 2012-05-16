package Messager;

use Dancer ':syntax'; 
use Dancer::Plugin::Ajax;
use Administrator;
use POSIX qw/ceil/;

prefix '/messager';

=head2

get '/message' => sub {
    my $adm = Administrator->new();
    my @messages   = $adm->getMessages();
    my $total_pages;
    my $nbOfMessages = scalar(@messages);
    my $limit = params->{'rowNum'};
    my %msg;
    $msg{page} = 1;
    $msg{records} = $nbOfMessages;
    if( $nbOfMessages > 0 ) {
        if( $limit != 0 ) {
	       $total_pages = ceil($nbOfMessages/$limit);
        } else {
            $limit = 25;
        }
    } else {
	   $total_pages = 0;
    }
    $msg{total} = $total_pages;
    foreach my $message (@messages) {
        my $msgid   = $message->getAttr(name => 'id');
        my $from    = $message->getAttr(name => 'from');
        my $level   = $message->getAttr(name => 'level');
        my $date    = $message->getAttr(name => 'date');
        my $time    = $message->getAttr(name => 'time');
        my $content = $message->getAttr(name => 'content');   
        #$msg{rows}{id}=$count;
        $msg{rows}{cell}=[$msgid,$from,$level,$date,$time,$content];
        
    }     
    content_type 'application/json';
    return to_json \%msg;
};

=cut

get '/messages' => sub {
    my $adm = Administrator->new();
    my @messages   = $adm->getMessages(limit => 100);
    my $nbOfMessages = scalar(@messages);
    my $total_pages = 1;
    my $response = {};
    my $msgid = 0;
    my @rows;
    my @msg;
    my $limit = params->{'rowNum'} || 20;
    #print 'Number of messages : ' . $nbOfMessages . "\n";
    if( $nbOfMessages > 0 ) {
        if( $limit != 0 ) {
	       $total_pages = ceil($nbOfMessages / $limit);
        } else {
            $limit = 20;
        }
    } else {
	   $total_pages = 1;
    }
    #print 'Number of pages : ' . $total_pages . "\n";
    foreach my $message (@messages) {
        $msgid = $message->{'id'};
        my $from = $message->{'from'};
        my $level = $message->{'level'};
        my $date = $message->{'date'};
        my $time = $message->{'time'};
        my $content = $message->{'content'};

        my $row = { 
            #'id' => $msgid,
            #'cell' => [$msgid,$from,$level,$date,$time,$content],
            'id'  => $msgid,
            'from' => $from,
            'level' => $level,
            'date' => $date,
            'time' => $time,
            'content' => $content,
        };
        push @rows,$row; 
    }

    $response->{rows}=\@rows;
    $response->{page}=1;
    $response->{total_pages}=$total_pages;
    $response->{records}=$nbOfMessages;
    

    content_type 'application/json';
    return to_json $response;
};

=head2

ajax '/messages' => sub {
    my $adm = Administrator->new();
    my @messages   = $adm->getMessages(limit => 100);
    my $total_pages;
    my $nbOfMessages = scalar(@messages);
    my $limit = params->{'rows'};
    my %msg;
    $msg{page} = 1;
    $msg{records} = $nbOfMessages;
    if( $nbOfMessages > 0 ) {
	   $total_pages = ceil($nbOfMessages/$limit);
    } else {
	   $total_pages = 0;
    }
    $msg{total} = $total_pages;
    for (my $count = 0; $count = $nbOfMessages; $count++) {
        my $msgid   = $messages[$count]->getAttr('name' => 'id');
        my $from    = $messages[$count]->getAttr('name' => 'from');
        my $level   = $messages[$count]->getAttr('name' => 'level');
        my $date    = $messages[$count]->getAttr('name' => 'date');
        my $time    = $messages[$count]->getAttr('name' => 'time');
        my $content = $messages[$count]->getAttr('name' => 'content');   
        $msg{rows}[$count]{id}=$count;
        $msg{rows}[$count]{cell}=[$msgid,$from,$level,$date,$time,$content];
        
    }     
    content_type 'application/json';
    return to_json \%msg;
    
    #content_type('application/json');
    #return to_json(\@messages);
};

=cut

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
