package Entity::Component::DBserver::Mysql5;
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use Log::Log4perl "get_logger";
use Data::Dumper;
use strict;
use McsExceptions;

use strict;

use base "Entity::Component::DBserver";

my $log = get_logger("administrator");
my $errmsg;
# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}
1;
