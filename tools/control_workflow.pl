#!/usr/bin/perl -w

use strict;
use warnings;

use Kanopya::Exceptions;
use Kanopya::Database;
use General;
use Entity::Workflow;

use TryCatch;
use Switch;
use XML::Simple;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

# Get param
my ($id, $control) = @ARGV;
if (scalar(@ARGV) < 2) {
    print "Usage: control_workflow <id> <cancel|interrupt|resume>\n";
    exit 1;
}

# Use the configuration file of the daemon
my $conf;
try {
    $conf = XMLin("/opt/kanopya/conf/executor.conf");
} 
catch ($err) {
    print "Unable to use the configuration file <executor.conf>:\n$err\n";
    exit 1;
}

# Authenticate
General::checkParams(args => $conf->{user}, required => [ "name", "password" ]);

Kanopya::Database::authenticate(login    => $conf->{user}->{name},
                                password => $conf->{user}->{password});

# Check existance of the workflow
my $workflow;
try {
    $workflow = Entity::Workflow->get(id => $id);
} 
catch ($err) {
    print "Workflow with id <$id> does not exists\n";
    exit 1;
}

switch ($control) {
    case 'cancel' {
        $workflow->cancel();
    }
    case 'interrupt' {
        $workflow->interrupt();
    }
    case 'resume' {
        my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
        $kanopya->getManager(manager_type => 'ExecutionManager')->resume(
            workflow_id => $workflow->id
        );
    }
    else {
        throw Kanopya::Exception::Execution(
                  error => "Unknown controle code <$control>"
              );
    }
}
