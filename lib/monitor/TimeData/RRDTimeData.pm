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
	
	General::checkParams(args => \%args, required => ['name', 'DS', 'RRA']); 
	
	my $name = $args{'name'};
	my $options = $args{'options'};
	my $DS = $args{'DS'};
	my $RRA = $args{'RRA'};
	my $DSchain;
	my $opts = '';
	
	#The DS syntax is different for the COMPUTE type, that's why we're checking the type here to form the command string
	if ($DS->{'type'} eq 'GAUGE' or $DS->{'type'} eq 'COUNTER' or $DS->{'type'} eq 'DERIVE' or $DS->{'type'} eq 'ABSOLUTE') {
		$DSchain = 'DS:'.$DS->{'name'}.':'.$DS->{'type'}.':'.$DS->{'heartbeat'}.':'.$DS->{'min'}.':'.$DS->{'max'};
	}elsif ($DS->{'type'} eq 'COMPUTE'){
		$DSchain = 'DS:'.$DS->{'name'}.':'.$DS->{'type'}.':'.$DS->{'rpn'};
	}
	
	#Definition of the options. Default start is (now - 10s), default step is (300s)
	if (defined $options->{start}) {
		$opts .= '-b '.$options->{'start'}.' ';
	}
	if (defined $options->{step}) {
		$opts .= '-s '.$options->{'step'};
	}

	#definition of the RRA
	my $RRAchain = 'RRA:'.$RRA->{'function'}.':'.$RRA->{'XFF'}.':'.$RRA->{'PDPnb'}.':'.$RRA->{'CPDnb'};


	#final command
	my $cmd = 'rrdtool.exe create '.$name.' '.$opts.' '.$DSchain.' '.$RRAchain;
	print $cmd." :\n";
	
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
	General::checkParams(args => \%args, required => ['name', 'CF']); 
	
	my $name = $args{'name'};
	my $CF = $args{'CF'};
	my $start = $args{'start'};
	my $end = $args{'end'};
	
	my $cmd = 'rrdtool.exe fetch '.$name.' '.$CF;
	
	#if not defined, start is (end - 1 day), and end is (now)
	if (defined $start){ 
		$cmd .= ' -s '.$start;
	}
	if (defined $end){ 
		$cmd .= ' -e '.$end;
	}
	
	print $cmd.": \n";
	
	#we store the ouput of the command into a string
	my $return = `$cmd`;
	#print "back quotes output:\n ".$return;

    print "WARNING ERRORS NOT CHECKED \n"; 
    #TODO
#	if ($exec =~ m/^ERROR.*/){
#		throw Kanopya::Exception::Internal(error => 'RRD fetch failed: '.$exec);
#	}
	
	#clean the string of unwanted ":"
	$return =~ s/://g;
	#we split the string into an array
	my @values = split(' ', $return);
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
    _updateTimeDataStore (name => 'timeDB_'.$args{aggregator_id}.'.rrd', datasource => $args{aggregator_id}, time => $args{time}, value =>$args{value})
}

#Feed a rrd.
sub _updateTimeDataStore {
	my %args = @_;
	General::checkParams(args => \%args, required => ['name', 'datasource', 'time', 'value']); 
	
	my $name = $args{'name'};
	my $datasource = $args{'datasource'};
	my $time = $args{'time'};
	my $value = $args{'value'};
	
	my $cmd = 'rrdtool.exe updatev '.$name.' -t '.$datasource.' '.$time.':'.$value;
	print $cmd.": \n";
	
	system ($cmd);
	print "WARNING ERRORS NOT CHECKED \n";
    #TODO
#	if ($exec =~ m/^ERROR.*/){
#		throw Kanopya::Exception::Internal(error => 'RRD fetch failed: '.$exec);
#	}
}
1;