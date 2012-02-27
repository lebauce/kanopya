#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/Vlan.t.log', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok ('Administrator');
use_ok ('Entity::Vlan');

eval {
#    BEGIN { $ENV{DBIC_TRACE} = 1 }
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    
    throws_ok { 
		Entity::Vlan->new(
		    vlan_name	      => '*',
		    vlan_desc       => 'toto',
		    vlan_number       => 1,    
		)
	} 
		'Kanopya::Exception::Internal::WrongValue',
		'bad attribute value';

    throws_ok { 
		Entity::Vlan->new(
		    # vlan_name	      => 'toto',
		    vlan_desc       => 'toto',
		    vlan_number       => 1,    
		)
	} 
		'Kanopya::Exception::Internal::IncorrectParam',
		'missing mandatory attribute';

	my $vlan = Entity::Vlan->new(
		    Vlan_name	      => 'vlan0',
		    Vlan_desc       => 'premier vlan',
		    Vlan_number       => '1',
	);
		
	isa_ok($vlan, "Entity::Vlan", 'Entity::Vlan instanciation');

	my $vlan_id = $vlan->getAttr(name=>'vlan_id');

	my $samevlan = Entity::Vlan->get(id => $vlan_id);

	is  ($vlan, $samevlan, 'get vlan ip via id');

	my $vlan_number = $vlan->getAttr(name=>'vlan_number');
	is  ($vlan_number, 1, 'getAttr vlan numbers');

};

if($@) {
	my $error = $@;
	print Dumper $error;
};

