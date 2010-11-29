package Mcsui::Messager;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use strict;
use warnings;

sub setup {
	my $self = shift;
	my $tmpl_path = [
		'/opt/kanopya/ui/web/Mcsui/templates/',
		'/opt/kanopya/ui/web/Mcsui/templates/Messages/'];
	$self->tmpl_path($tmpl_path);
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_messages : StartRunmode {
    my $self = shift;
 	my $query = $self->query();
    
    my $userid = $query->param('userid');
    my @loopparams = $self->{'admin'}->getMessages();
    
    my $tmpl = $self->load_tmpl('view_messages.tmpl');
    
    #$tmpl->param(USERID => $userid);
    $tmpl->param(MESSAGES => \@loopparams);
   
	return $tmpl->output();
}



1;
