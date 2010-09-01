package Mcsui::Motherboards;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->mode_param(
		path_info => 2,
		param => 'rm'
	);
}

sub view_motherboards : StartRunmode {
    my $self = shift;
    my $output = '';
    my $motherboards = [
		{ 'POSITION' => '1', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ 'POSITION' => '2', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ 'POSITION' => '3', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'}, 
		{ 'POSITION' => '4', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ 'POSITION' => '5', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'no'}, 
		{ 'POSITION' => '6', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ 'POSITION' => '7', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ 'POSITION' => '8', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ 'POSITION' => '9', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'yes'},
		{ 'POSITION' => '10', 'MODEL' => 'Intel D945GCFL-2', 'ACTIVE' => 'no'}
    ];
    my $details = [
		{ 'SN' => '111-1111-1111-00000N', 'MAC' => '00:00:00:00:00:00', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.1', 'KERNEL' => '2.6.32-hedera' },
		{ 'SN' => '222-2222-2222-00000N', 'MAC' => '00:00:00:00:00:11', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.2', 'KERNEL' => '2.6.32-hedera'},
		{ 'SN' => '333-3333-3333-00000N', 'MAC' => '00:00:00:00:00:22', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.3', 'KERNEL' => '2.6.32-hedera'},
		{ 'SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:33', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.4', 'KERNEL' => '2.6.32-hedera' },
		{ 'SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:44', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.5', 'KERNEL' => '2.6.32-hedera' },
		{ 'SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:55', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.6', 'KERNEL' => '2.6.32-hedera' },
		{ 'SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:66', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.7', 'KERNEL' => '2.6.32-hedera' },
		{ 'SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:77', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.8', 'KERNEL' => '2.6.32-hedera' },
		{ 'SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:88', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.9', 'KERNEL' => '2.6.32-hedera' },
		{ 'SN' => '123-1234-1234-00000N', 'MAC' => '00:00:00:00:00:99', 'CPU' => 'Intel ATOM 330', 'CORES' => '2', 'RAM' => '2', 'CONSUMPTION' => '33', 'IP' => '10.0.0.10', 'KERNEL' => '2.6.32-hedera' }
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

sub add_motherboard : Runmode {
    my $self = shift;
    return 'you are on AddMotherboard page';
}

sub remove_motherboard : Runmode {
    my $self = shift;
    return 'you are on RemoveMotherboard page';
}

1;
