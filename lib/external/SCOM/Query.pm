#    Copyright 2011 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 3 july 2010

=head1 NAME

SCOM::Query - get performance counters values from a remote management server

=head1 SYNOPSIS

    my %counters = (
        'Memory'    => ['Available MBytes','PercentMemoryUsed'],
        'Processor' => ['% Processor Time'],
    );
    
    my $scom = SCOM::Query->new( server_name => $management_server_name );
    
    my $res = $scom->getPerformance(
        counters    => \%counters,
        start_time  => '2/2/2012 11:00:00 AM',
        end_time    => '2/2/2012 12:00:00 AM',
    );

=head1 DESCRIPTION

Retrieve in one request all wanted counters (only one remote connection).
Output hash is fashionable.

=head1 METHODS

=cut

package SCOM::Query;

use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    # TODO check args
    
    my $self = {};
    bless $self, $class;
    
    $self->{_management_server_name} = $args{server_name};
    #$self->{_set_execution_policy_cmd} = 'set-executionPolicy unrestricted'; ## WARNING to study
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
    
    my $wanted_attrs = defined $args{want_attrs} ? $args{want_attrs} 
                                                 : ['$pc.MonitoringObjectPath','$pc.ObjectName','$pc.CounterName','$pv.TimeSampled','$pv.SampleValue'];
    my ($line_sep, $item_sep) = ('DATARAW', '###');
    
    my $cmd = $self->_buildGetPerformanceCmd(
                counters            => $args{counters},
                monitoring_object   => $args{monitoring_object}, # optional
                start_time          => $args{start_time},
                end_time            => $args{end_time},
                want_attrs          => $wanted_attrs,
                line_sep            => $line_sep,
                item_sep            => $item_sep,
    );

    # Execute command
    my $cmd_res = $self->_execCmd(cmd => $cmd);

    # remove all \n (end of line and inserted \n due to console output)
    $cmd_res =~ s/\n//g; 

    # Die if something wrong
    die $cmd_res if ($cmd_res !~ 'DATASTART');

    # Build resulting data hash from cmd output
    my $h_res    = $self->_formatToHash( 
                                input           => $cmd_res,
                                line_sep        => $line_sep,
                                item_sep        => $item_sep,
                                items_per_line  => scalar(@$wanted_attrs),
                                #index_order    => [0,1,2,3,4],
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
        #$self->{_set_execution_policy_cmd},                                            # allow script execution
        map({ "import-module '$_' -DisableNameChecking" } @{$self->{_scom_modules}}),   # import modules without verb warning
        $self->{_scom_shell_cmd},                                                       # connect to scom shell on management server
        $args{cmd},                                                                     # SCOM cmd to execute (double quote must be escaped)
    );
    
    my $full_cmd = join(';', @cmd_list) . ";";
    
    # If full_cmd use scom snap-in (need scom skd on local)
    #my $cmd_res = `powershell $full_cmd`;
    
    # Else use remote snap-in
    my $cmd_res = `powershell invoke-command {$full_cmd} -ComputerName $self->{_management_server_name}`;
    
    return $cmd_res;
}

sub _buildGetPerformanceCmd {
    my $self = shift;
    my %args = @_;
    my @want_attrs  = @{$args{want_attrs}};
    my %counters    = %{$args{counters}};
    my $start_time  = $args{start_time};
    my $end_time    = $args{end_time};
    
    my @obj_criteria;
    while (my ($object_name, $counters_name) = each %counters) {
        push @obj_criteria,
            "(ObjectName='$object_name' and (" . join( ' or ', map { "CounterName='$_'" } @$counters_name) . "))";
    }
    my $criteria = join ' or ', @obj_criteria;
    
    if (defined $args{monitoring_object}) {
        my $target_criteria = join ' or ', map { "MonitoringObjectPath='$_'" } @{$args{monitoring_object}};
        $criteria = "($criteria) and ($target_criteria)";
    }
    
    my $want_attrs_str = join ',', @want_attrs;
    my $format_str = join $args{item_sep}, map { "{$_}" } (0..$#want_attrs);

    # TODO study better way: ps script template...
    my $cmd   = 'echo DATASTART;';
    $cmd     .= 'foreach ($pc in Get-PerformanceCounter -Criteria \"' . $criteria . '\")';
    #my $cmd  = 'foreach ($pc in Get-PerformanceCounter )';
    $cmd     .= '{ foreach ($pv in Get-PerformanceCounterValue -startTime \''. $start_time .'\' -endTime \''. $end_time .'\' $pc)';
    $cmd     .= '{ \"' . $args{line_sep} . $format_str . '\" -f ' . $want_attrs_str . '; } }';

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

    my $value_idx = defined $args{value_index} ? $args{value_index} : $args{items_per_line} - 1; # last item by default
    my @key_idx_order = defined $args{index_order} ? @{$args{index_order}} : (0..$args{items_per_line}-2);
    
    my %h_res;
    LINE:
    foreach my $line (split $args{line_sep}, $input) {
        my @items = split $args{item_sep}, $line;
        if ($args{items_per_line} != @items) {
            # TODO LOG WARNING !!
            next LINE;
        }
        my $h_update_str =     '$h_res' .
                            (join '', map { "{'$items[$_]'}" } @key_idx_order) .
                            "= '$items[$value_idx]';";
        eval($h_update_str);
    }
    
    return \%h_res;
}

1;
