#!/usr/bin/perl -w

use lib </opt/kanopya/lib/*>;

use Test::More 'no_plan';

BEGIN {
      use_ok( 'Administrator' );
      use_ok( 'Entity::Cluster' );
      use_ok( 'Entity::Component::Logger::Syslogng3' );
}

Administrator::authenticate(login => "admin", password => "admin");

# Get admin cluster
my $cluster = Entity::Cluster->get(id => 1);

my $comp = $cluster->getComponent( category => 'Logger', name => 'Syslogng', version => 3 );
#my $comp = Entity::Component::Logger::Syslogng3->get( id => 6 );
isa_ok($comp, "Entity::Component::Logger::Syslogng3", "Retrieve concrete component");


my $new_conf = {
   'source' => {
   	'src_one' => [{ content => "driver1(param1)" }, { content => "driver2(parm1 param2)"}],
	'src_two' => [{ content => "driver1(param1)" }]
   },
   'destination' => {
   	'dest_one' => [{ content => "driver1(param1)" }, { content => "driver2(parm1 param2)"}],
   },
   'log' => [
   	 [ {type =>'source', name => 'src_two'}, {type =>'destination', name => 'dest_one'}],
   	 [ {type =>'source', name => 'src_one'}, {type =>'destination', name => 'dest_one'}],
   ],
};

$comp->setConf( $new_conf );

#my $data = $comp->getConf();

use  EEntity::EComponent::ELogger::ESyslogng3;
use EContext::Local;
my $econtext = EContext::Local->new();
my $ecomp = EEntity::EComponent::ELogger::ESyslogng3->new( data => $comp );

$dest_dir = "/tmp/syslog-ng";
`mkdir $dest_dir` if not -d $dest_dir;

$ecomp->configureNode( econtext => $econtext, mount_point => "/tmp", template_path => ".", motherboard => "" );

use File::Compare;

my $file_compare = File::Compare::compare_text("/tmp/syslog-ng/syslog-ng.conf", "syslog-ng.conf.good");
is( $file_compare, 0, "Good generated file");

