package EEntity::EComponent::ESystem::EMounttable1;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::ESystem";
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

# generate configuration files on node
sub configureNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{motherboard} or ! defined $args{motherboard}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::EMonitoragent::EMounttable1->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $data = $self->_getEntity()->getConf();
	
	$log->debug(Dumper($args{econtext}));
	$log->debug(Dumper($args{mount_point}));
	
	
	foreach my $row (@{$data->{mountdefs}}) {
		delete $row->{mounttable1_id};
	}
	
	$log->debug(Dumper($data));
						 	
	$self->generateFile(	econtext => $args{econtext}, 
							mount_point => $args{mount_point},
						 	template_dir => "/templates/components/mounttable",
						 	input_file => "fstab.tt", 
						 	output => "/fstab", 
						 	data => $data);
	
	
}

sub addNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::ESystem::EMounttable1->addNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$self->configureNode(%args);
}





1;
