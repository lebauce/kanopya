package EEntity::EComponent::ESshserver::EOpenssh5;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent::ESshserver";
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

1;
