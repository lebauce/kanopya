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
package KanopyaUI::Distributions;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::Distribution;

# distributions listing page

sub view_distributions : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Distributions/view_distributions.tmpl');
	$tmpl->param('titlepage' => "Systems - Distributions");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submDistributions' => 1);
	$tmpl->param('username' => $self->session->param('username'));

    my @edistributions = Entity::Distribution->getDistributions(hash => {});
    my $distributions = [];
    
    foreach my $m (@edistributions) {
		my $tmp = {};
		my $methods = $m->getPerms();
		$tmp->{distribution_id} = $m->getAttr(name => 'distribution_id');
		$tmp->{distribution_name} = $m->getAttr(name => 'distribution_name');
		$tmp->{distribution_version} = $m->getAttr(name => 'distribution_version');
		$tmp->{distribution_desc} = $m->getAttr(name => 'distribution_desc');
		if($methods->{'setperm'}->{'granted'}) { $tmp->{'can_setperm'} = 1; }
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
	$tmpl->param('username' => $self->session->param('username'));
	
	my $query = $self->query();
	my $edistribution = Entity::Distribution->get(id => $query->param('distribution_id'));
	
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
