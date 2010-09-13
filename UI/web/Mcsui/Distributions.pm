package Mcsui::Distributions;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_distributions : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('view_distributions.tmpl');
    my $output = '';
    my @edistributions = $self->{'admin'}->getEntities(type => 'Distribution', hash => {});
    my $distributions = [];
    
    foreach my $m (@edistributions) {
		my $tmp = {};
		$tmp->{ID} = $m->getAttr(name => 'distribution_id');
		$tmp->{NAME} = $m->getAttr(name => 'distribution_name');
		$tmp->{VERSION} = $m->getAttr(name => 'distribution_version');
		$tmp->{DESC} = $m->getAttr(name => 'distribution_desc');
		$tmp->{COMPONENTS} = $m->getProvidedComponents();
			   
		push (@$distributions, $tmp);
    }
		
    $tmpl->param('TITLE_PAGE' => "Distributions View");
	$tmpl->param('MENU_CONFIGURATION' => 1);
		
	$tmpl->param('USERID' => 1234);
	$tmpl->param('DISTRIBUTIONS' => $distributions);
	
	$output .= $tmpl->output();
        
    return $output;	
}

1;
