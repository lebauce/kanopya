package EEntity::EComponent::EProxyCache::EMemcached1;

use strict;
use Template;
use base "EEntity::EComponent::EProxyCache";
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

	# Generation of memcached.conf
	my $data = { 
				connection_port => $conf->{memcached1_port},
				listening_address => $args{motherboard}->getInternalIP()->{ipv4_internal_address},
				};
	$self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
						 template_dir => "/templates/components/memcached",
						 input_file => "memcached.conf.tt", output => "/memcached.conf", data => $data);

}

sub addNode {
	my $self = shift;
	my %args = @_;

	my $masternodeip = $args{cluster}->getMasterNodeIp();
	
	# Memcached run only on master node
	if(not defined $masternodeip) {
		# no masternode defined, this motherboard becomes the masternode
			
		$self->configureNode(%args);
		
		$self->addInitScripts(	etc_mountpoint => $args{mount_point}, 
								econtext => $args{econtext}, 
								scriptname => 'memcached', 
								startvalue => 20, 
								stopvalue => 20);
	}

}


1;
