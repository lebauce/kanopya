package EEntity::EComponent::EExport::EIscsitarget1;

use strict;
use Log::Log4perl "get_logger";

use base "EEntity::EComponent::EExport";

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub generateInitiatorname{
	my $self = shift;
	my %args  = @_;	
	#$args{params} = {} if !$args{params};	

	if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "EEntity::EStorage::EIscsitarget1->generateInitiatorname need an id named argument to generate initiatorname!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	return "test";
}
1;
