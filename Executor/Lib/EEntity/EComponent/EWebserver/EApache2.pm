package EEntity::EComponent::EWebserver::EApache2;

use strict;
use Template;
use String::Random;
use Data::Dumper;
use base "EEntity::EComponent::EWebserver";
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

sub addNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{motherboard} or ! defined $args{motherboard}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::EWebserver::EApacge2->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $config = {
	    INCLUDE_PATH => "/templates/mcsapache2", #$self->_getEntity()->getTemplateDirectory(),
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $apache2_conf = $self->_getEntity()->getGeneralConf();	
	$log->debug("Apache2 conf return is : " . Dumper($apache2_conf));
	my $rand = new String::Random;
	my $template = Template->new($config);
	
	# generation of /etc/apache2/apache2.conf 
	my $tmpfile = $rand->randpattern("cccccccc");
	my $input = "apache2.conf.tt";
	my $data = {};
	$data->{serverroot} = $apache2_conf->{'apache2_serverroot'};
   	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EWebserver::EApache2->addNode : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/apache2/apache2.conf');	
	unlink "/tmp/$tmpfile";
	
	# generation of /etc/apache2/ports.conf 
	$tmpfile = $rand->randpattern("cccccccc");
	$input = "ports.conf.tt";
    $data = {};
    $data->{ports} = $apache2_conf->{apache2_ports};
    $data->{sslports} = $apache2_conf->{apache2_sslports};
       	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EWebserver::EApache2->addNode : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/apache2/ports.conf');	
	unlink "/tmp/$tmpfile";
	
	# generation of /etc/php5/apache2/php.ini 
	$tmpfile = $rand->randpattern("cccccccc");
	$input = "php.ini.tt";
    $data = {};
    $data->{phpsessions_dir} = $apache2_conf->{apache2_phpsession};
       	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EWebserver::EApache2->addNode : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/php5/apache2/php.ini');	
	unlink "/tmp/$tmpfile";
	
	# generation of /etc/apache2/sites-available/default
	$tmpfile = $rand->randpattern("cccccccc");
	$input = "virtualhost.tt";
    
    $data = {};
    $data->{virtualhosts} = $self->_getEntity()->getVirtualhostConf();
    
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EWebserver::EApache2->addNode : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/apache2/sites-available/default');	
	unlink "/tmp/$tmpfile";
}

sub removeNode{
	
}

# Reload snmp process
sub reload {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EMonitoragent::ESnmpd5->reload needs an econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "invoke-rc.d snmpd restart";
	my $result = $args{econtext}->execute(command => $command);
	return undef;
}

1;
