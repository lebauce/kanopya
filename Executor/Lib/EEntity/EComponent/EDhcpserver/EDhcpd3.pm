package EEntity::EComponent::EDhcpserver::EDhcpd3;

use strict;
use Template;
use String::Random;
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

# generate edhcpd configuration files
sub generate {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EDhcpserver::EDhcpd3->generate needs an econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $config = {
    INCLUDE_PATH => $self->_getEntity()->getTemplateDirectory(),
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 0,               # cleanup whitespace 
    EVAL_PERL    => 1,               # evaluate Perl code blocks
    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");
	# create Template object
	my $template = Template->new($config);
    my $input = "dhcpd.conf.tt";
    my $data = $self->_getEntity()->getTemplateData();
	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EDhcpserver::EDhcpd3->generate : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/dhcp3/dhcpd.conf");	
		 	 
}

# Reload conf on edhcp
sub reload {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EDhcpserver::EDhcpd3->reload needs an econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "invoke-rc.d dhcp3-server restart";
	my $result = $args{econtext}->execute(command => $command);
	return 	undef;
}
1;
