#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use Log::Log4perl qw(:easy);
use Data::Dumper;
use NetApp::Filer;
use Entity::ServiceProvider::Outside::Netapp;
use Entity::Connector::NetappManager;
# use Entity::Connector::CiscoUCS;

Log::Log4perl->easy_init( {
    level => 'DEBUG',
    file => '/tmp/CiscoUCS.t.log',
    layout => '%F %L %p %m%n'}
);

use_ok('Administrator');

Administrator::authenticate(login=>'admin', password=>'K4n0pY4' );

eval {
    print "UCS Service Provider Creation\n";
    print "Administrator instantiation\n";
    my $adm = Administrator->new;
    print "Call create() method\n";
    my $sp = Entity::ServiceProvider::Outside::UnifiedComputingSystem->create(
            ucs_name     => 'AlterWayTest',
            ucs_desc     => 'UCS from test file',
            ucs_addr     => '00.00.00.00',
            ucs_login     => 'test',
            ucs_passwd  => 'testpasswd',
            ucs_dataprovider  => 'test',
            ucs_ou  => 'test',
    );
    print "Call UcsManager->new()\n";
    my $conn = Entity::Connector::UcsManager->new();
    print "Call addConnector method\n";
    $sp->addConnector('connector' => $conn);
};

if ($@) {
    my $error = $@;
    print "$error\n";
};

eval {
    my $ucs = Cisco::UCS->new(
        cluster  => "89.31.149.80",
        port     => 80,
        proto    => "http",
        username => "admin",
        passwd   => "Infidis2011"
    );

    $ucs->login();
    print "Authentication token is " . $ucs->{cookie} . "\n";

    print "Listing all fabric interconnects\n";
    my @interconnects = $ucs->get_interconnects;
    foreach my $ic (@interconnects) {
        print "Interconnect $ic HA status is $ic->{dn}\n";
    }

    print "Listing all blades";
    my @blades = $ucs->get_blades();
    foreach my $blade (@blades) {
        print "Model: $blade->{model}\n";
    }

    print "Listing all service profiles\n";
    my @service_profiles = $ucs->get_service_profiles(dn => "/sn");
    foreach my $service_profile (@service_profiles) {
        print "Service Profile: $service_profile->{name}\n";
    }

    $ucs->logout();
};

if ($@) {
	my $error = $@;
	print "$error\n";
};
