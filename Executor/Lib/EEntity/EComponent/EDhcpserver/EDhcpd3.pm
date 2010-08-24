package EEntity::EComponent::EDhcpserver::EDhcpd3;

use strict;

use base "EEntity::EComponent::EDhcpserver";
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

sub addHost {
	my $self = shift;
    my %args = @_;
	
	if ((! exists $args{dhcpd3_subnet_id} or ! defined $args{dhcpd3_subnet_id}) ||
		(! exists $args{dhcpd3_hosts_ipaddr} or ! defined $args{dhcpd3_hosts_ipaddr}) ||
		(! exists $args{dhcpd3_hosts_mac_address} or ! defined $args{dhcpd3_hosts_mac_address}) ||
		(! exists $args{dhcpd3_hosts_hostname} or ! defined $args{dhcpd3_hosts_hostname}) ||
		(! exists $args{kernel_id} or ! defined $args{kernel_id})) {
		$errmsg = "EComponent::EDhcpserver::EDhcpd3->addHost needs a dhcpd3_subnet_id, dhcpd3_hosts_ipaddr, dhcpd3_hostst_mac_add, dhcpd3_hosts_hostname and kernel_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#TODO Apply configuration on dhcp server
	return $self->_getEntity()->addHost(%args);
}

sub reload {
	#TODO Reloadconf on edhcp
	return 	undef;
}

sub removeHost {
	my $self = shift;
    my %args = @_;
	
	if ((! exists $args{dhcpd3_subnet_id} or ! defined $args{dhcpd3_subnet_id}) ||
		(! exists $args{dhcpd3_hosts_id} or ! defined $args{dhcpd3_hosts_id})) {
		$errmsg = "EComponent::EDhcpserver::EDhcpd3->removeHost needs a dhcpd3_subnet_id, dhcpd3_hosts_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#TODO Apply configuration on dhcp server
	return $self->_getEntity()->removeHost(%args);
}
1;
