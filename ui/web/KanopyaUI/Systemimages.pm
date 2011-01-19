package KanopyaUI::Systemimages;
use base 'KanopyaUI::CGI';

use strict;
use warnings;

# system images listing page

sub view_systemimages : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Systemimages/view_systemimages.tmpl');
    $tmpl->param('titlepage' => "Systems - System images");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submSystemimages' => 1);
	    
    my @esystemimages = $self->{'admin'}->getEntities(type => 'Systemimage', hash => {});
    my $systemimages =[];
   
	foreach my $s (@esystemimages) {
		my $tmp = {};
		$tmp->{systemimage_id} = $s->getAttr(name => 'systemimage_id');
		$tmp->{systemimage_name} = $s->getAttr(name => 'systemimage_name');
		$tmp->{systemimage_desc} = $s->getAttr(name => 'systemimage_desc');
		my $edistro = $self->{'admin'}->getEntity(type =>'Distribution', id => $s->getAttr(name => 'distribution_id'));
		$tmp->{distribution} = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version');
		$tmp->{active} = $s->getAttr(name => 'active');
		push (@$systemimages, $tmp);
    }		
	$tmpl->param('systemimages_list' => $systemimages);

	return $tmpl->output();
}

# system images creation popup window

sub form_addsystemimage : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl =$self->load_tmpl('Systemimages/form_addsystemimage.tmpl');
	$tmpl->param($errors) if $errors;
	
	my @esystemimages = $self->{'admin'}->getEntities(type => 'Systemimage', hash => {});
	my @edistros = $self->{'admin'}->getEntities(type =>'Distribution', hash => {});
	
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
	eval {
		if($query->param('type') eq 'systemimage') {
			$self->{'admin'}->newOp(type => "CloneSystemimage", priority => '100', params => {
			 	systemimage_name => $query->param('systemimage_name'),
			 	systemimage_desc => $query->param('systemimage_desc'),
			 	systemimage_id =>  $query->param('distribution_id'),  });
			
			$self->{'admin'}->addMessage(from => 'Administrator',level => 'info', content => 'clone system image operation adding to execution queue'); 
		
		} elsif($query->param('type') eq 'distribution') {	
			$self->{'admin'}->newOp(type => "AddSystemimage", priority => '100', params => {
				systemimage_name => $query->param('systemimage_name'),
			 	systemimage_desc => $query->param('systemimage_desc'),
			 	distribution_id =>  $query->param('distribution_id'), });
			
			$self->{'admin'}->addMessage(from => 'Administrator', => 'info', content => 'new system image operation adding to execution queue'); 
		}
	};		
	if(@$) {
		my $error = $@;
		$self->{'admin'}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} 	
		
    return $self->close_window();
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
	
	# actions visibility
	$tmpl->param('link_delete' => 0);
	$tmpl->param('link_activate' => 0);

	my $query = $self->query();
	my $esystemimage = $self->{'admin'}->getEntity(type => 'Systemimage', id => $query->param('systemimage_id'));
	
	$tmpl->param('systemimage_id' => $esystemimage->getAttr(name => 'systemimage_id'));
	$tmpl->param('systemimage_name' => $esystemimage->getAttr(name => 'systemimage_name'));
	$tmpl->param('systemimage_desc' => $esystemimage->getAttr(name => 'systemimage_desc'));
		
	my $edistro = $self->{'admin'}->getEntity(type =>'Distribution', id => $esystemimage->getAttr(name => 'distribution_id'));
	$tmpl->param('distribution' => $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version'));
	
	if(not $esystemimage->getAttr(name => 'active')) {
		$tmpl->param('link_activate' => 1);
		$tmpl->param('link_delete' => 1);
	} else {
		$tmpl->param('active' => 1);
	}
	
	my $link_remove = $tmpl->param('active') ? 0 : 1;
	my $components_list = $esystemimage->getInstalledComponents();
	my $nb = scalar(@$components_list);
	foreach my $c (@$components_list) {
		$c->{link_remove} = $link_remove;
	}
	$tmpl->param('components_list' => $components_list);
	$tmpl->param('components_count' => $nb + 1);
	
	
	return $tmpl->output();
}


sub process_activatesystemimage : Runmode {
	my $self = shift;
	my $query = $self->query();
	eval {
    $self->{'admin'}->newOp(type => "ActivateSystemimage", priority => '100', params => { 
		systemimage_id => $query->param('systemimage_id') }
		
	)};
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(from => 'Administrator',level => 'info', content => 'activate systemimage operation adding to execution queue'); }
    $self->redirect('/cgi/kanopya.cgi/systemimages/view_systemimages');
}

sub process_deactivatesystemimage : Runmode {
	my $self = shift;
	my $query = $self->query();
	eval {
    $self->{'admin'}->newOp(type => "DeactivateSystemimage", priority => '100', params => { 
		systemimage_id => $query->param('systemimage_id') }
		
	)};
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(from => 'Administrator',level => 'info', content => 'deactivate systemimage operation adding to execution queue'); }
    $self->redirect('/cgi/kanopya.cgi/systemimages/view_systemimages');
}

sub process_removesystemimage : Runmode {
    my $self = shift;
        
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "RemoveSystemimage", priority => '100', params => { 
		systemimage_id => $query->param('systemimage_id'), 
		});
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(from => 'Administrator',level => 'info', content => 'remove systemimage operation adding to execution queue'); }
    $self->redirect('/cgi/kanopya.cgi/systemimages/view_systemimages');
}

1;
