#!/usr/bin/perl
use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib /workspace/mcs/Executor/Lib);

#Log::Log4perl->init('../Conf/log.conf');
#my $log = get_logger("executor");
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});



my $admtest = "AdminTest";
my $exectest = "ExecTest";

note("Use Tests");
use_ok(Administrator);
use_ok(Executor);
use_ok(McsExceptions);

note("Load Administrator tests");
my %args = (login =>'xebech', password => 'pass');

my $addmotherboard_op;

my $adm = Administrator->new( %args);
eval {
#	$adm->{db}->txn_begin;
		
	note("Add Motherboard");	
	$adm->newOp(type => "AddMotherboard", priority => '100', params => { 
		motherboard_mac_address => '70:71:bc:6c:2d:b1', 
		kernel_id => 5, 
		motherboard_serial_number => "Test sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:2d:e9', 
		kernel_id => 5, 
		motherboard_serial_number => "Test2 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:4a:fd', 
		kernel_id => 5, 
		motherboard_serial_number => "Test3 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:31:d4', 
		kernel_id => 5, 
		motherboard_serial_number => "Test4 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:2d:20', 
		kernel_id => 5, 
		motherboard_serial_number => "Test5 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:56:9f', 
		kernel_id => 5, 
		motherboard_serial_number => "Test6 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:2c:82', 
		kernel_id => 5, 
		motherboard_serial_number => "Test7 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:49:89', 
		kernel_id => 5, 
		motherboard_serial_number => "Test8 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:dc:6c:4a:a0', 
		kernel_id => 5, 
		motherboard_serial_number => "Test9 sn",
		motherboardmodel_id => 1,
		processormodel_id => 1});
	
	#BEGIN { $ENV{DBIC_TRACE} = 1 }
	
};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Mcs::Exception')) 
   	{
		print "Mcs Exception\n";
   }
#	$adm->{db}->txn_rollback;
}


#pass($exectest);
#fail($admtest);


