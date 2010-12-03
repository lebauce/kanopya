package Mcsui::Distributions;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use strict;
use warnings;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'admin', password => 'admin');
}


# distributions listing page

sub view_distributions : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Distributions/view_distributions.tmpl');
	$tmpl->param('titlepage' => "Systems - Distributions");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submDistributions' => 1);

    my @edistributions = $self->{'admin'}->getEntities(type => 'Distribution', hash => {});
    my $distributions = [];
    
    foreach my $m (@edistributions) {
		my $tmp = {};
		$tmp->{distribution_id} = $m->getAttr(name => 'distribution_id');
		$tmp->{distribution_name} = $m->getAttr(name => 'distribution_name');
		$tmp->{distribution_version} = $m->getAttr(name => 'distribution_version');
		$tmp->{distribution_desc} = $m->getAttr(name => 'distribution_desc');
		#$tmp->{COMPONENTS} = $m->getProvidedComponents();
			   
		push (@$distributions, $tmp);
    }

	$tmpl->param('distributions_list' => $distributions);
    return $tmpl->output();
}

# distributions details page

sub view_distributiondetails : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Distributions/view_distributiondetails.tmpl');
	 
	# header / menu variables
	$tmpl->param('titlepage' => "Distribution's overview");
	$tmpl->param('mSystems' => 1);
	$tmpl->param('submDistributions' => 1);
	
	my $query = $self->query();
	my $edistribution = $self->{'admin'}->getEntity(type => 'Distribution', id => $query->param('distribution_id'));
	
	$tmpl->param('distribution_id' => $edistribution->getAttr(name => 'distribution_id'));
	$tmpl->param('distribution_name' => $edistribution->getAttr(name => 'distribution_name'));
	$tmpl->param('distribution_version' => $edistribution->getAttr(name => 'distribution_version'));
	$tmpl->param('distribution_desc' => $edistribution->getAttr(name => 'distribution_desc'));
	
	my $components_list = $edistribution->getProvidedComponents();
	my $nb = scalar(@$components_list);
	$tmpl->param('components_list' => $components_list);
	$tmpl->param('components_count' => $nb + 1);
	
	return $tmpl->output();
}

1;
