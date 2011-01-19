package KanopyaUI::Messager;
use base 'KanopyaUI::CGI';

use strict;
use warnings;

sub view_messages : StartRunmode {
    my $self = shift;
 	my $query = $self->query();
    
    my $userid = $query->param('userid');
    my @messages = $self->{adm}->getMessages();
    
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
