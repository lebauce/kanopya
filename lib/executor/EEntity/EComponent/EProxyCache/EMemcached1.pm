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

	#TODO insert configuration files generation

}

sub addNode {
	my $self = shift;
	my %args = @_;

	my $masternodeip = $args{cluster}->getMasterNodeIp();
	
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
