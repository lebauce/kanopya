package KanopyaUI::Permissions;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

sub view_selectactors : StartRunmode {
	my $self = shift;
	my $query = $self->query();
	my $tmpl = $self->load_tmpl('Permissions/view_selectactors.tmpl');
	$tmpl->param('titlepage' => "Permissions - who");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submPermissions' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	
	return $tmpl->output();
	
}

sub form_permissionsettings : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $tmpl = $self->load_tmpl('Permissions/form_permissionsettings.tmpl');
	
	
	return $tmpl->output();
}
