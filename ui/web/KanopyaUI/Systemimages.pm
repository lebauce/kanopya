package KanopyaUI::Systemimages;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::Systemimage;
use Entity::Distribution;

# system images listing page

sub view_systemimages : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Systemimages/view_systemimages.tmpl');
    $tmpl->param('titlepage' => "Systems - System images");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submSystemimages' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	    
    my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
    my $systemimages =[];
   
	foreach my $s (@esystemimages) {
		my $tmp = {};
		$tmp->{systemimage_id} = $s->getAttr(name => 'systemimage_id');
		$tmp->{systemimage_name} = $s->getAttr(name => 'systemimage_name');
		$tmp->{systemimage_desc} = $s->getAttr(name => 'systemimage_desc');
		eval {
			my $edistro = Entity::Distribution->get(id => $s->getAttr(name => 'distribution_id'));
			$tmp->{distribution} = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version');
		};
		$tmp->{active} = $s->getAttr(name => 'active');
		push (@$systemimages, $tmp);
    }		
	$tmpl->param('systemimages_list' => $systemimages);
	my $methods = Entity::Systemimage->getPerms();
	if($methods->{'create'}->{'granted'}) { $tmpl->param('can_create' => 1); }
	
	return $tmpl->output();
}

# system images creation popup window

sub form_addsystemimage : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl =$self->load_tmpl('Systemimages/form_addsystemimage.tmpl');
	$tmpl->param($errors) if $errors;
	
	my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
	my @edistros = Entity::Distribution->getDistributions(hash => {});
	
	my $systemimage = [];
	foreach my $s (@esystemimages){
		my $tmp = {};
		$tmp->{ID} = $s->getAttr(name => 'systemimage_id');
		$tmp->{NAME} = $s->getAttr(name => 'systemimage_name');
		push (@$systemimage, $tmp); 
	}
	
	my $distro = [];
	foreach my $d (@edistros){
		my $tmp = {};
		$tmp->{ID} = $d->getAttr(name => 'distribution_id');
		$tmp->{NAME} = join(' ',$d->getAttr(name =>'distribution_name'), $d->getAttr(name =>'distribution_version'));
		push (@$distro, $tmp);		
	}
	
	$tmpl->param('SYSTEMIMAGE' => $systemimage);
	$tmpl->param('DISTRIBUTION' => $distro);
	
	return $tmpl->output();
}

# fields verification function to used with form_addsystemimage

sub _addsystemimage_profile {
	return {
		required => 'systemimage_name',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

# form_addsystemimage processing

sub process_addsystemimage : Runmode {
	my $self = shift;
	use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addsystemimage', '_addsystemimage_profile');
    return $err_page if $err_page;
	
	my $query = $self->query();
			
	# system image create from another system image (clone)
	# distribution_id query parameter contains system image source id 
	if($query->param('source') eq 'systemimage') {
		eval {
			my $esystemimage = Entity::Systemimage->get(id => $query->param('systemimage_id'));
			$esystemimage->clone(
				systemimage_name => $query->param('systemimage_name'),
			 	systemimage_desc => $query->param('systemimage_desc'),
			);
		};
		if($@) {
			my $exception = $@;
			if(Kanopya::Exception::Permission::Denied->caught()) {
				$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
				$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
			}
			else { $exception->rethrow(); }
		}
		else {	
			$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'new system image clone adding to execution queue'); 
			return $self->close_window();
		} 		
		 
	} # system image creation from a distribution
	elsif($query->param('source') eq 'distribution') {	
		eval {
			my $esystemimage = Entity::Systemimage->new(
				systemimage_name => $query->param('systemimage_name'),
			 	systemimage_desc => $query->param('systemimage_desc'),
			 	distribution_id =>  $query->param('distribution_id'), 
			);		
		 	$esystemimage->create(); 
		}; 	
		if($@) {
			my $exception = $@;
			if(Kanopya::Exception::Permission::Denied->caught()) {
				$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
				$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
			}
			else { $exception->rethrow(); }
		}
		else {	
			$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'new system image operation adding to execution queue'); 
			return $self->close_window();
		}
	}
}

# systemimage details page

sub view_systemimagedetails : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Systemimages/view_systemimagedetails.tmpl');
	 
	# header / menu variables
	$tmpl->param('titlepage' => "System image's overview");
	$tmpl->param('mSystems' => 1);
	$tmpl->param('submSystemimages' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	
	# actions visibility

	my $query = $self->query();
	my $esystemimage = Entity::Systemimage->get(id => $query->param('systemimage_id'));
	
	my $methods = $esystemimage->getPerms();
	if($methods->{'setperm'}->{'granted'}) { $tmpl->param('can_setperm' => 1); }
	
	$tmpl->param('systemimage_id' => $esystemimage->getAttr(name => 'systemimage_id'));
	$tmpl->param('systemimage_name' => $esystemimage->getAttr(name => 'systemimage_name'));
	$tmpl->param('systemimage_desc' => $esystemimage->getAttr(name => 'systemimage_desc'));
	
	eval {	
		my $edistro = Entity::Distribution->get(id => $esystemimage->getAttr(name => 'distribution_id'));
		$tmpl->param('distribution' => $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version'));
	};
	if(not $esystemimage->getAttr(name => 'active')) {
		if($methods->{'activate'}->{'granted'}) { $tmpl->param('can_activate' => 1); }
		if($methods->{'remove'}->{'granted'}) { $tmpl->param('can_delete' => 1); }
	} else {
		if($methods->{'deactivate'}->{'granted'}) { $tmpl->param('can_deactivate' => 1); }
		$tmpl->param('active' => 1);
	}
	
	my $components_list = $esystemimage->getInstalledComponents();
	my $nb = scalar(@$components_list);
	foreach my $c (@$components_list) {
		delete $c->{component_id};
	}
	$tmpl->param('components_list' => $components_list);
	$tmpl->param('components_count' => $nb + 1);
	
	
	return $tmpl->output();
}

# TODO systemimage edition popup window

sub form_editsystemimage : Runmode {
	return "TODO";
}

# systemimage deletion processing

sub process_removesystemimage : Runmode {
	my $self = shift;
	my $query = $self->query();
	eval {
		my $esystemimage = Entity::Systemimage->get(id => $query->param('systemimage_id'));
		$esystemimage->remove();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'system image removing adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/systemimages/view_systemimages');
	} 
}

# systemimage activation processing

sub process_activatesystemimage : Runmode {
	my $self = shift;
	my $query = $self->query();
	eval {
		my $esystemimage = Entity::Systemimage->get(id => $query->param('systemimage_id'));
		$esystemimage->activate();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
		}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'system image activation adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/systemimages/view_systemimagedetails?systemimage_id='.$query->param('systemimage_id'));
	} 
}

# systemimage deactivation processing

sub process_deactivatesystemimage : Runmode {
	my $self = shift;
	my $query = $self->query();
	eval {
		my $esystemimage = Entity::Systemimage->get(id => $query->param('systemimage_id'));
		$esystemimage->deactivate();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'system image activation adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/systemimages/view_systemimages');
	} 
}

# TODO form_installcomponent popup window

sub form_installcomponent : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl =$self->load_tmpl('Systemimages/form_installcomponent.tmpl');
	$tmpl->param($errors) if $errors;
	my $query = $self->query;
	$tmpl->param('systemimage_id' => $query->param('systemimage_id'));
	
	return $tmpl->output();
}

sub _installcomponent_profile {
	return {
		required => 'componentfile',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

sub process_installcomponent : Runmode {
	my $self = shift;
	use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_installcomponent', '_installcomponent_profile');
    return $err_page if $err_page;
	my $query = $self->query();
	eval {
		my $esystemimage = Entity::Systemimage->get(id => $query->param('systemimage_id'));
		$esystemimage->installComponent();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'new component installation added to execution queue'); 
		return $self->close_window();
	} 		
}

1;
