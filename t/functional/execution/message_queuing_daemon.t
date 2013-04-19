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
    use_ok ('MessageQueuing::Sender');

    my $daemonconf = {
        config => {
            user => {
                name     => 'admin',
                password => '_tamere23'
            }
        }
    };

    # Generate a unique message adresse for this test
    my $channel = 'message_queuing_test_' . time;

    my @configarray = %$daemonconf;
    my $genericdaemon = new_ok("Daemon::MessageQueuing", \@configarray, "Instantiate a generic Daemon::MessageQueuing");
    my $genericdaemon2 = new_ok("Daemon::MessageQueuing", \@configarray, "Instantiate a generic Daemon::MessageQueuing");

    # Use the client lib to send messages
    MessageQueuing::Sender->connect();

    # Defined the callback method
    sub callback {
        return 1;
    }

    # Register the generic daemon as a worker on channel 'generic'
    $genericdaemon->registerWorker(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');
    $genericdaemon2->registerWorker(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');

    $genericdaemon->registerSubscriber(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');
    $genericdaemon2->registerSubscriber(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');

    # Firstly send a message on the channel $channel
    MessageQueuing::Sender->send(channel => $channel, test => 'test');

    lives_ok {
        $genericdaemon->oneRun(channel => $channel, type => 'queue');
    } 'Fetch the message as worker1';
    
    throws_ok {
        $genericdaemon->oneRun(channel => $channel, type => 'queue');
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as worker1 an already consummed message.";

    throws_ok {
        $genericdaemon2->oneRun(channel => $channel, type => 'queue');
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as worker2 an already consummed message.";

    lives_ok {
        $genericdaemon->oneRun(channel => $channel, type => 'topic');
    } 'Fetch the message as subscriber1';

    throws_ok {
        $genericdaemon->oneRun(channel => $channel, type => 'topic');
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as subcriber1 an already consummed message.";

    lives_ok {
        $genericdaemon2->oneRun(channel => $channel, type => 'topic');
    } 'Fetch the message as subscriber2';

    throws_ok {
        $genericdaemon->oneRun(channel => $channel, type => 'topic');
    } "Kanopya::Exception::MessageQueuing::NoMessage",
      "Try to fetch as subcriber2 an already consummed message.";

    $genericdaemon->disconnect();
    $genericdaemon2->disconnect();
};
if ($@) {
    my $error = $@;
    print $error."\n";
};

1;
