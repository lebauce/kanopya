package Mcsui::Messager;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_messages : StartRunmode {
    my $self = shift;
 	my $query = $self->query();
    my $output = '';
    my $userid = $query->param('userid');
    my @loopparams = $self->{'admin'}->getMessages();
    
    my $tmpl = $self->load_tmpl('view_messages.tmpl');
    
    #$tmpl->param(USERID => $userid);
    $tmpl->param(MESSAGES => \@loopparams);
    
	$output .= $tmpl->output();
        
    return $output;
}



1;
