package Entity::Cluster;

use strict;

use base "Entity";
use lib qw (..);
use Entity::Component;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");

# contructor

sub new {
    my $class = shift;
    my %args = @_;

	$log->info("Cluster Instanciation");
    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getComponents{
	
}

1;
