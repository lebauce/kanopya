#!/usr/bin/perl -w

use Data::Dumper;
use Entity::Host::Subhost;
use Administrator;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

Administrator::authenticate(login => 'admin', password => 'K4n0pY4');

my @new_hosts = (
	{ host_mac_address => '00:00:00:00:00:10',
	  kernel_id        => 1,
	  host_serial_number => '10',
	  active => 0,
	  host_state => 'down:'.time()
	 },
	{ host_mac_address => '00:00:00:00:00:11',
	  kernel_id        => 1,
	  host_serial_number => '11',
	  active => 0,
	  host_state => 'down:'.time()
	 },
	{ host_mac_address => '00:00:00:00:00:12',
	  kernel_id        => 1,
	  host_serial_number => '12',
	  active => 0,
	  host_state => 'down:'.time()
	 }
);

#~ for my $attributes (@new_hosts) {
	#~ my $host = Entity::Host->new(%$attributes);
	#~ $host->setAttr(name => 'host_core', value => 2);
	#~ $host->setAttr(name => 'host_ram', value => 20000000000);
	#~ $host->save(); 
#~ }

my @hosts = Entity::Host->getHosts(hash => {});

my $value;

for(@hosts) {
	print $_->getAttr(name => 'host_mac_address')."\n";
	$_->setAttr(name => 'host_mac_address', value => $value);
}
