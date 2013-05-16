#!/usr/bin/perl -w

use strict;
use warnings;
use XML::Simple;

use Kanopya::Exceptions;
use BaseDB;
use General;

use Entity::ServiceProvider::Cluster;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

# Get param
my $arg = $ARGV[0];
if (not defined $arg) {
    print "Usage: deploy_masterimage /path/to/your/masterimage/file.tar.bz\n";
    exit 1;
}

if(! -e $arg) {
    print "file $arg not found\n";
    exit 2;
}

my $conf = XMLin("/opt/kanopya/conf/executor.conf");
General::checkParams(args=>$conf->{user}, required=>["name","password"]);


my $adm = BaseDB->authenticate(
              login    => $conf->{user}->{name},
	          password => $conf->{user}->{password}
          );

eval {
    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
    $kanopya->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'DeployMasterimage',
        params   => { file_path => "$arg", keep_file => 1 },
    );
};
if ($@) {
    print "Failed:\n$@";
}
else {
    print "DeployMasterimage operation added to operations queue\n";
}
