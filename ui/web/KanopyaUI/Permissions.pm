package KanopyaUI::Permissions;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
my $closewindow = "<script type=\"text/javascript\">window.opener.location.reload();window.close();</script>";

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}
