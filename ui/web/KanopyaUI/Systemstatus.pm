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
package KanopyaUI::Systemstatus;

use Entity::Cluster;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

use base 'KanopyaUI::CGI';

# Define admin components and services we want display status. They are organized as we want in ui.
sub adminComponentsDef {
	return [ 	[
    				{ id => 'Database', label => 'Database server', comps => [{ label => 'mysql', name => 'mysql'}] },
    				{ id => 'Boot', label => 'Boot server', comps => [	{ label => 'ntpd', name => 'ntpd'},
    																	{ label => 'dhcpd', name => 'dhcpd'},
    																	{ label => 'atftpd', name => 'atftpd'}] },
    			],[
    				{ id => 'Harddisk', label => 'NAS server', comps => [{ label => 'ietd', name => 'ietd'}, {label => 'nfsd', name => 'nfsd'},{label => 'mountd', name => 'rpc.mountd'},{label=>'statd', name => 'rpc.statd'}] },
    				{ id => 'Execute', label => 'Executor', comps => [{ label => 'executor', name => 'kanopya-executor'}, {label => 'state-manager', name => 'kanopya-state-manager'}] },
    			],[
    				{ id => 'Monitor', label => 'Monitor', comps => [{ label => 'collector', name => 'kanopya-collector'}, { label => 'grapher', name => 'kanopya-grapher'}] },
    				{ id => 'Orchestrator', label => 'Orchestrator', comps => [{ label => 'orchestrator', name => 'kanopya-orchestrator'}] },
    			]
  			];
}

sub getStatus {
   		my $self = shift;
   		my %args = @_;
   		
   		my $grep = `ps aux | grep $args{proc_name}`;
    	my $ps_count = scalar (split(/\n/, $grep));
    	my $status = $ps_count > 2 ? 'Up' : 'Down';
		return $status;
}

sub xml_admin_status : Runmode {
	my $self = shift;
	my $session = $self->session;     
    my $admin_components = adminComponentsDef();
    
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
    
    # Check the status of admin components and build the html template var
    my $admin_components = adminComponentsDef();
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
     
    return $tmpl->output(); 
}

sub permission_denied : runmode {
	return "you dont have permission to access to this page";
}


sub view_logs : Runmode {
	my $self = shift;
	
	my @dirs_info = ();
	my $error_msg;
	my $logger_comp;
	my $admin_cluster = Entity::Cluster->get(id => 1);
	eval {
		$logger_comp = $admin_cluster->getComponent( category => 'Logger', name => 'Syslogng', version => 3 );
	};
	if ($@) {
		$log->warn("$@");
		$error_msg = "Syslogng3 must be installed on admin cluster";
	} else {
		my @log_dirs = $logger_comp->getLogDirectories();
		
		for $path (@log_dirs) {
			my $dir_error;
			my @files_info = ();
			my $ls_output = `ls $path` or $dir_error = 1;
			if (not defined $dir_error) {
				# Select only files
				my @files = grep { -f "$path$_" } split(" ", $ls_output);
				# Built tmpl struct
				@files_info = map { { path=>$path, filename=>$_} } @files;
			}
			
			push @dirs_info, { path => $path, dir_locked => $dir_error, files => \@files_info };
		}
	}
	
	my $tmpl =  $self->load_tmpl('Systemstatus/view_logs.tmpl');
    $tmpl->param('TITLEPAGE' => "System Logs");
	$tmpl->param('MDASHBOARD' => 1);
	$tmpl->param('SUBMLOGS' => 1);
	$tmpl->param('username' => $self->session->param('username')); 
    $tmpl->param('dirs' => \@dirs_info);
    $tmpl->param('error_msg' => $error_msg);
 
    return $tmpl->output(); 
}

sub get_log : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	
	my $log_id = $query->param('log_id');

	my $log_str = `tail -50 $log_id`;
	
	$log_str = CGI::escapeHTML($log_str);
	#$log_str =~ s/\n/<br\/>/g;
	
	return $log_str;
}

1;
