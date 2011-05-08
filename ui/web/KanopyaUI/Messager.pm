#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
