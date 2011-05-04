package EEntity::EComponent::ESystem::EMounttable1;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::ESystem";
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
		$errmsg = "EComponent::EMonitoragent::EMounttable1->configureNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $config = {
	    INCLUDE_PATH => "/templates/components/mounttable1", #$self->_getEntity()->getTemplateDirectory(),
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $rand = new String::Random;
	my $template = Template->new($config);
	my $tmpfile = $rand->randpattern("cccccccc");
	my $input = "fstab.tt";
	my $data = {};
	$data->{serverroot}
}

sub addNode {
	my $self = shift;
	my %args = @_;
	
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{mount_point} or ! defined $args{mount_point})) {
		$errmsg = "EComponent::ESystem::EMounttable1->addNode needs a motherboard, mount_point and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$self->configureNode(%args);
}





1;
