package Mcsui::Systemimages;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
	$self->mode_param(
		path_info => 2,
		param => 'rm'
	);
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
	$tmp->{DISTRO} = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version')." (".$edistro->getAttr(name => 'distribution_desc').")";
	$tmp->{ACTIVE} = $s->getAttr(name => 'active');
	push (@$systemimage, $tmp);
    }		
    
    my $tmpl =  $self->load_tmpl('view_systemimages.tmpl');
    $tmpl->param('TITLE_PAGE' => "System images View");
	$tmpl->param('SYSTEMIMAGE' => $systemimage);
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	$tmpl->param('SUBMENU_SYSTEMIMAGES' => 1);
	
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
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	$tmpl->param('SUBMENU_SYSTEMIMAGES' => 1);
	$tmpl->param($errors) if $errors;
	
	my @esystemimages = $self->{'admin'}->getEntities(type => 'Systemimage', hash => {});
	my @edistros = $self->{'admin'}->getEntities(type =>'Distribution', hash => {});
	
	my $systemimage = [];
	foreach my $s (@esysteimages){
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

1;
