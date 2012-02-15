#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/Poolip.t.log', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok ('Administrator');
use_ok('Entity::Poolip');

eval {
#    BEGIN { $ENV{DBIC_TRACE} = 1 }
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    
    throws_ok { 
		Entity::Poolip->new(
		    poolip_name	      => 'toto',
		    poolip_desc       => 'toto',
		    poolip_addr       => 'one user',
		    poolip_mask       => 'toto',
		    poolip_netmask    => 'toto',
		    poolip_gateway    => 'toto',
		    
		)
	} 
		'Kanopya::Exception::Internal::WrongValue',
		'bad attribute value';

    throws_ok { 
		Entity::Poolip->new(
		    #poolip_name	      => 'toto',
		    poolip_desc       => 'toto',
		    poolip_addr       => 'one user',
		    poolip_mask       => 'toto',
		    poolip_netmask    => 'toto',
		    poolip_gateway    => 'toto',
		)
	} 
		'Kanopya::Exception::Internal::IncorrectParam',
		'missing mandatory attribute';

	my $poolip = Entity::Poolip->new(
		    poolip_name	      => 'publicpool',
		    poolip_desc       => 'pool',
		    poolip_addr       => '80.120.120.0',
		    poolip_mask       => '24',
		    poolip_netmask    => '255.255.255.0',
		    poolip_gateway    => '80.120.120.254',
	);
		
	isa_ok($poolip, "Entity::Poolip", 'Entity::Poolip instanciation');

	my $poolip_id = $poolip->getAttr(name=>'poolip_id');

	my $samepoolip = Entity::Poolip->get(id => $poolip_id);

	is  ($poolip, $samepoolip, 'get pool ip via id');

	my $poolip_addr = $poolip->getAttr(name=>'poolip_addr');
	is  ($poolip_addr, '80.120.120.0', 'getAttr pool ip addr');

};

if($@) {
	my $error = $@;
	print Dumper $error;
};

