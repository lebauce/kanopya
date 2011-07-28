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
package KanopyaUI::CGI;
use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;


use Administrator;

sub cgiapp_init {
    my $self = shift;
}

sub cgiapp_prerun {
    my $self = shift;
    my $eid = $self->session->param('EID');
    $self->error_mode("error_occured");
    if(not $eid) {
        $self->session_delete;
        $self->redirect('/cgi/kanopya.cgi/login/form_login');
    } else {
        $ENV{EID} = $eid;
        $self->{adm} = Administrator->new();
    }
}

sub close_window {
    my $self = shift;
    my %args = @_;
    my $javascript = "<script type=\"text/javascript\">";
    if(exists $args{url} and defined $args{url}) {
        $javascript .= "window.opener.location.replace(\"$args{url}\");";
    } else {
        $javascript .= "window.opener.location.reload();";
    }
    
    $javascript .= "window.close();</script>";
    return $javascript;
}

sub error_occured {
    my $self = shift;
    my $errors = shift;

    my $template = $self->load_tmpl('error.tmpl');

    $template->param(errors => $errors);
    return $template->output();
}
1;