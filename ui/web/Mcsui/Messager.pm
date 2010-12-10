package Mcsui::Messager;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use strict;
use warnings;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'admin', password => 'admin');
}

sub view_messages : StartRunmode {
    my $self = shift;
 	my $query = $self->query();
    
    my $userid = $query->param('userid');
    my @messages = $self->{'admin'}->getMessages();
    
    my $tmpl = $self->load_tmpl('Messages/view_messages.tmpl');
    my $counter = 0;
    foreach my $message (@messages) {
    	$message->{color} = ($counter % 2) ? 'dark' : 'light';
    	$counter++;
    }
    
    $tmpl->param(messages_list => \@messages);
   	
   
	return $tmpl->output();
}



1;
