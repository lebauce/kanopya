#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;

use Kanopya::Exceptions;
use EContext::Local;
use ERollback;

use Data::Dumper;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'message_queuing_daemon.t.log',
    layout => '%F %L %p %m%n'
});


eval {
    use_ok ('Daemon::MessageQueuing');
    use_ok ('MessageQueuing::RabbitMQ::Sender');

    my $daemonconf = {
        config => {
            user => {
                name     => 'admin',
                password => 'K4n0pY4'
            },
            amqp => {
                user     => 'executor',
                password => 'K4n0pY4'
            }
        }
    };

    # Generate a unique message adresse for this test
    my $queue = 'message_queuing_test_' . time;

    my @configarray = %$daemonconf;
    my $genericdaemon = new_ok("Daemon::MessageQueuing", \@configarray, "Instantiate a generic Daemon::MessageQueuing");
    my $genericdaemon2 = new_ok("Daemon::MessageQueuing", \@configarray, "Instantiate a generic Daemon::MessageQueuing");

    # Use the client lib to send messages
    my $genericclient = MessageQueuing::RabbitMQ::Sender->new();
    $genericclient->connect(%{ $daemonconf->{config}->{amqp} });

    # Defined the callback method
    sub callback {
        my @args = @_;
    }

    # Connect manually in order to create the reciever at register, without it,
    # the connection and the receivers are created at oneRun call.
    $genericdaemon->connect(%{ $daemonconf->{config}->{amqp} });
    $genericdaemon2->connect(%{ $daemonconf->{config}->{amqp} });

    # Register the generic daemons as workers
    $genericdaemon->registerWorker(cbname => $queue, type => "queue", queue => $queue, callback => \&callback);
    $genericdaemon2->registerWorker(cbname => $queue, type => "queue", queue => $queue, callback => \&callback);

    # Register the generic daemon as subscribers
    $genericdaemon->registerSubscriber(cbname => $queue . "_notifications", exchange => $queue, type => 'fanout', callback => \&callback);
    $genericdaemon2->registerSubscriber(cbname => $queue . "_notifications", exchange => $queue, type => 'fanout', callback => \&callback);

    # Create the consumers for subricptions before sending the message because the
    # exclusive queues are not binded on the exchange at the essage send instead.
    $genericdaemon->createConsumer(cbname => $queue . "_notifications");
    $genericdaemon2->createConsumer(cbname => $queue . "_notifications");

    # Firstly send a message on the queue/exchange $queue
    $genericclient->send(queue => $queue, test => 'test');

    # NOTE: Calling onRun on callback of type fanout or topic has non sens, has oneRun
    #       should firstly connect, create the consumer, and disconnect, but this raise
    #       a new exclusive queue binded on the exchange but that loose the message
    #       when it has been send on the exchange.
    #       So, create the consumer before sending the message, and do not disconnect
    #       the receiver if we want to simulate a continuous subscription for test purpose.
    lives_ok {
        $genericdaemon->oneRun(cbname => $queue . "_notifications", duration => 1, keep_connection => 1);
    } 'Fetch the message as subscriber1';

    throws_ok {
       $genericdaemon->oneRun(cbname => $queue . "_notifications", duration => 1);
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as subcriber1 an already consummed message.";

    lives_ok {
        $genericdaemon2->oneRun(cbname => $queue . "_notifications", duration => 1, keep_connection => 1);
    } 'Fetch the message as subscriber2';

    throws_ok {
        $genericdaemon2->oneRun(cbname => $queue . "_notifications", duration => 1);
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as subcriber2 an already consummed message.";

    lives_ok {
        $genericdaemon->oneRun(cbname => $queue, duration => 1);
    } 'Fetch the message as worker1';

    throws_ok {
        $genericdaemon->oneRun(cbname => $queue, duration => 1);
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as worker1 an already consummed message.";

    throws_ok {
        $genericdaemon2->oneRun(cbname => $queue, duration => 1);
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as worker2 an already consummed message.";

    # Uncomment this lines to test the daemon (infinite loop)
    # my $running = 1;
    # $genericdaemon->run(\$running);

    $genericclient->disconnect();
    $genericdaemon->disconnect();
    $genericdaemon2->disconnect();
};
if ($@) {
    my $error = $@;
    print $error."\n";
};

1;
