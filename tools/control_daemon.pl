#!/usr/bin/perl -w

use strict;
use warnings;

use Kanopya::Exceptions;
use Kanopya::Database;
use General;
use Node;

use TryCatch;
use XML::Simple;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

# Get param
my ($daemon, $cbname, $control, $instances, $hostname) = @ARGV;
if (scalar(@ARGV) < 4) {
    print "Usage: control_daemon daemon_name callback_name control_type instances_number [ hostname ]\n";
    exit 1;
}

if (! defined $hostname) {
    $hostname = `hostname`;
}
chomp($hostname);

# Use the configuration file of the daemon
my $conf;
try {
    $conf = XMLin("/opt/kanopya/conf/" . $daemon . ".conf");
} 
catch ($err) {
    print "Unable to use the configuration file <$daemon.conf>:\n$err\n";
    exit 1;
}

# Authenticate
General::checkParams(args => $conf->{user}, required=>[ "name", "password" ]);

Kanopya::Database::authenticate(login    => $conf->{user}->{name},
                                password => $conf->{user}->{password});

# Build the component name from daemon name
my $component_name = 'Kanopya' . ucfirst($daemon);

# Get the node on wich is instaled the component
my $node;
try {
    $node = Node->find(hash => { 'node_hostname' => $hostname });
}
catch ($err) {
    print "Unable to find node with hostname <$hostname>:\n$err\n";
    exit 1;
}

# Get the component to call controlDaemon on it
my $component;
try {
    $component = $node->getComponent(name => $component_name);
}
catch ($err) {
    print "Unable to find component with name <$component_name> on node <$hostname>:\n$err\n";
    exit 1;
}

# Control the daemon
$component->controlDaemon(cbname => $cbname, control => $control, instances => $instances);

