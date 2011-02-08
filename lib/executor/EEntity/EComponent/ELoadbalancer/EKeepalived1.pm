package EEntity::EComponent::ELoadbalancer::EKeepalived1;

use strict;
use Date::Simple (':all');
use Log::Log4perl "get_logger";
use Template;
use String::Random;
use lib qw(/workspace/mcs/Executor/Lib);

use base "EEntity::EComponent::ELoadbalancer";

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

# called when a node is added to a cluster
sub addNode {
	my $self = shift;
	my %args = @_;
	
	my $keepalived = $self->_getEntity();
	my $masternodeip = $args{cluster}->getMasterNodeIp();
	# recuperer les adresses ips publiques et les ports
	
	if(not defined $masternodeip) {
		# no masternode defined, this motherboard becomes the masternode
		#  so it is the first initialization of keepalived
				
		$log->debug("adding virtualserver  definition in database");
		my $vsid1 = $keepalived->addVirtualserver(
			virtualserver_ip => '192.168.100.254/24',
			virtualserver_port => 80,
			virtualserver_lbkind => 'NAT',
			virtualserver_lbalgo => 'wlc');
			
		my $vsid2 = $keepalived->addVirtualserver(
			virtualserver_ip => '192.168.100.254/24',
			virtualserver_port => 443,
			virtualserver_lbkind => 'NAT',
			virtualserver_lbalgo => 'wlc');
		
		$log->debug("adding realserver definition in database");
		 my $rsid1 = $keepalived->addRealserver(
			virtualserver_id => $vsid1,
			realserver_ip => $args{motherboard}->getAttr(name => 'motherboard_internal_ip'),
			realserver_port => 80,
			realserver_checkport => 80,
			realserver_checktimeout => 15,
			realserver_weight => 1);
			
		my $rsid2 = $keepalived->addRealserver(
			virtualserver_id => $vsid2,
			realserver_ip => $args{motherboard}->getAttr(name => 'motherboard_internal_ip'),
			realserver_port => 443,
			realserver_checkport => 443,
			realserver_checktimeout => 15,
			realserver_weight => 1);
	
		$log->debug("generate /etc/default/ipvsadm file");
		$self->generateIpvsadm(econtext => $args{econtext}, mount_point => $args{mount_point});
		$log->debug("generate /etc/keepalived/keepalived.conf file");
		$self->generateKeepalived(econtext => $args{econtext}, mount_point => $args{mount_point});
		
		$self->addInitScripts(	etc_mountpoint => $args{mount_point}, 
								econtext => $args{econtext}, 
								scriptname => 'keepalived', 
								startvalue => 20, 
								stopvalue => 20);
								
		# activating ipv4 forwarding to sysctl
		$log->debug('activating ipv4 forwarding to sysctl.conf');
		my $command = "echo 'net.ipv4.ip_forward=1' >> $args{mount_point}/sysctl.conf";
		$log->debug($command);
		$args{econtext}->execute(command => $command);
	
	} else {
		# a masternode exists so we update his keepalived configuration
		$log->debug("Keepalived update");
		use EFactory;
		my $masternode_econtext = EFactory::newEContext(ip_source => '127.0.0.1', ip_destination => $masternodeip);
		
		# add this motherboard as realserver for each virtualserver of this cluster
		my $virtualservers = $keepalived->getVirtualservers();
		
		foreach my $vs (@$virtualservers) {
			my $rsid = $keepalived->addRealserver(
				virtualserver_id => $vs->{virtualserver_id},
				realserver_ip => $args{motherboard}->getAttr(name => 'motherboard_internal_ip'),
				realserver_port => $vs->{virtualserver_port},
				realserver_checkport => $vs->{virtualserver_port},
				realserver_checktimeout => 15,
				realserver_weight => 2);
		}
		
		$log->debug('Generation of network_routes script');
		$self->addnetwork_routes(mount_point => $args{mount_point},
								econtext => $args{econtext},
								loadbalancer_internal_ip => $masternodeip);
		
		$log->debug('init script generation for network_routes script');
		$self->addInitScripts(	etc_mountpoint => $args{mount_point}, 
								econtext => $args{econtext}, 
								scriptname => 'network_routes', 
								startvalue => 17, 
								stopvalue => 20);
		
#		$self->generateKeepalived(mount_point => '/etc', econtext => $masternode_econtext);
#		$self->reload(econtext => $masternode_econtext);
		
	}
}

# called when a node is removed from a cluster 
sub stopNode {
	my $self = shift;
	my %args = @_;
	
	my $keepalived = $self->_getEntity();
	my $masternodeip = $args{cluster}->getMasterNodeIp();
	if($masternodeip eq $args{motherboard}->getAttr(name => 'motherboard_internal_ip')) {
		# this motherboard is the masternode so we remove virtualserver definitions
		$log->debug('No master node ip retreived, we are stopping the master node');
		my $virtualservers = $keepalived->getVirtualservers();
		foreach my $vs (@$virtualservers) {
			$keepalived->removeVirtualserver(virtualserver_id => $vs->{virtualserver_id});
		}
		
	} else {
		use EFactory;
		my $masternode_econtext = EFactory::newEContext(ip_source => '127.0.0.1', ip_destination => $masternodeip);
		
		# remove this motherboard as realserver for each virtualserver of this cluster
		my $virtualservers = $keepalived->getVirtualservers();
		
		foreach my $vs (@$virtualservers) {
			my $realserver_id = $keepalived->getRealserverId(virtualserver_id => $vs->{virtualserver_id}, realserver_ip => $args{motherboard}->getAttr(name => 'motherboard_internal_ip'));
			
			$keepalived->removeRealserver(
				virtualserver_id => $vs->{virtualserver_id},
				realserver_id => $realserver_id);
		}
		
		$self->generateKeepalived(mount_point => '/etc', econtext => $masternode_econtext);
		$self->reload(econtext => $masternode_econtext);	
	}
	
}


# Reload configuration of keepalived process
sub reload {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::ELoadbalancer::EKeepalived->reload needs an econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "invoke-rc.d keepalived reload";
	my $result = $args{econtext}->execute(command => $command);
	return undef;
}

# generate /etc/keepalived/keepalived.conf configuration file
sub generateKeepalived {
	my $self = shift;
	my %args = @_;
	if((! exists $args{econtext} or ! defined $args{econtext}) || 
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::ELoadbalancer::EKeepalived1->generateKeepalived needs a econtext and mount_point named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $config = {
	    INCLUDE_PATH => '/templates/components/mcskeepalived',
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");
	# create Template object
	my $template = Template->new($config);
    my $input = "keepalived.conf.tt";
    my $data = $self->_getEntity()->getTemplateDataKeepalived();
	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::ELoadbalancer::EKeepalived1->generate : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}."/keepalived/keepalived.conf");	
	unlink "/tmp/$tmpfile";		 	 
}

# generate /etc/default/ipvsadm configuration file for the master node
sub generateIpvsadm {
	my $self = shift;
	my %args = @_;
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})){
		$errmsg = "EComponent::ELoadbalancer::EKeepalived1->generateIpvsadm needs a econtext and mount_point named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $config = {
	    INCLUDE_PATH => '/templates/components/mcskeepalived',
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");
	# create Template object
	my $template = Template->new($config);
    my $input = "default_ipvsadm.tt";
    my $data = $self->_getEntity()->getTemplateDataIpvsadm();
	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::ELoadbalancer::EKeepalived1->generateIpvsadm : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}."/default/ipvsadm");	
	unlink "/tmp/$tmpfile";		
}

# add network_routes script to the node 
sub addnetwork_routes {
	my $self = shift;
	my %args = @_;
	if((! exists $args{econtext} or ! defined $args{econtext}) || 
		(! exists $args{mount_point} or ! defined $args{mount_point}) ||
		(! exists $args{loadbalancer_internal_ip} or ! defined $args{loadbalancer_internal_ip})) {
		$errmsg = "EComponent::ELoadbalancer::EKeepalived1->generateKeepalived needs a econtext, mount_point and loadbalancer_internal_ip named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $config = {
	    INCLUDE_PATH => '/templates/components/mcskeepalived',
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");
	# create Template object
	my $template = Template->new($config);
    my $input = "network_routes.tt";
    my $data = {};
    $data->{gateway} = $args{loadbalancer_internal_ip};
	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::ELoadbalancer::EKeepalived1->addnetwork_routes : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}."/init.d/network_routes");	
	my $command = '/bin/chmod +x '.$args{mount_point}.'/init.d/network_routes';
	$log->debug($command);
	my $result = $args{econtext}->execute(command => $command);
	unlink "/tmp/$tmpfile";		
}

sub postStartNode{
	my $self = shift;
	my %args = @_;
	
	my $keepalived = $self->_getEntity();
	my $masternodeip = $args{cluster}->getMasterNodeIp();
	if($masternodeip eq $args{motherboard}->getAttr(name => 'motherboard_internal_ip')) {
		# this motherboard is the masternode so we remove virtualserver definitions
		$log->debug('First Node is started, nothing to do');
		return;		
	} else {
		use EFactory;
		my $masternode_econtext = EFactory::newEContext(ip_source => '127.0.0.1', ip_destination => $masternodeip);
		
		$self->generateKeepalived(mount_point => '/etc', econtext => $masternode_econtext);
		$self->reload(econtext => $masternode_econtext);	
	}
}
1;
