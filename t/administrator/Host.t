#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
Administrator::authenticate(login => 'admin', password => 'K4n0pY4');

my $adm = Administrator->new();

my $entity_attrs = {};
my $host_attrs = {
	kernel_id 		   => 1,
	host_serial_number => '',
	active             => 0,
	host_mac_address   => '00:00:00:00:00:01',
	host_state         => 'down', 	
	parent 			   => $entity_attrs,
};
my $subhost_attrs = {
	subhost_attr => 'une super valeur',
	parent       => $host_attrs,
};



my $rs = $adm->{db}->resultset('Subhost')->new($subhost_attrs); 
	
print $rs->get_column('subhost_attr')."\n";
print $rs->parent->get_column('host_mac_address')."\n";


print "here we save in database\n";
$rs->insert;
print $rs->id."\n";




