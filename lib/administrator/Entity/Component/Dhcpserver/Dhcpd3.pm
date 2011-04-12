# Dhcp3.pm - Dhcp 3 server component (Adminstrator side)
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 2 august 2010

=head1 NAME

<Entity::Component::Dhcpserver::Dhcpd3> <Dhcpd3 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Dhcpserver::Dhcpd3> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Dhcpserver::Dhcpd3>;

my $component_instance_id = 2; # component instance id

Entity::Component::Dhcpserver::Dhcpd3->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Dhcpserver::Dhcpd3->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Dhcpserver::Dhcpd3 is class allowing to instantiate an Dhcpd3 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Dhcpserver::Dhcpd3;
use parent "Entity::Component::Dhcpserver";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;
# contructor

=head2 get
B<Class>   : Public
B<Desc>    : This method allows to get an existing Dhcpd3 component.
B<args>    : 
    B<component_instance_id> : I<Int> : identify component instance 
B<Return>  : a new Entity::Component::Dhcpserver::Dhcpd3 from Kanopya Database
B<Comment>  : To modify configuration use concrete class dedicated method
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
	
=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Component::Dhcpserver::Dhcpd3->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args, table=>"ComponentInstance");
   return $self;
}

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of Dhcpd server component and concretly Dhcp3.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::Dhcpserver::Dhcpd3 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
	
=cut

sub new {
	my $class = shift;
    my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id})||
		(! exists $args{component_id} or ! defined $args{component_id})){ 
		$errmsg = "Entity::Component::Dhcpserver::Dhcpd3->new need a cluster_id and a component_id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# We create a new DBIx containing new entity
	my $self = $class->SUPER::new( %args);

    return $self;

}

=head2 getInternalSubNet
B<Class>   : Public
B<Desc>    : This method return internal network subnet id
B<args>    : None
B<Return>  : String : internal network subnet id
B<Comment>  : TO Change when kanopya will manage different internal network
	Or when component dhcp will be a available to be installed on a cluster
	Before internal ip will be the first entry in dhcp component
B<throws>  : None  	
=cut

sub getInternalSubNet{
	#TO Change when kanopya will manage different internal network
	# Or when component dhcp will be a available to be installed on a cluster
	# Before internal ip will be the first entry in dhcp component
	return 1;
}

=head2 getConf
B<Class>   : Public
B<Desc>    : This method returns a structure to pass to the template processor 
B<args>    : None
B<Return>  : hashref : dhcpd configuration :
    B<domain_name> : String : domain name
    B<domain_name_server> : String : domain name server ip
    B<servername> : String : dhcpd server name
    B<server_ip> : String : dhcpd server ip
    B<subnet> : hash ref containing
        B<net> : String : network address of the subnet entry
        B<mask> : String : network mask of the subnet entry
        B<nodes> : table ref containing nodes (which are hash table) :
            B<ip_address> : String : Node ip address\
            B<mac_address> : String : Node mac address
            B<hostname> : String : Node hostname
            B<kernel_version> : String : Node kernel version
B<Comment>  : TO Change when kanopya will manage different internal network
	Or when component dhcp will be a available to be installed on a cluster
	Before internal ip will be the first entry in dhcp component
B<throws>  : None  	
=cut

# return a data structure to pass to the template processor 
sub getConf {
	my $self = shift;
	my $cluster = $self->{_dbix}->cluster;
	my $dhcpd3 =  $self->{_dbix}->dhcpd3s->first();
	my $data = {};
	$data->{domain_name} = $dhcpd3->get_column('dhcpd3_domain_name');
	$data->{domain_name_server} = $dhcpd3->get_column('dhcpd3_domain_server');
	$data->{server_name} =  $dhcpd3->get_column('dhcpd3_servername');;
	$data->{server_ip} = $cluster->search_related("nodes", { master_node => 1 })->single->motherboard->get_column('motherboard_internal_ip');
	
	my $subnets = $dhcpd3->dhcpd3_subnets;
	my @data_subnets = ();
	while(my $subnet = $subnets->next) {
		my $hosts = $subnet->dhcpd3_hosts;
		my @data_hosts = ();
		while(my $host = $hosts->next) {
        my $motherboard = Motherboard::getMotherboardFromIP(ipv4_internal_ip => $host->get_column('dhcpd3_hosts_ipaddr'));
			push @data_hosts, {
			    #########################
			    #TODO search node from their ip.
				ip_address => $host->get_column('dhcpd3_hosts_ipaddr'), 
				mac_address => $host->get_column('dhcpd3_hosts_mac_address'), 
				hostname => $host->get_column('dhcpd3_hosts_hostname'), 
				kernel_version => $host->kernel->get_column('kernel_version')
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

=head2 addHost
B<Class>   : Public
B<Desc>    : This method returns a structure to pass to the template processor 
B<args>    : 
    B<dhcpd3_subnet_id> : Int : Subnet identifier
    B<dhcpd3_hosts_ipaddr> : String : New host ip address
    B<dhcpd3_hosts_mac_address> : String : New host mac address
    B<dhcpd3_hosts_hostname> : String : New host hostname
    B<kernel_id> : Int : New host kernel id
B<Return>  : Int : New host id
B<Comment>  : None
B<throws>  : 
Kanopya::Exception::Internal::IncorrectParam thrown when args missed  	
=cut

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
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $dhcpd3_hosts_rs = $self->{_dbix}->dhcpd3s->first()->dhcpd3_subnets->find($args{dhcpd3_subnet_id})->dhcpd3_hosts;

	my $res = $dhcpd3_hosts_rs->create(\%args);
	return $res->get_column('dhcpd3_hosts_id');
}

=head2 getHostId
B<Class>   : Public
B<Desc>    : This method returns host id in dhcpd component instance 
B<args>    : 
    B<dhcpd3_subnet_id> : Int : Subnet identifier
    B<dhcpd3_hosts_mac_address> : String : host mac address
B<Return>  : Int : host id
B<Comment>  : None
B<throws>  : 
Kanopya::Exception::Internal::IncorrectParam thrown when args missed  	
=cut

sub getHostId {
	my $self = shift;
    my %args = @_;
	
	if ((! exists $args{dhcpd3_subnet_id} or ! defined $args{dhcpd3_subnet_id}) ||
		(! exists $args{dhcpd3_hosts_mac_address} or ! defined $args{dhcpd3_hosts_mac_address})) {
		$errmsg = "Component::Dhcpserver::Dhcpd3->getHostId needs a dhcpd3_subnet_id and a dhcpd3_hostst_mac_add named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->dhcpd3s->first()->dhcpd3_subnets->find($args{dhcpd3_subnet_id})->dhcpd3_hosts->search({ dhcpd3_hosts_mac_address=> $args{dhcpd3_hosts_mac_address}})->first()->get_column('dhcpd3_hosts_id');
	
}

=head2 removeHost
B<Class>   : Public
B<Desc>    : This method remove a host from dhcpd component configuration
B<args>    : 
    B<dhcpd3_subnet_id> : Int : Subnet identifier
    B<dhcpd3_hosts_id> : Int : host identifier
B<Return>  : None
B<Comment>  : None
B<throws>  : 
Kanopya::Exception::Internal::IncorrectParam thrown when args missed  	
=cut

sub removeHost{
	my $self = shift;
    my %args = @_;
	
	if ((! exists $args{dhcpd3_subnet_id} or ! defined $args{dhcpd3_subnet_id}) ||
		(! exists $args{dhcpd3_hosts_id} or ! defined $args{dhcpd3_hosts_id})) {
		$errmsg = "Component::Dhcpserver::Dhcpd3->removeId needs a dhcpd3_subnet_id and a dhcpd3_hosts_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->dhcpd3s->first()->dhcpd3_subnets->find($args{dhcpd3_subnet_id})->dhcpd3_hosts->find( $args{dhcpd3_hosts_id})->delete();
}

=head2 getNetConf
B<Class>   : Public
B<Desc>    : This method return component network configuration in a hash ref, it's indexed by port and value is the port
B<args>    : None
B<Return>  : hash ref containing network configuration with following format : {port => protocol}
B<Comment>  : None
B<throws>  : Nothing
=cut

sub getNetConf {
    return {67=> 'udp'};
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
