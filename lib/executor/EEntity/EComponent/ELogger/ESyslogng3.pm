package EEntity::EComponent::ELogger::ESyslogng3;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::ELogger";
use Log::Log4perl "get_logger";

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
		$errmsg = "EComponent::EMonitoragent::ESyslogng3->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $template_path = $args{template_path} || "/templates/components/syslogng";
	
	my $data = $self->_getEntity()->getConf();
		
	$self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
						 template_dir => $template_path,
						 input_file => "syslog-ng.conf.tt", output => "/syslog-ng/syslog-ng.conf",
						 data => $data);
	
}

sub addNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::EMonitoragent::ESyslogng3->addNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$self->configureNode(%args);
		
	# add init scripts
	$self->addInitScripts(
		etc_mountpoint => $args{mount_point},
		econtext => $args{econtext},
		scriptname => 'syslog-ng',
		startvalue => 10,
		stopvalue => 90
	);
	 	 
}

# Reload process
sub reload {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::ELooger::ESyslogng3->reload needs an econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "invoke-rc.d syslog-ng restart";
	my $result = $args{econtext}->execute(command => $command);
	return undef;
}

1;
