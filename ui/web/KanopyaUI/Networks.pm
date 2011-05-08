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
package KanopyaUI::Networks;
use base 'KanopyaUI::CGI';


sub view_publicips : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Networks/view_publicips.tmpl');
    my $output = '';
    my $publicips = $self->{adm}->{manager}->{network}->getPublicIPs();
#    my $publicips = $self->{'admin'}->getPublicIPs();
   
    $tmpl->param('titlepage' => "Public IPs View");
    $tmpl->param('mClusters' => 1);
    $tmpl->param('submNetworks' => 1);
    $tmpl->param('USERID' => 1234);
    $tmpl->param('PUBLICIPS' => $publicips);
    $tmpl->param('username' => $self->session->param('username'));
    
    $output .= $tmpl->output();
        
    return $output;    
}

sub form_addpublicip : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('Networks/form_addpublicip.tmpl');
    my $output = '';
    $tmpl->param($errors) if $errors;

    
    $output .= $tmpl->output();
    return $output;
}

sub process_addpublicip : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addpublicip', '_addpublicip_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    eval {
        $self->{adm}->{manager}->{network}->newPublicIP(
            ip_address => $query->param('ip_address'),
            ip_mask => $query->param('ip_mask'),
            gateway => $query->param('gateway') ne '' ? $query->param('gateway') : undef, 
        );
    };
    if($@) { 
        my $error = $@;
        $self->{adm}->addMessage(from => 'Administrator',level => 'error', content => $error); 
    } else { $self->{adm}->addMessage(from => 'Administrator',level => 'info', content => 'new public ip added.'); }
    return $self->close_window();
}

sub _addpublicip_profile {
    return {
        required => ['ip_address', 'ip_mask'],
        msgs => {
                any_errors => 'some_errors',
                prefix => 'err_'
        },
    };
}

sub process_removepublicip : Runmode {
    my $self = shift;
    my $query = $self->query();
    eval {
        $self->{adm}->{manager}->{network}->delPublicIP(publicip_id => $query->param('publicip_id'));
    };
    if($@) { 
        my $error = $@;
        $self->{adm}->addMessage(from => 'Administrator',level => 'error', content => $error); 
    } else { $self->{adm}->addMessage(from => 'Administrator',level => 'info', content => 'public ip removed.'); }
    $self->redirect('/cgi/kanopya.cgi/networks/view_publicips');
}






1;
