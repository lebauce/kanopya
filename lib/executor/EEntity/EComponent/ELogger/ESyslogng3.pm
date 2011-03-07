package EEntity::EComponent::ELogger::ESyslogng3;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::ELogger";
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
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{motherboard} or ! defined $args{motherboard}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::EMonitoragent::ESyslogng3->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $template_path = $args{template_path} || "/templates/components/mcssyslogng";
	
	my $config = {
	    INCLUDE_PATH => $template_path, #$self->_getEntity()->getTemplateDirectory(),
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $conf = $self->_getEntity()->getConf();
	my $rand = new String::Random;
	my $template = Template->new($config);
	
	# generation of /etc/syslog-ng/syslog-ng.conf
	my $tmpfile = $rand->randpattern("cccccccc");
	my $input = "syslog-ng.conf.tt";
    my $data = $conf;
    
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::ECLogger::ESyslogng3->generate : error during template generation : " . $template->error;;
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point}.'/syslog-ng/syslog-ng.conf');	
	unlink "/tmp/$tmpfile";
	
}

sub addNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::EMonitoragent::ESyslogng3->addNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$self->configureNode(%args);
		
	# add init scripts
	$self->addInitScripts(
		etc_mountpoint => $args{mount_point},
		econtext => $args{econtext},
		scriptname => 'syslog-ng',
		startvalue => 10,
		stopvalue => 90
	);
	 	 
}

# Reload process
sub reload {
	my $self = shift;
	my %args = @_;
	
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::ELooger::ESyslogng3->reload needs an econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "invoke-rc.d syslog-ng restart";
	my $result = $args{econtext}->execute(command => $command);
	return undef;
}

1;
