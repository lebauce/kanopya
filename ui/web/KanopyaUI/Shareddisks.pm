package KanopyaUI::Shareddisks;
use base 'KanopyaUI::CGI';

sub view_shareddisks : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Shareddisks/view_shareddisks.tmpl');
    my $output = '';

    $tmpl->param('TITLE_PAGE' => "Shared disk View");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
		
	$tmpl->param('USERID' => 1234);
		
	$output .= $tmpl->output();
        
    return $output;	
}

sub form_addshareddisk : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('form_addshareddisk.tmpl');
    my $output = '';
    $tmpl->param('TITLE_PAGE' => "Adding a Shared disk");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	$tmpl->param($errors) if $errors;

		
	
	$output .= $tmpl->output();
	return $output;
}

sub process_addshareddisk : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addshareddisk', '_addshareddisk_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "AddMotherboard", priority => '100', params => { 
		motherboard_mac_address => $query->param('mac_address'), 
		kernel_id => $query->param('kernel'), , 
		motherboard_serial_number => $query->param('serial_number'), 
		motherboardmodel_id => $query->param('motherboard_model'), 
		processormodel_id => $query->param('cpu_model'), 
		motherboard_desc => $query->param('desc') });
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(from => 'Administrator',level => 'info', content => 'new motherboard operation adding to execution queue'); }
    $self->redirect('/cgi/kanopya.cgi/motherboards/view_motherboards');
}

sub _addshareddisk_profile {
	return {
		required => 'mac_address',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}






1;

