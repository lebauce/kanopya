package KanopyaUI::Executor;
use base 'KanopyaUI::CGI';

use strict;
use warnings;

use Log::Log4perl "get_logger";
my $log = get_logger("webui");

sub view_executionqueue : StartRunmode {
	my $self = shift;
    my $tmpl =  $self->load_tmpl('Executor/view_executionqueue.tmpl');
    # header / menu variables
    $tmpl->param('titlepage' => "Dashboard - Operations queue");
	$tmpl->param('mDashboard' => 1);
	$tmpl->param('submExecutor' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	
	$tmpl->param('operations' => $self->{adm}->getOperations());
	
	return $tmpl->output();
}