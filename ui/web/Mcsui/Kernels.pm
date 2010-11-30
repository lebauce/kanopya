package Mcsui::Kernels;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use strict;
use warnings;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}


# kernels listing page

sub view_kernels : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Kernels/view_kernels.tmpl');
	$tmpl->param('titlepage' => "Systems - Kernels");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submKernels' => 1);

    my @ekernels = $self->{'admin'}->getEntities(type => 'Kernel', hash => {});
    my $kernels = [];
    
    foreach my $m (@ekernels) {
		my $tmp = {};
		$tmp->{kernel_id} = $m->getAttr(name => 'kernel_id');
		$tmp->{kernel_name} = $m->getAttr(name => 'kernel_name');
		$tmp->{kernel_version} = $m->getAttr(name => 'kernel_version');
		$tmp->{kernel_desc} = $m->getAttr(name => 'kernel_desc');
		push (@$kernels, $tmp);
    }

	$tmpl->param('kernels_list' => $kernels);
    return $tmpl->output();
}



1;
