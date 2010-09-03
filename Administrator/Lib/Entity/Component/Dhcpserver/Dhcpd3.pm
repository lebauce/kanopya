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

# return a data structure to pass to the template processor 
sub getTemplateData {
	my $self = shift;
	my $cluster = $self->{_dbix}->cluster_id;
	my $dhcpd3 =  $self->{_dbix}->dhcpd3s->first();
	my $data = {};
	$data->{domain_name} = $dhcpd3->get_column('dhcpd3_domain_name');
	$data->{domain_name_server} = $dhcpd3->get_column('dhcpd3_domain_server');
	$data->{server_name} =  $dhcpd3->get_column('dhcpd3_servername');;
	$data->{server_ip} = $cluster->search_related("nodes", { master_node => 1 })->single->motherboard_id->get_column('motherboard_internal_ip');
	
	my $subnets = $dhcpd3->dhcpd3_subnets;
	my @data_subnets = ();
	while(my $subnet = $subnets->next) {
		my $hosts = $subnet->dhcpd3_hosts;
		my @data_hosts = ();
		while(my $host = $hosts->next) {
			push @data_hosts, {
				ip_address => $host->get_column('dhcpd3_hosts_ipaddr'), 
				mac_address => $host->get_column('dhcpd3_hosts_mac_address'), 
				hostname => $host->get_column('dhcpd3_hosts_hostname'), 
				kernel_version => $host->kernel_id->get_column('kernel_version')
			};
		}
		push @data_subnets, {
			net => $subnet->get_column('dhcpd3_subnet_net'),
			mask => $subnet->get_column('dhcpd3_subnet_mask'),
			nodes => \@data_hosts
		};
	}

	$data->{subnets} = \@data_subnets;
	return $data;
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
