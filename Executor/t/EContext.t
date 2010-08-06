use Test::More 'no_plan';
use lib "../Lib", "../../Common/Lib" ;
use McsExceptions;
use Log::Log4perl qw(:easy);
use Data::Dumper;

Log::Log4perl->easy_init({level=>'ERROR', file=>'STDOUT', layout=>'%F %L %p %m%n'});

###################################################################################
#
# To test EContext::SSH class, you must use a public key with no passphrase 
# The host you contact must have your public key in the .ssh/authorized_keys file of this host
# 
#################################################################################

my $hosttocontact = '10.0.0.1';
my $hostnametocontact = 'node001'; # expected result of hostname command on $hosttocontact

use_ok(EFactory);

note("\nExceptions Test");
eval { my $context = EFactory::newEContext(); };
if($@) {
	is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception: $@");
}

eval { my $context = EFactory::newEContext(ip_source => undef); };
if($@) {
	is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception: $@");
}

eval { my $context = EFactory::newEContext(ip_destination => undef); };
if($@) {
	is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception: $@");
}

note("\nEContext::Local Instanciation");
my $context1 = EFactory::newEContext(ip_source => '123.123.123.123', ip_destination => '123.123.123.123'); 
isa_ok( $context1, "EContext::Local", '$context1');

my $context2 = EFactory::newEContext(ip_source => '13.13.13.13', ip_destination => '13.13.13.13'); 
isa_ok( $context2, "EContext::Local", '$context2');

is($context2, $context1, '$context1 and $context2 are same instance');


note("\nEContext::SSH Instanciation");
my $context3 = EFactory::newEContext(ip_source => '123.123.123.123', ip_destination => $hosttocontact); 
isa_ok( $context3, "EContext::SSH", '$context3');

my $context4 = EFactory::newEContext(ip_source => '123.123.123.123', ip_destination => $hosttocontact); 
isa_ok( $context4, "EContext::SSH", '$context4');

is($context3, $context4, '$context3 and $context4 are same instance');

note("\nEContext::SSH execution");
eval {	
	my $result1 = $context3->execute(command => 'hostname');
	is($result1->{stdout}, $hostnametocontact, "STDOUT of hostname command for $hosttocontact is $hostnametocontact");
	is($result1->{stderr}, '', "no STDERR for hostname command");
		
	my $result2 = $context4->execute(command => 'cat unexistantfile');
	is($result2->{stdout}, '', 'no STDOUT for command: cat unexistantfile');
	is($result2->{stderr}, 'cat: unexistantfile: No such file or directory', 'STDERR is cat: unexistantfile: No such file or directory');
};

if($@) {
	print $@, "\n";
}





