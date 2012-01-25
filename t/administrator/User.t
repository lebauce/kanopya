#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok('Executor');
use_ok ('Administrator');
use_ok('Entity::User');

eval {
#    BEGIN { $ENV{DBIC_TRACE} = 1 }
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    # Test bad structure host
    note("Test Instanciation Error");
    
    throws_ok { 
		Entity::User->new(
		    user_login	      => 'toto',
		    user_password     => 'toto',
		    user_desc         => 'one user',
		    user_firstname    => 'toto',
		    user_lastname     => 'toto',
		    user_email        => 'toto',
		    
		)
	} 
		'Kanopya::Exception::Internal::WrongValue',
		'bad attribute value';

    throws_ok { 
		Entity::User->new(
		    #user_login	      => 'toto',
		    user_password     => 'toto',
		    user_desc         => 'one user',
		    user_firstname    => 'toto',
		    user_lastname     => 'toto',
		    user_email        => 'toto.toto@toto.to',
		    )
		} 
		'Kanopya::Exception::Internal::IncorrectParam',
		'missing mandatory attribute';

	my $user = Entity::User->new(
		user_login	      => 'toto',
		user_password     => 'toto',
		user_desc         => 'one user',
		user_firstname    => 'toto',
		user_lastname     => 'toto',
		user_email        => 'toto.toto@toto.to',
	);
		
	isa_ok($user, "Entity::User", 'Entity::User instanciation');

	my $user_login = $user->getAttr(name=>'user_login');
	is  ($user_login, 'toto', 'getAttr user_login');

	my $user_lastaccess = $user->getAttr(name=>'user_lastaccess');
	is  ($user_lastaccess, undef, 'getAttr undef user_lastaccess');

	#lives_ok { $host->create(); } 'AddHost operation enqueue';

	#lives_ok { $executor->execnround(run => 1); } 'AddHost operation execution succeed';
};

if($@) {
	my $error = $@;
	print Dumper $error;
};

