package EEntity::EComponent::ELibrary::EPhp5;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::ELibrary";
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
		$errmsg = "EComponent::EMonitoragent::EPhp5->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Generation of php.ini
	my $conf = $self->_getEntity()->getConf();
	my $data = { 
				session_handler => $conf->{php5_session_handler},
				session_path => $conf->{php5_session_path},
				};
	$self->generateFile( econtext => $args{econtext}, econtext => $args{mount_point},
						 input_file => "php.ini.tt", output => "/php5/apache2/php.ini", data => $data);
}

sub addNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::ELibrary::EPhp5->addNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$self->configureNode(%args);

}

# Reload process
sub reload {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::ELibrary::EPhp5->reload needs an econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}


}

1;
