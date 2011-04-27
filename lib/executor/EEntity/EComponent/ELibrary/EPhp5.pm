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

	my $conf = $self->_getEntity()->getConf();

	# Generation of php.ini
	my $data = { 
				session_handler => $conf->{php5_session_handler},
				session_path => $conf->{php5_session_path},
				};
	if ( $data->{session_handler} eq "memcache" ) { # This handler needs specific configuration (depending on master node)
		my $masternodeip = $args{cluster}->getMasterNodeIp();
		my $ip = (not defined $masternodeip) ? "127.0.0.1" : $masternodeip;
		my $port = '11211'; # default port of memcached
		$data->{session_path} = "tcp://$ip:$port";
	}
	$self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
						 template_dir => "/templates/components/php5",
						 input_file => "php.ini.tt", output => "/php5/apache2/php.ini", data => $data);
}

sub addNode {
	my $self = shift;
	my %args = @_;
		
	$self->configureNode(%args);
}


1;
