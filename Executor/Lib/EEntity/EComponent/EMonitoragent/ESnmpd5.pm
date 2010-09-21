package EEntity::EComponent::EMonitoragent::ESnmpd5;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::EMonitoragent";
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

# generate snmpd configuration files on node
sub configureNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{motherboard} or ! defined $args{motherboard}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::EMonitoragent::ESnmpd5->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $config = {
	    INCLUDE_PATH => "/templates/mcssnmpd", #$self->_getEntity()->getTemplateDirectory(),
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $conf = $self->_getEntity()->getConf();
	my $rand = new String::Random;
	my $template = Template->new($config);
	
	# generation of /etc/default/snmpd 
	my $tmpfile = $rand->randpattern("cccccccc");
	my $input = "default_snmpd.tt";
    my $data = {};
    $data->{node_ip_address} = $args{motherboard}->getAttr(name => 'motherboard_internal_ip');
    $data->{options} = $conf->{options};
   	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EMonitoragent::ESnmpd->generate : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/default/snmpd');	
	unlink "/tmp/$tmpfile";
	
	# generation of /etc/snmpd/snmpd.conf 
	$tmpfile = $rand->randpattern("cccccccc");
	$input = "snmpd.conf.tt";
    $data = {};
    $data->{monitor_server_ip} = $conf->{monitor_server_ip};
       	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EMonitoragent::ESnmpd->generate : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/snmp/snmpd.conf');	
	unlink "/tmp/$tmpfile";
	
	
	 	 
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
