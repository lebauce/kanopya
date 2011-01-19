package KanopyaUI::Permissions;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");

sub setup {
	my $self = shift;
	$self->{adm} = Administrator->new(login => 'thom', password => 'pass');
}
