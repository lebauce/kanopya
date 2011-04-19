package EEntity::EComponent::EParallelsProduct::EPleskpanel10;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::EParallelsProduct";
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



sub preStartNode {
	my $self = shift;
	my %args = @_;
	my $pleskpanel = $self->_getEntity();
	my $conf = $pleskpanel->getConf();
	my $motherboard = $args{motherboard};
	$motherboard->setAttr(name => 'motherboard_hostname', value => $conf->{pleskpanel10_hostname});
	$motherboard->save();
}

1;
