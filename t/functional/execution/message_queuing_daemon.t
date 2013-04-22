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
    use_ok ('MessageQueuing::Qpid::Sender');

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
    MessageQueuing::Qpid::Sender->connect();

    # Defined the callback method
    sub callback {
        my (%args) = @_;
#        print "Message received " . Dumper(\%args) . "\n";
    }

    # Connect manually in order to create the reciever at register, without it,
    # the connection and the receivers are created at oneRun call.
    $genericdaemon->connect();
    $genericdaemon2->connect();

    # Register the generic daemons as workers on channel 'generic'
    $genericdaemon->registerWorker(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');
    $genericdaemon2->registerWorker(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');

    # Register the generic daemon as subscribers on channel 'generic'
    $genericdaemon->registerSubscriber(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');
    $genericdaemon2->registerSubscriber(channel => $channel, callback => \&callback, duration => 'IMMEDIATE');

    # Firstly send a message on the channel $channel
    MessageQueuing::Qpid::Sender->send(channel => $channel, test => 'test');
    
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

    # Uncomment this lines to test the daemon
    # my $running = 1;
    # $genericdaemon->run(\$running);

    MessageQueuing::Qpid::Sender->disconnect();
    $genericdaemon->disconnect();
    $genericdaemon2->disconnect();
};
if ($@) {
    my $error = $@;
    print $error."\n";
};

1;
