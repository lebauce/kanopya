package Mcsui::Systemimages;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_systemimages : StartRunmode {
    my $self = shift;
    my $output = '';
    my @esystemimages = $self->{'admin'}->getEntities(type => 'Systemimage', hash => {});
    my $systemimage =[];
    foreach my $s (@esystemimages){
		my $tmp = {};
		$tmp->{ID} = $s->getAttr(name => 'systemimage_id');
		$tmp->{NAME} = $s->getAttr(name => 'systemimage_name');
		$tmp->{DESC} = $s->getAttr(name => 'systemimage_desc');
		$edistro = $self->{'admin'}->getEntity(type =>'Distribution', id => $s->getAttr(name => 'distribution_id'));
		$tmp->{DISTRO} = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version');
		$tmp->{ACTIVE} = $s->getAttr(name => 'active');
		$tmp->{COMPONENTS} = $s->getInstalledComponents();
		push (@$systemimage, $tmp);
    }		
    
    my $tmpl =  $self->load_tmpl('view_systemimages.tmpl');
    $tmpl->param('TITLE_PAGE' => "System images View");
	$tmpl->param('SYSTEMIMAGE' => $systemimage);
	$tmpl->param('MENU_CONFIGURATION' => 1);
		
	$tmpl->param('USERID' => 1234);
	
	$output .= $tmpl->output();
        
    return $output;	
    
}

sub form_addsystemimage : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl =$self->load_tmpl('form_addsystemimage.tmpl');
	my $output = '';
	
	$tmpl->param('TITLE_PAGE' => "Adding a system image");
	$tmpl->param('MENU_CONFIGURATION' => 1);
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
	$output .= $tmpl->output();
	return $output;
}

sub process_addsystemimage : Runmode {
	my $self = shift;
	use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addsystemimage', '_addsystemimage_profile');
    return $err_page if $err_page;
	
	my $query = $self->query();
	if($query->param('type') eq 'systemimage') {
		eval {
			 $self->{'admin'}->newOp(type => "CloneSystemimage", priority => '100', params => {
			 	systemimage_name => $query->param('systemimage_name'),
			 	systemimage_desc => $query->param('systemimage_desc'),
			 	distribution_id =>  $query->param('distribution_id'), });
		};	
		if(@$) {
			my $error = $@;
			$self->{'admin'}->addMessage(type => 'error', content => $error); 
		} else { $self->{'admin'}->addMessage(type => 'newop', content => 'clone system image operation adding to execution queue'); }	
		
	} elsif($query->param('type') eq 'distribution') {
		eval {
			$self->{'admin'}->newOp(type => "AddSystemimage", priority => '100', params => {
				systemimage_name => $query->param('systemimage_name'),
			 	systemimage_desc => $query->param('systemimage_desc'),
			 	systemimage_id =>  $query->param('distribution_id'), });
		};
		if(@$) {
			my $error = $@;
			$self->{'admin'}->addMessage(type => 'error', content => $error); 
		} else { $self->{'admin'}->addMessage(type => 'newop', content => 'new system image operation adding to execution queue'); }
	}
	
    $self->redirect('/cgi/mcsui.cgi/systemimages/view_systemimages');
}

sub _addsystemimage_profile {
	return {
		required => 'systemimage_name',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
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
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'newop', content => 'activate systemimage operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/systemimages/view_systemimages');
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
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'newop', content => 'deactivate systemimage operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/systemimages/view_systemimages');
}

sub process_removesystemimage : Runmode {
    my $self = shift;
        
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "RemoveSystemimage", priority => '100', params => { 
		motherboard_id => $query->param('systemimage_id'), 
		});
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'newop', content => 'remove systemimage operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/motherboards/view_motherboards');
}

1;
