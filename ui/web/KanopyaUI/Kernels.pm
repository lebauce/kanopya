#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
