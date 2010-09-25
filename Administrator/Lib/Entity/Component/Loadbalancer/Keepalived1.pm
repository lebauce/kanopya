package Entity::Component::Loadbalancer::Keepalived1;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use Log::Log4perl "get_logger";
use Data::Dumper;
use strict;
use McsExceptions;

use base "Entity::Component::Loadbalancer";

my $log = get_logger("administrator");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new( %args );
    return $self;
}

=head2 getVirtualservers
	
	Desc : return virtualservers list .
		
	return : array ref containing hasf ref virtualservers 

=cut

sub getVirtualservers {
	my $self = shift;
		
	my $virtualserver_rs = $self->{_dbix}->keepalived1s->first()->keepalived1_virtualservers->search();
	my $result = [];
	while(my $vs = $virtualserver_rs->next) {
		my $hashvs = {};
		$hashvs->{virtualserver_id} = $vs->get_column('virtualserver_id');
		$hashvs->{virtualserver_ip} = $vs->get_column('virtualserver_ip');
		$hashvs->{virtualserver_port} = $vs->get_column('virtualserver_port');
		$hashvs->{virtualserver_lbalgo} = $vs->get_column('virtualserver_lbalgo');
		$hashvs->{virtualserver_lbkind} = $vs->get_column('virtualserver_lbkind');
		push @$result, $hashvs;
	}
	return $result;
}

=head2 getRealserverId  

	Desc : This method return realserver id given a virtualserver_id and a realserver_ip
	args: virtualserver_id, realserver_ip
		
	return : realserver_id

=cut

sub getRealserverId {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{realserver_ip} or ! defined $args{realserver_ip}) ||
		(! exists $args{virtualserver_id} or ! defined $args{virtualserver_id})){
		$errmsg = "Component::Loadbalancer::Keepalived1->addVirtualserver needs a virtualserver_id and a realserver_ip named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $virtualserver = $self->{_dbix}->keepalived1s->first()->keepalived1_virtualservers->find($args{virtualserver_id});
	my $realserver = $virtualserver->keepalived1_realservers->search({ realserver_ip => $args{realserver_ip} })->single;
	return $realserver->get_column('realserver_id');
}

=head2 addVirtualserver
	
	Desc : This method add a new virtual server entry into keepalived configuration.
	args: virtualserver_ip, virtualserver_port, virtualserver_lbkind, virtualserver_lbalgo
		
	return : virtualserver_id added

=cut

sub addVirtualserver {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{virtualserver_ip} or ! defined $args{virtualserver_ip}) ||
		(! exists $args{virtualserver_port} or ! defined $args{virtualserver_port}) ||
		(! exists $args{virtualserver_lbkind} or ! defined $args{virtualserver_lbkind}) ||
		(! exists $args{virtualserver_lbalgo} or ! defined $args{virtualserver_lbalgo})) {
		$errmsg = "Component::Loadbalancer::Keepalived1->addVirtualserver needs a ... named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $virtualserver_rs = $self->{_dbix}->keepalived1s->first()->keepalived1_virtualservers;
	my $row = $virtualserver_rs->create(\%args);
	$log->info("New virtualserver added with ip $args{virtualserver_ip} and port $args{virtualserver_port}");
	return $row->get_column("virtualserver_id");
}

=head2 addRealserver
	
	Desc : This function add a new real server associated a virtualserver.
	args: virtualserver_id, realserver_ip, realserver_port,realserver_checkport , 
		realserver_checktimeout, realserver_weight 
	
	return :  realserver_id

=cut

sub addRealserver {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{virtualserver_id} or ! defined $args{virtualserver_id}) ||
		(! exists $args{realserver_ip} or ! defined $args{realserver_ip}) ||
		(! exists $args{realserver_port} or ! defined $args{realserver_port}) ||
		(! exists $args{realserver_checkport} or ! defined $args{realserver_checkport}) ||
		(! exists $args{realserver_checktimeout} or ! defined $args{realserver_checktimeout}) ||
		(! exists $args{realserver_weight} or ! defined $args{realserver_weight})) {
			$errmsg = "Component::Loadbalancer::Keepalived1->addRealserver needs a ... named argument!";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$log->debug("New real server try to be added on virtualserver_id $args{virtualserver_id}");
	my $realserver_rs = $self->{_dbix}->keepalived1s->first()->keepalived1_virtualservers->find($args{virtualserver_id})->keepalived1_realservers;

	my $row = $realserver_rs->create(\%args);
	$log->info("New real server <$args{realserver_ip}> <$args{realserver_port}> added");
	return $row->get_column('realserver_id');
}

=head2 removeVirtualserver
	
	Desc : This function a delete virtual server and all real servers associated.
	args: virtualserver_id
		
	return : ?

=cut

sub removeVirtualserver {
	my $self = shift;
	my %args  = @_;	
	if (! exists $args{virtualserver_id} or ! defined $args{virtualserver_id}) {
		$errmsg = "Component::Loadbalancer::Keepalived1->removeVirtualserver needs a virtualserver_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->keepalived1s->first()->keepalived1_virtualservers->find($args{virtualserver_id})->delete;
}

=head2 removeRealserver
	
	Desc : This function remove a real server from a virtualserver.
	args: virtualserver_id, realserver_id
		
	return : 

=cut

sub removeRealserver {
	my $self = shift;
	my %args  = @_;
	if ((! exists $args{virtualserver_id} or ! defined $args{virtualserver_id})||
		(! exists $args{realserver_id} or ! defined $args{realserver_id})) {
		$errmsg = "Component::Loadbalancer::Keepalived1->removeRealserver needs a virtualserver_id and a realserver_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->keepalived1s->first()->keepalived1_virtualservers->find($args{virtualserver_id})->keepalived1_realservers->find($args{realserver_id})->delete;
}




# return a data structure to pass to the template processor for ipvsadm file
sub getTemplateDataIpvsadm {
	my $self = shift;
	my $data = {};
	my $keepalived = $self->{_dbix}->keepalived1s->first();
	$data->{daemon_method} = $keepalived->get_column('daemon_method');
	$data->{iface} = $keepalived->get_column('iface');
	return $data;	  
}

# return a data structure to pass to the template processor for keepalived.conf file 
sub getTemplateDataKeepalived {
	my $self = shift;
	my $data = {};
	my $keepalived = $self->{_dbix}->keepalived1s->first();
	$data->{notification_email} = $keepalived->get_column('notification_email');
	$data->{notification_email_from} = $keepalived->get_column('notification_email_from');
	$data->{smtp_server} = $keepalived->get_column('smtp_server');
	$data->{smtp_connect_timeout} = $keepalived->get_column('smtp_connect_timeout');
	$data->{lvs_id} = $keepalived->get_column('lvs_id');
	$data->{virtualservers} = [];
	my $virtualservers = $keepalived->keepalived1_virtualservers;
	
	while (my $vs = $virtualservers->next) {
		my $record = {};
		$record->{ip} = $vs->get_column('virtualserver_ip');
		$record->{port} = $vs->get_column('virtualserver_port');
		$record->{lb_algo} = $vs->get_column('virtualserver_lbalgo');
		$record->{lb_kind} = $vs->get_column('virtualserver_lbkind');
			
		$record->{realservers} = [];
		
		my $realservers = $vs->keepalived1_realservers->search();
		while(my $rs = $realservers->next) {
			push @{$record->{realservers}}, { 
				ip => $rs->get_column('realserver_ip'),
				port => $rs->get_column('realserver_port'),
				weight => $rs->get_column('realserver_weight'),
				check_port => $rs->get_column('realserver_checkport'),
				check_timeout => $rs->get_column('realserver_checktimeout'),
			}; 
		}
		push @{$data->{virtualservers}}, $record;
	}
	return $data;	  
}
1;
