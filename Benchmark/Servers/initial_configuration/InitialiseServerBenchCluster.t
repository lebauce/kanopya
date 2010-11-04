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
		kernel_id => 9, 
		motherboard_serial_number => "No SN11",
		motherboard_powersupply_id => 11,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:56:9f', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN10",
		motherboard_powersupply_id => 10,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:2d:20', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN9",
		motherboard_powersupply_id => 9,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:4a:fd', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN8",
		motherboard_powersupply_id => 8,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '6c:f0:49:95:d8:1b', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN7",
		motherboard_powersupply_id => 7,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
	
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:56:b7', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN6",
		motherboard_powersupply_id => 6,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:2d:e9', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN5",
		motherboard_powersupply_id => 5,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:49:84', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN4",
		motherboard_powersupply_id => 4,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:4a:a0', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN3",
		motherboard_powersupply_id => 3,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:31:d4', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN2 without power controller",
#		motherboard_powersupply_id => 4,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:2c:82', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN1 without power controller",
#		motherboard_powersupply_id => 3,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
	

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


