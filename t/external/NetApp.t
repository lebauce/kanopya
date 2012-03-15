#!/usr/bin/perl -w

use lib "../../lib/external/NetApp";

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use Log::Log4perl qw(:easy);
use Data::Dumper;
use NetApp::API;
use Term::ReadKey;

Log::Log4perl->easy_init( {
    level => 'DEBUG',
    file => '/tmp/NetApp.t.log',
    layout => '%F %L %p %m%n'}
);

sub main {
    my ($netapp_addr, $netapp_login, $netapp_passwd);

    print "Please enter the NetApp IP address :\n";
    chomp($netapp_addr = <STDIN>);

    print "Please enter the NetApp login :\n";
    chomp($netapp_login = <STDIN>);

    print "Please enter the NetApp password :\n";
    ReadMode('noecho');
    chomp($netapp_passwd = <STDIN>);
    ReadMode('original');

    my $netapp = NetApp::API->new(
        addr     => $netapp_addr,
        username => $netapp_login,
        passwd   => $netapp_passwd
    );

    $netapp->login();
    my $result = $netapp->system_get_version();
    my $version = $result->child_get("version");
    print "NetApp version " . $version->get_content() . "\n";

    print "NetApp version " . $result->version;

    print "Luns " . $netapp->luns . "\n";
    foreach $lun ($netapp->luns) {
        print "Lun " . $lun->path . "\n";
    }

    print "Aggregates " . $netapp->aggregates . "\n";
    foreach $aggr ($netapp->aggregates) {
        print "Aggregate " . $aggr->name . "\n";
    }

    print "Volumes " . $netapp->volumes . "\n";
    foreach $vol ($netapp->volumes) {
        print "Volume " . $vol->name . " " . $vol->size_used . "\n";
    }

    $netapp->lun_create_by_size(path => "/vol/vol0/kiki",
                                size => "2G",
                                type => "linux");

    $netapp->logout();
}

if ($@) {
	my $error = $@;
	print Dumper $error;
};

main();
