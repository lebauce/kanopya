package KanopyaUI::Systemstatus;
use base 'KanopyaUI::CGI';

# Define admin components and services we want display status. They are organized as we want in ui.
sub adminComponentsDef {
	return [ 	[
    				{ id => 'Database', label => 'Database server', comps => [{ label => 'mysql', name => 'mysql'}] },
    				{ id => 'Boot', label => 'Boot server', comps => [	{ label => 'ntpd', name => 'ntpd'},
    																	{ label => 'dhcpd3', name => 'dhcpd3'},
    																	{ label => 'atftpd', name => 'atftpd'}] },
    				{ id => 'Harddisk', label => 'NAS server', comps => [{ label => 'ietd', name => 'ietd'},
    																	{ label => 'nfsd', name => 'nfsd'}] }
    			],[
    				{ id => 'Monitor', label => 'Monitor', comps => [{ label => 'collector', name => 'kanopya-collector'}, { label => 'grapher', name => 'kanopya-grapher'}] },
    				{ id => 'Planner', label => 'Planner', comps => [] },
    				{ id => 'Orchestrator', label => 'Orchestrator', comps => [{ label => 'orchestrator', name => 'kanopya-orchestrator'}] },
    			],[
    				{ id => 'Execute', label => 'Executor', comps => [{ label => 'executor', name => 'kanopya-executor'}] },
				]
  			];
}

sub getStatus {
   		my $self = shift;
   		my %args = @_;
   		
   		my $grep = `ps aux | grep $args{proc_name}`;
    	my $ps_count = scalar (split '\n', $grep);
    	my $status = $ps_count > 2 ? 'Up' : 'Down';
		return $status;
}

sub xml_admin_status : Runmode {
	my $self = shift;
	my $session = $self->session;     
    my $admin_components = adminComponentsDef;
    
    # Check the status of admin components and build the xml of status
	my $xml = "";
    foreach my $group (@$admin_components) {
    	foreach my $def (@$group) {
    		my ($tot, $up) = (0 ,0);
    		foreach my $serv (@{$def->{comps}}) {
				my $status = $self->getStatus( proc_name => $serv->{name});
    			$up++ if ($status eq 'Up');
    			$tot++;
    			$xml .= "<elem id='status$serv->{name}' class='img$status'/>";
    		}
    		my $status = ($tot>0 && $up eq $tot) ? 'Up' : ($up>0 ? 'Broken' : 'Down');
    		$xml .= "<elem id='status$def->{id}' class='img$status'/>";
    	}
    }

	return '<data>' . $xml . '</data>';
}

sub view_status : StartRunmode {
    my $self = shift;
    
    my $output = '';

    # Check the status of admin components and build the html template var
    my $admin_components = adminComponentsDef;
    my @components_status = ();
    foreach my $group (@$admin_components) {
    	my @res_group = ();
    	foreach my $def (@$group) {
    		my @details = ();
    		my ($tot, $up) = (0 ,0);
    		foreach my $serv (@{$def->{comps}}) {
    			my $status = $self->getStatus( proc_name => $serv->{name});
    			$up++ if ($status eq 'Up');
    			$tot++;
				push @details, {name => $serv->{name}, label => $serv->{label}, status => $status };
    		}
    		push @res_group, {	id => $def->{id}, label => $def->{label}, details => \@details,
    							status => ($tot>0 && $up eq $tot ? 'Up' : ($up>0 ? 'Broken' : 'Down') ) };
    	}
    	push  @components_status, { group => \@res_group};
    }
    
    my $tmpl =  $self->load_tmpl('Systemstatus/view_status.tmpl');
    $tmpl->param('TITLEPAGE' => "System Status");
	$tmpl->param('MDASHBOARD' => 1);
	$tmpl->param('SUBMSYSTEMSTATUS' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	$tmpl->param('COMPONENTS_STATUS' => \@components_status);
	$output .= $tmpl->output();
     
    return $output;   
}

1;
