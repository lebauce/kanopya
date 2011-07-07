#!/usr/bin/perl
use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';

#Log::Log4perl->init('../Conf/log.conf');
#my $log = get_logger("executor");
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});



my $admtest = "AdminTest";
my $exectest = "ExecTest";

note("Use Tests");
use_ok(Administrator);
use_ok(Executor);
use_ok(Kanopya::Exceptions);

note("Load Administrator tests");
my %args = (login =>'admin', password => 'admin');

my $addmotherboard_op;

my $adm = Administrator->new( %args);
eval {
#	$adm->{db}->txn_begin;
		
	note("Add Motherboard");	
	$adm->newOp(type => "AddMotherboard", priority => '100', params => { 
		motherboard_mac_address => '70:71:bc:6c:2d:b1', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN11",
		powersupplyport_number => 11,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:56:9f', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN10",
		powersupplyport_number => 10,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:2d:20', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN9",
		powersupplyport_number => 9,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:4a:fd', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN8",
		powersupplyport_number => 8,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '6c:f0:49:95:d8:1b', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN7",
		powersupplyport_number => 7,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
	
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:56:b7', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN6",
		powersupplyport_number => 6,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:2d:e9', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN5",
		powersupplyport_number => 5,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:49:84', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN4",
		powersupplyport_number => 4,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:4a:a0', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN3",
		powersupplyport_number => 3,
		powersupplycard_id => 1,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});

	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:31:d4', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN2 without power controller",
#		powersupply_id => 4,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
		
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '70:71:bc:6c:2c:82', 
		kernel_id => 9, 
		motherboard_serial_number => "No SN1 without power controller",
#		powersupply_id => 3,
		motherboardmodel_id => 7,
		processormodel_id => 2,
		active => 1
	});
	

	#BEGIN { $ENV{DBIC_TRACE} = 1 }
	
};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Kanopya::Exception')) 
   	{
		print "Kanopya Exception\n";
   }
#	$adm->{db}->txn_rollback;
}


#pass($exectest);
#fail($admtest);


