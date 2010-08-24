package Entity::Component::Dhcpserver::Dhcpd3;
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use Log::Log4perl "get_logger";
use Data::Dumper;
use strict;
use McsExceptions;

use strict;

use base "Entity::Component::Dhcpserver";

my $log = get_logger("administrator");
my $errmsg;
# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getInternalSubNet{
	#TODO getInternalSubNet in dhcpd3 component
	return 1;
}

sub addHost {
	my $self = shift;
    my %args = @_;
	
	if ((! exists $args{dhcpd3_subnet_id} or ! defined $args{dhcpd3_subnet_id}) ||
		(! exists $args{dhcpd3_hosts_ipaddr} or ! defined $args{dhcpd3_hosts_ipaddr}) ||
		(! exists $args{dhcpd3_hosts_mac_address} or ! defined $args{dhcpd3_hosts_mac_address}) ||
		(! exists $args{dhcpd3_hosts_hostname} or ! defined $args{dhcpd3_hosts_hostname}) ||
		(! exists $args{kernel_id} or ! defined $args{kernel_id})) {
		$errmsg = "Component::Dhcpserver::Dhcpd3->addHost needs a dhcpd3_subnet_id, dhcpd3_hosts_ipaddr, dhcpd3_hostst_mac_add, dhcpd3_hosts_hostname and kernel_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $dhcpd3_hosts_rs = $self->{_dbix}->dhcpd3s->first()->dhcpd3_subnets->find($args{dhcpd3_subnet_id})->dhcpd3_hosts;

	my $res = $dhcpd3_hosts_rs->create(\%args);
	return $res->get_column('dhcpd3_hosts_id');
}

sub getHostId {
	my $self = shift;
    my %args = @_;
	
	if ((! exists $args{dhcpd3_subnet_id} or ! defined $args{dhcpd3_subnet_id}) ||
		(! exists $args{dhcpd3_hosts_mac_address} or ! defined $args{dhcpd3_hosts_mac_address})) {
		$errmsg = "Component::Dhcpserver::Dhcpd3->getHostId needs a dhcpd3_subnet_id and a dhcpd3_hostst_mac_add named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->dhcpd3s->first()->dhcpd3_subnets->find($args{dhcpd3_subnet_id})->dhcpd3_hosts->first({ dhcpd3_hosts_mac_address=> $args{dhcpd3_hosts_mac_address}})->get_column('dhcpd3_hosts_id');
	
}

sub removeHost{
	my $self = shift;
    my %args = @_;
	
	if ((! exists $args{dhcpd3_subnet_id} or ! defined $args{dhcpd3_subnet_id}) ||
		(! exists $args{dhcpd3_hosts_id} or ! defined $args{dhcpd3_hosts_id})) {
		$errmsg = "Component::Dhcpserver::Dhcpd3->removeId needs a dhcpd3_subnet_id and a dhcpd3_hosts_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->dhcpd3s->first()->dhcpd3_subnets->find($args{dhcpd3_subnet_id})->dhcpd3_hosts->find( $args{dhcpd3_hosts_id})->delete();
}
1;
