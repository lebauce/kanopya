package KanopyaUI::Kernels;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::Kernel;

# kernels listing page

sub view_kernels : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Kernels/view_kernels.tmpl');
	$tmpl->param('titlepage' => "Systems - Kernels");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submKernels' => 1);
	$tmpl->param('username' => $self->session->param('username'));

    my @ekernels = Entity::Kernel->getKernels(hash => {});
    my $methods = Entity::Kernel->getPerms();
    my $kernels = [];
    
    foreach my $m (@ekernels) {
		my $tmp = {};
		my $methods = $m->getPerms();
		$tmp->{kernel_id} = $m->getAttr(name => 'kernel_id');
		$tmp->{kernel_name} = $m->getAttr(name => 'kernel_name');
		$tmp->{kernel_version} = $m->getAttr(name => 'kernel_version');
		$tmp->{kernel_desc} = $m->getAttr(name => 'kernel_desc');
		if($methods->{'setperm'}->{'granted'}) { $tmp->{can_setperm} = 1; }
		
		push (@$kernels, $tmp);
    }

	if($methods->{'upload'}->{'granted'}) { $tmpl->param('link_upload' => 1); }
	else { $tmpl->param('link_upload' => 0); }
	$tmpl->param('kernels_list' => $kernels);
    return $tmpl->output();
}



1;
