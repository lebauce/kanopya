package ScomQuery;

use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

	# TODO check args
	
    my $self = {};
    bless $self, $class;
    
    $self->{_management_server_name} = $args{server_name};
	$self->{_set_execution_policy_cmd} = 'set-executionPolicy unrestricted'; ## WARNING to study
	$self->{_scom_modules} = [
		'C:\Program Files\System Center Operations Manager 2007\Microsoft.EnterpriseManagement.OperationsManager.ClientShell.dll',
		'C:\Program Files\System Center Operations Manager 2007\Microsoft.EnterpriseManagement.OperationsManager.ClientShell.Functions.ps1',	
	];
	$self->{_scom_shell_cmd} = 'Start-OperationsManagerClientShell -managementServerName: ' . $self->{_management_server_name} . ' -persistConnection: $false -interactive: $false';
    
    return $self;
}

sub getPerformance {
	my $self = shift;
    my %args = @_;
	
	my $wanted_attrs = 	defined $args{want_attrs} ? $args{want_attrs} 
						                          : ['$pc.MonitoringObjectPath','$pc.ObjectName','$pc.CounterName','$pv.TimeSampled','$pv.SampleValue'];
	
	my $cmd = $self->_buildGetPerformanceCmd(
				counters 	=> $args{counters},
				start_time	=> $args{start_time},
				end_time	=> $args{end_time},
				want_attrs 	=> $wanted_attrs,
	);

	print $cmd;

	my $cmd_res = $self->_execCmd(cmd => $cmd);

	# remove all \n (end of line and inserted \n due to console output)
	$cmd_res =~ s/\n//g; 

	# Build resulting data hash from cmd output
	my $h_res	= $self->_formatToHash( 
								input => $cmd_res,
								line_sep => 'DATARAW',
								item_sep => ',',
								items_per_line => scalar(@$wanted_attrs),
								#index_order => [0,1,2,3,4],
	);
	
	return $h_res;
}

sub getcounters {
	
}

# Build a power shell command to execute a SCOM command on management server
sub _execCmd {
	my $self = shift;
	my %args = @_;
	
	my @cmd_list = (
		$self->{_set_execution_policy_cmd},							# allow script execution
		map({ "import-module '$_'" } @{$self->{_scom_modules}}), 	# import modules
		$self->{_scom_shell_cmd},									# connect to scom shell on management server
		$args{cmd},									 				# SCOM cmd to execute (double quote must be escaped)
	);
	
	my $full_cmd = join(';', @cmd_list) . ";";
	
	# If full_cmd use scom snap-in
	#my $cmd_res = `powershell $full_cmd`;
	
	# Else use remote snap-in
	my $cmd_res = `powershell invoke-command {$full_cmd} -ComputerName $self->{_management_server_name}`;
	
	return $cmd_res;
}

sub _buildGetPerformanceCmd {
	my $self = shift;
	my %args = @_;
	my @want_attrs 	= @{$args{want_attrs}};
	my %counters 	= %{$args{counters}};
	my $start_time	= $args{start_time};
	my $end_time	= $args{end_time};
	
	# TODO criteria "((obj and (counter or counter)) or (obj and (counter)))" intead of "((obj or obj) and (counter or counter or counter))"
	my $object_criteria 	= join ' or ', map { "ObjectName='$_'" } keys %counters;
	my $counter_criteria 	= join ' or ', map { "CounterName='$_'" } map { @$_ } values %counters;
	my $criteria = "($object_criteria) and ($counter_criteria)";
	my $want_attrs_str = join ',', @want_attrs;
	my $format_str = join ',', map { "{$_}" } (0..$#want_attrs);

	# TODO study better way: ps script template...	
	my $cmd  = 'foreach ($pc in Get-PerformanceCounter -Criteria \"' . $criteria . '\")';
	#my $cmd  = 'foreach ($pc in Get-PerformanceCounter )';
	$cmd 	.= '{ foreach ($pv in Get-PerformanceCounterValue -startTime \''. $start_time .'\' -endTime \''. $end_time .'\' $pc)';
	$cmd	.= '{ \"DATARAW' . $format_str . '\" -f ' . $want_attrs_str . '; } }';

	return $cmd;
}

# Parse string and build correponding hash
# String has multi lines separated by line_sep
# each line has data separated by item_sep
# resulting hash is build in this way: $h{item_0}{item_1}{item_2}{...} = value
# with item_x = item at pos $key_idx_order[x] 
# and value = item at pos $value_idx 
sub _formatToHash {
	my $self = shift;
	my %args = @_;
	my $input = $args{input};

	my $value_idx = $args{value_index} // $args{items_per_line} - 1; # last item by default
	my @key_idx_order = defined $args{index_order} ? @{$args{index_order}} : (0..$args{items_per_line}-2);
	
	my %h_res;
	LINE:
	foreach my $line (split $args{line_sep}, $input) {
		my @items = split ',', $line;
		next LINE if ($args{items_per_line} != @items);
		my $h_update_str = 	'$h_res' .
							(join '', map { "{'$items[$_]'}" } @key_idx_order) .
							"= '$items[$value_idx]';";
		eval($h_update_str);
	}
	
	return \%h_res;
}

1;
