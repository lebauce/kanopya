package KanopyaUI::Networks;
use base 'KanopyaUI::CGI';


sub view_publicips : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Networks/view_publicips.tmpl');
    my $output = '';
    my $publicips = $self->{'admin'}->{manager}->{network}->getPublicIPs();
#    my $publicips = $self->{'admin'}->getPublicIPs();
   
    $tmpl->param('titlepage' => "Public IPs View");
	$tmpl->param('mClusters' => 1);
	$tmpl->param('submNetworks' => 1);
	$tmpl->param('USERID' => 1234);
	$tmpl->param('PUBLICIPS' => $publicips);
	
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
    	$self->{admin}->{manager}->{network}->newPublicIP(
    		ip_address => $query->param('ip_address'),
    		ip_mask => $query->param('ip_mask'),
    		gateway => $query->param('gateway') ne '' ? $query->param('gateway') : undef, 
    	);
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(from => 'Administrator',level => 'info', content => 'new public ip added.'); }
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
    	$self->{admin}->{manager}->{network}->delPublicIP(publicip_id => $query->param('publicip_id'));
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(from => 'Administrator',level => 'info', content => 'public ip removed.'); }
    $self->redirect('/cgi/kanopya.cgi/networks/view_publicips');
}






1;
