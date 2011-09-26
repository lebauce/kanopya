package Distributions;

use Dancer ':syntax';

use Entity::Distribution;
use Operation;

use Log::Log4perl "get_logger";

my $log = get_logger("webui");

# Obtain every distributions object and attribute.
# After that, send it to distributions template.
sub _distributions {
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
	return $distributions;
}

# Distributions template.
get '/distributions' => sub {
	template 'distributions', {
		title_page       => 'Systems - Distributions',
		eid              => session('EID'),
		distributions_list => _distributions(),
		object           => vars->{adm_object}
	}
}

get '/distributions/:distributionid' => sub {
    # Call for Entity components for Distributions details.
    my $edistribution = Entity::Distribution->get(id => params->{distributionid});
    my $components_list = $edistribution->getProvidedComponents();
    my $nb = scalar(@$components_list);
	
	# Ṕass the text and arrays to the Distribution template. 
	template 'distributions_details', {
		title_page       => "Systems - Distribution's overview",
		eid              => session('EID'),
		distribution_id => $edistribution->getAttr(name => 'distribution_id'),
		distribution_name => $edistribution->getAttr(name => 'distribution_name'),
		distribution_version => $edistribution->getAttr(name => 'distribution_version'),
		distribution_desc => $edistribution->getAttr(name => 'distribution_desc'),
		components_list => $components_list,
		components_count => $nb + 1,
		object           => vars->{adm_object}
	}
}

