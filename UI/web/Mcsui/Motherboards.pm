package Mcsui::Motherboards;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Forward;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_motherboards : StartRunmode {
    my $self = shift;
    my $output = '';
    my $motherboards = [
		{ ID => '1','POSITION' => '1', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ID => '2','POSITION' => '2', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ ID => '3','POSITION' => '3', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'}, 
		{ ID => '4','POSITION' => '4', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ ID => '5','POSITION' => '5', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'no'}, 
		{ ID => '6','POSITION' => '6', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ ID => '7','POSITION' => '7', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ ID => '8','POSITION' => '8', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ ID => '9','POSITION' => '9', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ ID => '10','POSITION' => '10', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'no'}
    ];
    my $details = [
		{ ID => '1', 'SN' => '000-1111-1111-00000N', 'MAC' => '00:00:00:00:00:00', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.1', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description' },
		{ ID => '2','SN' => '222-2222-2222-00000N', 'MAC' => '00:00:00:00:00:11', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.2', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description'},
		{ ID => '3','SN' => '333-3333-3333-00000N', 'MAC' => '00:00:00:00:00:22', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.3', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description'},
		{ ID => '4','SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:33', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.4', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description' },
		{ ID => '5','SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:44', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.5', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description' },
		{ ID => '6','SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:55', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.6', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description' },
		{ ID => '7','SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:66', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.7', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description' },
		{ ID => '8','SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:77', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.8', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description' },
		{ ID => '9','SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:88', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.9', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description' },
		{ ID => '10','SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:99', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.10', 'KERNEL' => '2.6.32-hedera', DESC => 'optional description optional description optional description optional description optional description optional description optional description optional description optional description ' }
    ];
    
    my $tmpl =  $self->load_tmpl('view_motherboards.tmpl');
    $tmpl->param('TITLE_PAGE' => "Motherboards View");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MOTHERBOARDS' => 1);
	
	$tmpl->param('USERID' => 1234);
	$tmpl->param('MOTHERBOARDS' => $motherboards);
	$tmpl->param('DETAILS' => $details);
	
	$output .= $tmpl->output();
        
    return $output;	
}

sub form_addmotherboard : Runmode {
    my $self = shift;
    my $errors = shift;
    my $output = '';
    my $tmpl =  $self->load_tmpl('form_addmotherboard.tmpl');
    $tmpl->param('TITLE_PAGE' => "Adding a Motherboard");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MOTHERBOARDS' => 1);
	$tmpl->param($errors) if $errors;
	
	$tmpl->param('USERID' => 1234);
	$output .= $tmpl->output();
	return $output;
}

sub process_addmotherboard : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addmotherboard', '_addmotherboard_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "AddMotherboard", priority => '100', params => { 
		motherboard_mac_address => $query->param('mac_address'), 
		kernel_id => $query->param('kernel'), , 
		motherboard_serial_number => $query->param('serial_number'), 
		motherboard_model_id => $query->param('motherboard_model'), 
		processor_model_id => $query->param('cpu_model'), 
		motherboard_desc => $query->param('desc') });
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'new motherboard operation adding to execution queue'); }
    $self->forward('view_motherboards');
}

sub _addmotherboard_profile {
	return {
		required => 'mac_address',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

1;
