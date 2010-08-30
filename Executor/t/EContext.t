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

note("\nInstanciation Exceptions Test");
eval { my $context = EFactory::newEContext(); };
if($@) { is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception: $@"); }

eval { my $context = EFactory::newEContext(ip_source => undef); };
if($@) { is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception: $@"); }

eval { my $context = EFactory::newEContext(ip_destination => undef); };
if($@) { is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception: $@"); }

note("\nEContext::Local Instanciation");
my $context1 = EFactory::newEContext(ip_source => '123.123.123.123', ip_destination => '123.123.123.123'); 
isa_ok( $context1, "EContext::Local", '$context1');

my $context2 = EFactory::newEContext(ip_source => '13.13.13.13', ip_destination => '13.13.13.13'); 
isa_ok( $context2, "EContext::Local", '$context2');

is($context2, $context1, '$context1 and $context2 are same instance');

note("\nEContext::Local failed execution Exception");
eval { my $result = $context1->execute(command => "badcommandbadcommand"); };
if($@) { is ($@->isa('Mcs::Exception::Execution'), 1, "get Mcs Exception: $@"); }

note("\nEContext::Local send method");
my $srcfile = '/tmp/srcfile';
my $destfile = '/tmp/destfile';
$context1->execute(command => "touch $srcfile");
$context1->send(src => $srcfile, dest => $destfile);
is( -e $destfile, 1, '$srcfile moved to $destfile with success');

#note("\nEContext::Local send failed ");
#$badsrcfile = '/tmp/unexistentfile';
#$baddestfile = '/tmp/destfile';
#$context1->send(src => $badsrcfile, dest => $baddestfile);
#is( -e $destfile, 1, '$srcfile moved to $destfile with success');


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
};
if($@) { print $@, "\n"; }

note("\nEContext::SSH failed execution Exception");
eval { my $result = $context3->execute(command => "badcommandbadcommand"); };
if($@) { is ($@->isa('Mcs::Exception::Execution'), 1, "get Mcs Exception: $@"); }

note("\nEContext::SSH send method");
# context1 is LOCAL
# context3 is SSH to $hosttocontact
$srcfile = '/tmp/srcfile';
$destfile = '/tmp/destfile';
$context1->execute(command => "touch $srcfile");
eval { $context3->send(src => $srcfile, dest => $destfile); };
if($@) { print $@, "\n"; }



