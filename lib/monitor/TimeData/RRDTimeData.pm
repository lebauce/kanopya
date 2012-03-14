# RRDTimeData.pm - Monitor object to store Time based values through RRD database

#    Copyright  © 2012, 2013, 2014 Hedera Technology SAS
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
# Created 03/02/2012

package RRDTimeData;

use base TimeData;
use strict;
use warnings;
use General;
use Data::Dumper;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("timedata");

my $dir = 'C:\\tmp\\monitor\\TimeData\\';

####################################################################################################################
#########################################RRD MANIPULATION FUNCTIONS#################################################
####################################################################################################################

=head2 createTimeDataStore

B<Class>   : Public
B<Desc>    : This method create a RRD file.
B<args>    : name, options, RRA, DS
B<Return>  : None
B<Comment> : Only name is mandatory. Default RRD configuration are: step = 60, 1 RRA with 1 PDP per CPD, and 1440 CDP (60x1x1440 = 86400scd/ 1 day). Standard is 1 RRA and 1 DS per RRD
B<throws>  : 'RRD creation failed' if the creation is a failure §WARNING§: the code only catch the keyword 'ERROR' in the command return...

=cut

sub createTimeDataStore{
	#rrd creation example: system ('rrdtool.exe create target.rrd --start 1328190055 --step 300 DS:mem:GAUGE:600:0:671744 RRA:AVERAGE:0.5:12:24');
    my %args = @_;
    $log->debug(Dumper(\%args));
	
    General::checkParams(args => \%args, required => ['name']); 
	
	my $name = _formatName(name => $args{'name'});

    my $RRA_chain;
    my $DS_chain;
    my $opts = '';
	
    #definition of the options. If unset, default rrd start time is (now -10s)
    if (defined $args{'options'}){
        my $options = $args{'options'};

        if (defined $options->{start}) {
            $opts .= '-b '.$options->{'start'}.' ';
        }else{
			my $time = time();
			my $moduloTime = $time % 60;
			my $finalTime = $time - $moduloTime;
			$opts .= '-b '.$finalTime.' ';
		}

        if (defined $options->{step}) {
            $opts .= '-s '.$options->{'step'}.' ';
        }else{
            $opts .= '-s 60 ';
        }
    }else{
            $opts .= '-s 60 ';
			my $time = time();
			my $moduloTime = $time % 60;
			my $finalTime = $time - $moduloTime;
			$opts .= '-b '.$finalTime.' ';
        }
	
    #default parameter for Round Robin Archive
    my %RRA_params = (function => 'LAST', XFF => '0', PDPnb => '1', CDPnb => '1440');

    if (defined $args{'RRA'}){
        my $RRA = $args{'RRA'};

        while (my ($param_name, $default_value) = each %RRA_params){
        if (defined $RRA->{$param_name}){
            $RRA_params{$param_name} = $RRA->{$param_name};
            }
        }		
    }
	
    #definition of the RRA
    $RRA_chain = 'RRA:'.$RRA_params{'function'}.':'.$RRA_params{'XFF'}.':'.$RRA_params{'PDPnb'}.':'.$RRA_params{'CDPnb'};

    #default parameter for Data Source
    my %DS_params = (DSname => 'aggregate', type => 'GAUGE', heartbeat => '120', min => '0', max => 'U');

    if (defined $args{'DS'}){
        my $DS = $args{'DS'};

        while (my ($param_name, $default_value) = each %DS_params){
        if (defined $DS->{$param_name}){
            $DS_params{$param_name} = $DS->{$param_name};
            }
        }			
        ############################################
        #COMPUTE TYPE IS NOT HANDLED BY THIS MODULE#
        ############################################
        #
        #The DS syntax is different for the COMPUTE type, that's why we're checking the type here to form the command string
        #if ($type eq 'GAUGE' or $type eq 'COUNTER' or $type eq 'DERIVE' or $type eq 'ABSOLUTE') {
        #	$DSchain = 'DS'.$DSname.':'.$type.':'.$heartbeat.':'.$min.':'.$max;
        #}elsif ($type eq 'COMPUTE'){
        #	$DSchain = 'DS:'.$DSname.':'.$type.':'.$rpn;
        #}	
    }
	
    #definition of the DS
    $DS_chain = 'DS:'.$DS_params{'DSname'}.':'.$DS_params{'type'}.':'.$DS_params{'heartbeat'}.':'.$DS_params{'min'}.':'.$DS_params{'max'};

    #final command
    my $cmd = 'rrdtool.exe create '.$dir.$name.' '.$opts.' '.$DS_chain.' '.$RRA_chain;
    # print $cmd."\n";
    $log->info($cmd);

    #execution of the command
    my $exec = `$cmd 2>&1`;
    if ($exec =~ m/^ERROR.*/){
        throw Kanopya::Exception::Internal(error => 'RRD creation failed: '.$exec);
    }		
}

=head2 deleteTimeDataStore

B<Class>   : Public
B<Desc>    : This method delete a RRD file.
B<args>    : name
B<Return>  : None
B<Comment>  : None
B<throws>  : None

=cut

sub deleteTimeDataStore{
    my %args = @_;

    General::checkParams(args => \%args, required => ['name']); 

    my $name = _formatName(name => $args{'name'}); 
    my $cmd = 'del '.$dir.$name;

    system ($cmd);
}

=head2 getTimeDataStoreInfo

B<Class>   : Public
B<Desc>    : This method get info a RRD file.
B<args>    : name
B<Return>  : None
B<Comment>  : None
B<throws>  : None

=cut

sub getTimeDataStoreInfo {
    my %args = @_;

    General::checkParams(args => \%args, required => ['name']); 

	my $name = _formatName(name => $args{'name'});
    my $cmd = 'rrdtool.exe info '.$dir.$name;

    system ($cmd);	
}

=head2 fetchTimeDataStore

B<Class>   : Public
B<Desc>    : This method retrieve values from a RRD file.
B<args>    : name, start, end
B<Return>  : %values
B<Comment> : if start and end are not specified, rrd fetch use start = now - 1 day and stop = now
B<throws>  : 'RRD fetch failed' if the fetch is a failure §WARNING§: the code only catch the keyword 'ERROR' in the command return...

=cut

sub fetchTimeDataStore {
    my %args = @_;
    General::checkParams(args => \%args, required => ['name']); 

    my $name = _formatName(name => $args{'name'});
    my $CF    = 'LAST';
    my $start = $args{'start'};
    my $end   = $args{'end'};
    my $cmd   = 'rrdtool.exe fetch '.$dir.$name.' '.$CF;

    #if not defined, start is (end - 1 day), and end is (now)
    if (defined $start){ 
        $cmd .= ' -s '.$start;
    }
    if (defined $end){ 
        $cmd .= ' -e '.$end;
    }
	
    $log->info($cmd);

    #we store the ouput of the command into a string
    my $exec = `$cmd 2>&1`;
    # print "back quotes output:\n ".$exec;

    if ($exec =~ m/^ERROR.*/){
        throw Kanopya::Exception::Internal(error => 'RRD fetch failed: '.$exec);
    }
	
    #clean the string of unwanted ":"
    $exec =~ s/://g;
	#replace the ',' by '.'
	$exec =~ s/,/./g;	
	#we replace the '-1.#IND000000e+000' values for 'undef'
	$exec =~ s/-1\.\#IND000000e\+000/undef/g;
    #we split the string into an array
    my @values = split(' ', $exec);
    #print Dumper(\@values);
    #The first entry is the DS' name. We remove it from the list.
    shift (@values);
    #print Dumper(\@values);
    #We convert the list into the final hash that is returned to the caller.
    my %values = @values;
    
    $log->debug(Dumper(\%values));
    return %values;   
}

=head2 updateTimeDataStore

B<Class>   : Public
B<Desc>    : This method update values into a RRD file.
B<args>    : clustermetric_id, time, value
B<Return>  : None
B<Comment> : None
B<throws>  : 'RRD update failed' if the update is a failure §WARNING§: the code only catch the keyword 'ERROR' in the command return...

=cut

sub updateTimeDataStore {
    my %args = @_;
    General::checkParams(args => \%args, required => ['clustermetric_id', 'time', 'value']);

    my $name = _formatName(name => $args{'clustermetric_id'});
    my $datasource;
    if (defined $args{'datasource'}){
        $datasource = $args{'datasource'};
    }else{
        $datasource = 'aggregate';
    }
    my $time = $args{'time'};
    my $value = $args{'value'};

    my $cmd = 'rrdtool.exe updatev '.$dir.$name.' -t '.$datasource.' '.$time.':'.$value;
    $log->debug($cmd);
    print $cmd."\n";

    my $exec =`$cmd 2>&1`;
    print $exec."\n";
    $log->debug($exec);

    if ($exec =~ m/^ERROR.*/){
        throw Kanopya::Exception::Internal(error => 'RRD update failed: '.$exec);
    }	
}

=head2 getLastUpdatedValue

B<Class>   : Public
B<Desc>    : This method get the last updated value into a RRD file.
B<args>    : clustermetric_id
B<Return>  : %values
B<Comment> : None
B<throws>  : 'RRD fetch failed for last updated value' if the fetch is a failure §WARNING§: the code only catch the keyword 'ERROR' in the command return...

=cut


sub getLastUpdatedValue {
    my %args = @_;
    General::checkParams(args => \%args, required => ['clustermetric_id']);

    my $name = _formatName(name => $args{'clustermetric_id'});
    
    my $cmd = 'rrdtool.exe lastupdate '.$dir.$name;
    $log->info($cmd);
    
    my $exec =`$cmd 2>&1`;
    #print $exec."\n";

    if ($exec =~ m/^ERROR.*/) {
        throw Kanopya::Exception::Internal(error => 'RRD fetch failed for last updated value: '.$exec);
    }	  
    
    #clean the string of unwanted ":"
    $exec =~ s/://g;
	#replace the ',' by '.'
	$exec =~ s/,/./g;
    #we split the string into an array
    my @values = split(' ', $exec);
    #print Dumper(\@values);
    #The first entry is the DS' name. We remove it from the list.
    shift (@values);
    # print Dumper(\@values);
    #We convert the list into the final hash that is returned to the caller.
    my %values = @values;
    #print Dumper(\%values);
    $log->debug(Dumper(\%values));
    return %values;
}

=head2 _formatName

B<Class>   : Public
B<Desc>    : This method format a name argument for RRD
B<args>    : None
B<Return>  : $name
B<Comment> : None
B<throws>  : None

=cut

sub _formatName {
	my %args = @_;
	my $name = 'timeDB_'.$args{'name'}.'.rrd';
	return $name;
}
1;