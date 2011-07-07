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
package KanopyaUI::Powersupplycards;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::Powersupplycard;
use Entity::Powersupplycardmodel;

# power supply card listing page

sub view_powersupplycards : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Powersupplycards/view_powersupplycards.tmpl');
    $tmpl->param('titlepage' => "Hardware - Powersupplycards");
    $tmpl->param('mHardware' => 1);
    $tmpl->param('submPower' => 1);
    $tmpl->param('username' => $self->session->param('username'));  
    
    my @powersupplycards = Entity::Powersupplycard->getPowerSupplyCards(hash => {});
    my $pscs = [];
    
    foreach my $psc (@powersupplycards) {
        my $tmp = {};
        $tmp->{powersupplycard_id} = $psc->getAttr(name => 'powersupplycard_id');
        $tmp->{powersupplycard_name} = $psc->getAttr(name => 'powersupplycard_name');
        $tmp->{powersupplycard_desc} = "Ajouter le champ description dans la database!"; 
        $tmp->{powersupplycard_ip} = $psc->getAttr(name => 'powersupplycard_ip');
        $tmp->{active} = $psc->getAttr(name => 'active');
        push @$pscs, $tmp;
    }
    
    my $methods = Entity::Powersupplycard->getPerms();
    if($methods->{'create'}->{'granted'}) { $tmpl->param('can_create' => 1); }
    
    $tmpl->param('powersupplycards_list' => $pscs);
    return $tmpl->output();
} 

# power supplycard creation popup window

sub form_addpowersupplycard : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('Powersupplycards/form_addpowersupplycard.tmpl');
    $tmpl->param($errors) if $errors;

    my @powersupplycardmodels = Entity::Powersupplycardmodel->getPowersupplycardmodels(hash => {});
    my $pscms = [];
    foreach my $pscm (@powersupplycardmodels) {
        my $tmp = {};
        $tmp->{id} = $pscm->getAttr(name => 'powersupplycardmodel_id');
        $tmp->{name} = $pscm->toString();
        push @$pscms, $tmp;
    }
    
    $tmpl->param('powersupplycardmodels' => $pscms);
    return $tmpl->output();    
}

# form_addpowersupplycard processing

sub process_addpowersupplycard : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addpowersupplycard', '_addpowersupplycard_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    my %params = (
        powersupplycard_mac_address => $query->param('mac_address'), 
        powersupplycard_name => $query->param('name'), 
        powersupplycardmodel_id => $query->param('powersupplycardmodel_id'), 
        powersupplycard_ip => '1.1.1.1',
        #powersupplycard_desc => $query->param('desc'),
    );

    my $powersupplycard = Entity::Powersupplycard->new(%params);     
    eval { $powersupplycard->create() };
    if($@) { 
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            $self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else { return $self->close_window(); }
}

# fields verification function to used with form_addpowersupplycard

sub _addpowersupplycard_profile {
    return {
        required => ['mac_address', 'name'],
        msgs => {
                any_errors => 'some_errors',
                prefix => 'err_'
        },
    };
}

# power supply card details page

sub view_powersupplycarddetails : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl = $self->load_tmpl('Powersupplycards/view_powersupplycarddetails.tmpl');
    
     # header / menu variables
    $tmpl->param('titlepage' => "Power supply card's overview");
    $tmpl->param('mHardware' => 1);
    $tmpl->param('submPower' => 1);
    $tmpl->param('username' => $self->session->param('username'));
    
    my $query = $self->query();
    my $epowersupplycard = Entity::Powersupplycard->get(id => $query->param('powersupplycard_id'));
    
    my $model = Entity::Powersupplycardmodel->get(id => $epowersupplycard->getAttr(name => 'powersupplycardmodel_id'));
    
    $tmpl->param('active' => $epowersupplycard->getAttr(name => 'active'));
    $tmpl->param('model' => $model->toString());
    $tmpl->param('slots_count' => $model->getAttr(name => 'powersupplycardmodel_slotscount'));
    $tmpl->param('powersupplycard_name' => $epowersupplycard->getAttr(name => 'powersupplycard_name'));
    $tmpl->param('powersupplycard_desc' => 'ajouter la description dans la database!!!');
    $tmpl->param('mac_address' => $epowersupplycard->getAttr(name => 'powersupplycard_mac_address'));
    $tmpl->param('ip' => $epowersupplycard->getAttr(name => 'powersupplycard_ip'));
    
    
    
    return $tmpl->output();
}


1;