# RRDTimeData.pm - Monitor object to store Time based values through RRD database

#    Copyright  © 2011 Hedera Technology SAS
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



####################################################################################################################
#########################################RRD MANIPULATION FUNCTIONS#################################################
####################################################################################################################

#create RRD file. Standard is 1 RRA, and 1 DS.
sub createTimeDataStore{
	#rrd creation example: system ('rrdtool.exe create target.rrd --start 1328190055 --step 300 DS:mem:GAUGE:600:0:671744 RRA:AVERAGE:0.5:12:24');
    my %args = @_;
    print Dumper(\%args);
	
    General::checkParams(args => \%args, required => ['name']); 
	
    my $dir          = 'C:\\opt\\kanopya\\t\\monitor\\'; 
    my $name         = 'timeDB_'.$args{'name'}.'.rrd';
    my $RRA_chain;
    my $DS_chain;
    my $opts = '';
	
    if (defined $args{'options'}){
        my $options = $args{'options'};

        #Definition of the options. Default start is (now - 10s), default step is (300s)
        if (defined $options->{start}) {
            $opts .= '-b '.$options->{'start'}.' ';
        }

        if (defined $options->{step}) {
            $opts .= '-s '.$options->{'step'};
        }
    }
	
    #default parameter for Round Robin Archive
    my %RRA_params = (function => 'LAST', XFF => '0.9', PDPnb => '1', CDPnb => '30');

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
    my %DS_params = (DSname => 'aggregate', type => 'GAUGE', heartbeat => '60', min => '0', max => 'U');

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
    print $cmd." \n";

    #execution of the command
    my $exec = `$cmd 2>&1`;
    if ($exec =~ m/^ERROR.*/){
        throw Kanopya::Exception::Internal(error => 'RRD creation failed: '.$exec);
    }		
#	or die "an error occured while trying to create the RRD: $?:$!";
}

#delete a RRD file.
sub deleteTimeDataStore{
    my %args = @_;

    General::checkParams(args => \%args, required => ['name']); 

    my $name = $args{'name'};
    my $cmd = 'del '.$name;

    system ($cmd);
}

#get info about a RRD file.
sub getTimeDataStoreInfo {
    my %args = @_;

    General::checkParams(args => \%args, required => ['name']); 

    my $name = $args{'name'}; 
    my $cmd = 'rrdtool.exe info '.$name;

    system ($cmd);	
}

#fetch values from a RRD file.
sub fetchTimeDataStore {
    my %args = @_;
    General::checkParams(args => \%args, required => ['name']); 

    my $name  = 'timeDB_'.$args{'name'}.'.rrd';
    my $CF    = 'LAST';
    my $start = $args{'start'};
    my $end   = $args{'end'};
    my $cmd   = 'rrdtool.exe fetch '.$name.' '.$CF;

    #if not defined, start is (end - 1 day), and end is (now)
    if (defined $start){ 
        $cmd .= ' -s '.$start;
    }
    if (defined $end){ 
        $cmd .= ' -e '.$end;
    }
	
    print $cmd."\n";

    #we store the ouput of the command into a string
    my $exec = `$cmd 2>&1`;
    #print "back quotes output:\n ".$return;

    if ($exec =~ m/^ERROR.*/){
        throw Kanopya::Exception::Internal(error => 'RRD fetch failed: '.$exec);
    }
	
    #clean the string of unwanted ":"
    $exec =~ s/://g;
    #we split the string into an array
    my @values = split(' ', $exec);
    print Dumper(\@values);
    #The first entry is the DS' name. We remove it from the list.
    shift (@values);
    #print Dumper(\@values);
    #We convert the list into the final hash that is returned to the caller.
    my %values = @values;
    return %values;
    #print Dumper(\%values);
}

sub updateTimeDataStore {
    my %args = @_;
    General::checkParams(args => \%args, required => ['aggregator_id', 'time', 'value']);

    my $name = 'timeDB_'.$args{'aggregator_id'}.'.rrd';
    #hardcoded generic DS name
    my $datasource = 'aggregate';
    my $time = $args{'time'};
    my $value = $args{'value'};

    my $dir  = 'C:\\opt\\kanopya\\t\\monitor\\'; 

    my $cmd = 'rrdtool.exe update '.$dir.$name.' -t '.$datasource.' '.$time.':'.$value;
    print $cmd."\n";

    my $exec =`$cmd 2>&1`;

    if ($exec =~ m/^ERROR.*/){
        throw Kanopya::Exception::Internal(error => 'RRD fetch failed: '.$exec);
    }	
}
1;