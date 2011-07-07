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