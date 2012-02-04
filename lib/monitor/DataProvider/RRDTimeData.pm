# RRDTimeData.pm - Monitor object to store Time based values through RRD database

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 20 august 2010

package RRDTimeData;

use TimeData;
use strict;
use warnings;
use General;
use Data::Dumper;

sub createTimeDataStore{

	#rrd creation example: system ('rrdtool.exe create target.rrd --start 1328190055 --step 300 DS:mem:GAUGE:600:0:671744 RRA:AVERAGE:0.5:12:24');
	my %args = @_;
	#print Dumper(\%args);
	
	General::checkParams(args => \%args, required => ['name', 'options', 'DS', 'RRA']); 
	
	my $name = $args{'name'};
	my $options = $args{'options'};
	my $DS = $args{'DS'};
	my $RRA = $args{'RRA'};
	my $DSchain;
		
	if ($DS->{'type'} eq 'GAUGE' or $DS->{'type'} eq 'COUNTER' or $DS->{'type'} eq 'DERIVE' or $DS->{'type'} eq 'ABSOLUTE') {
		$DSchain = 'DS:'.$DS->{'name'}.':'.$DS->{'type'}.':'.$DS->{'heartbeat'}.':'.$DS->{'min'}.':'.$DS->{'max'};
	}elsif ($DS->{'type'} eq 'COMPUTE'){
		$DSchain = 'DS:'.$DS->{'name'}.':'.$DS->{'type'}.':'.$DS->{'rpn'};
	}
	#print $DSchain."\n";
	my $RRAchain = 'RRA:'.$RRA->{'function'}.':'.$RRA->{'XFF'}.':'.$RRA->{'PDPnb'}.':'.$RRA->{'CPDnb'};
	#print $RRAchain."\n";
	my $opts = '-s '.$options->{'step'}.' -b '.$options->{'start'};
	#print $opts."\n";
	#print $name."\n";
	my $cmd = 'rrdtool.exe create '.$name.' '.$opts.' '.$DSchain.' '.$RRAchain;
	#print $cmd;
	
	system ($cmd);
}

sub deleteTimeDataStore{
	my %args = @_;
	
	General::checkParams(args => \%args, required => ['name']); 
	
	my $name = $args{'name'};
	my $cmd = 'del '.$name;
	
	system ($cmd);
}

sub getTimeDataStoreInfo {
	my %args = @_;
	
	General::checkParams(args => \%args, required => ['name']); 
	
	my $name = $args{'name'}; 
	my $cmd = 'rrdtool.exe info '.$name;
	
	system ($cmd);	
}

sub fetchTimeDataStore {
	my %args = @_;
	General::checkParams(args => \%args, required => ['name', 'CF']); 
	
	my $name = $args{'name'};
	my $CF = $args{'CF'};
	my $start = $args{'start'};
	my $end = $args{'end'};
	
	my $cmd = 'rrdtool.exe fetch '.$name.' '.$CF;
	
	if (defined $start){ 
		$cmd .= ' -s '.$start;
	}
	if (defined $end){ 
		$cmd .= ' -e '.$end;
	}
	system ($cmd);
}

sub updateTimeDataStore {
	
}

sub checkDSParams {
	my %args = @_;
	#foreach (%args){ print "$_ => $args{$_}\n";}
	print Dumper(\%args);
	General::checkParams(args => \%args, required => ['name', 'type', 'heartbeat', 'RRA']); 

	foreach my $arg (\%args) {
		#print Dumper($arg);
	}

}

sub checkRRAParams {
	my %args = @_;
	General::checkParams(args => \%args, required => ['function', 'XFF', 'PDPnb', 'CDPnb']); 

}

1;