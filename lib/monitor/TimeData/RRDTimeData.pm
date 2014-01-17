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

=pod
=begin classdoc

TODO

=end classdoc
=cut


package TimeData::RRDTimeData;
use base TimeData;

use strict;
use warnings;

use General;
use Data::Dumper;
use Kanopya::Config;

use TryCatch;
my $err;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("timedata");

my $dir;
my $rrd;
my $delete;
my $move;

#Quick solution to handle windows and linux
if ($^O eq 'MSWin32') {
    $dir    = 'C:\\tmp\\monitor\\TimeData\\';
    $rrd    = 'rrdtool.exe';
    $delete = 'del';
    $move   = 'move /Y';
} elsif ($^O eq 'linux') {
    $rrd    = '/usr/bin/rrdtool';
    $dir    = '/var/cache/kanopya/monitor/';
    $delete = 'rm';
    $move   = 'mv';
}

###################################################################################################
#########################################RRD MANIPULATION FUNCTIONS################################
###################################################################################################


=pod
=begin classdoc

This method create a RRD file.

Only name is mandatory. Default RRD configuration are: step = 60, 1 RRA with
1 PDP per CPD, and 1440 CDP (60x1x1440 = 86400scd/ 1 day).
Standard is 1 RRA and 1 DS per RRD
throws 'RRD creation failed' if the creation is a failure
§WARNING§: the code only catch the keyword 'ERROR' in the command return...

@param name
@param options
@param RRA
@param DS
@param skip_if_exists

=end classdoc
=cut

sub createTimeDataStore {
    #rrd creation example: system ('$rrd create target.rrd --start 1328190055
    #                                                      --step 300
    #                                                      DS:mem:GAUGE:600:0:671744
    #                                                      RRA:AVERAGE:0.5:12:24'
    #                             );

    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'name', 'collect_frequency', 'storage_duration' ],
                         optional => { 'skip_if_exists' => undef, time => undef });

    my $name = _formatName(name => $args{'name'});

    # Do nothing if rrd already exists and skip_if_exists option is set
    return if (-e $dir.$name && $args{'skip_if_exists'});

    my $RRA_chain;
    my $DS_chain;
    my $opts = '';

    #configure the heartbeat, number of CDP and step according to the configuration
    my $config;
    try {
        $config = _configTimeDataStore(collect_frequency => $args{collect_frequency},
                                       storage_duration  => $args{storage_duration});
    }
    catch ($err) {
        throw Kanopya::Exception(error => "$err");
    }

    #definition of the options. If unset, default rrd start time is (now -10s)
    if (defined $args{'options'}) {
        my $options = $args{'options'};

        if (defined $options->{start}) {
            $opts .= '-b '.$options->{'start'}.' ';
        } else {
            my $time = $args{time} || time();
            my $moduloTime = $time % 60;
            my $finalTime = $time - $moduloTime;
            $opts .= '-b '.$finalTime.' ';
        }

        if (defined $options->{step}) {
            $opts .= '-s '.$options->{'step'}.' ';
        } else {
            $opts .= '-s '.$config->{step}.' ';
        }
    } else {
        $opts .= '-s '.$config->{step}.' ';
        my $time = $args{time} || time();
        my $moduloTime = $time % 60;
        my $finalTime = $time - $moduloTime;
        $opts .= '-b '.$finalTime.' ';
    }

    #default parameter for Round Robin Archive
    my %RRA_params = (function => 'LAST', XFF => '0', PDPnb => '1', CDPnb => $config->{CDP});

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
    my %DS_params = (DSname => 'aggregate', type => 'GAUGE', heartbeat => $config->{heartbeat}, min => '0', max => 'U');

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
        #    $DSchain = 'DS'.$DSname.':'.$type.':'.$heartbeat.':'.$min.':'.$max;
        #}elsif ($type eq 'COMPUTE'){
        #    $DSchain = 'DS:'.$DSname.':'.$type.':'.$rpn;
        #}
    }

    #definition of the DS
    $DS_chain = 'DS:'.$DS_params{'DSname'}.':'.$DS_params{'type'}.':'.$DS_params{'heartbeat'}.':'.$DS_params{'min'}.':'.$DS_params{'max'};

    #final command
    my $cmd = $rrd.' create '.$dir.$name.' '.$opts.' '.$DS_chain.' '.$RRA_chain;

    $log->debug($cmd);
    $log->info("creating rrd $dir$name");

    #execution of the command
    my $exec = `$cmd 2>&1`;
    if (not defined $exec or $exec =~ m/^ERROR.*/){
        my $err = (defined $exec) ? $exec : 'RRDtool probably not installed.';
        throw Kanopya::Exception::Internal(
                  error => 'RRD creation failed: ' . $err
              );
    }
}




=pod
=begin classdoc

This method delete a RRD file.

@param name RRD name

=end classdoc
=cut

sub deleteTimeDataStore{
    my %args = @_;

    General::checkParams(args => \%args, required => ['name']);

    my $name = _formatName(name => $args{'name'});
    my $cmd = $delete.' '.$dir.$name;

    system ($cmd);
}


=pod
=begin classdoc

This method get info a RRD file.

@param name RRD name

=end classdoc
=cut

sub getTimeDataStoreInfo {
    my %args = @_;

    General::checkParams(args => \%args, required => ['name']);

    my $name = _formatName(name => $args{'name'});
    my $cmd = $rrd.' info '.$dir.$name;

    system ($cmd);
}


=pod
=begin classdoc

This method retrieve values from a RRD file.
Ff start and end are not specified, rrd fetch use start = now - 1 day and stop = now
Throws 'RRD fetch failed' if the fetch is a failure
§WARNING§: the code only catch the keyword 'ERROR' in the command return...

@param name
@param start
@param end

@return values

=end classdoc
=cut


sub fetchTimeDataStore {
    my %args = @_;
    General::checkParams(args => \%args, required => ['name']);

    my $name = _formatName(name => $args{'name'});
    my $CF    = 'LAST';
    my $start = $args{'start'};
    my $end   = $args{'end'};
    my $cmd   = $rrd.' fetch '.$dir.$name.' '.$CF;

    #if not defined, start is (end - 1 day), and end is (now)
    if (defined $start){
        $cmd .= ' -s '.$start;
    }
    if (defined $end){
        $cmd .= ' -e '.$end;
    }

    $log->debug($cmd);

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
    #we split the string into an array
    my @values = split(' ', $exec);
    #print Dumper(\@values);
    #The first entry is the DS' name. We remove it from the list.
    shift (@values);
    #print Dumper(\@values);
    #We convert the list into the final hash that is returned to the caller.
    my %values = @values;

    if (scalar(keys %values) == 0) {
        throw  Kanopya::Exception::Internal(error => 'no values could be retrieved from RRD');
    }

    #we replace the '-1.#IND000000e+000' values for "undef"
    while (my ($timestamp, $value) = each %values) {
        if (($value eq '-1.#IND000000e+000') or ($value eq '-nan')){
            $values{$timestamp} = undef;
            }
    }
    #$log->debug(Dumper(\%values));
    return %values;
}


=pod
=begin classdoc

This method update values into a RRD file.
throws 'RRD update failed' if the update is a failure
WARNING: the code only catch the keyword 'ERROR' in the command return...

@param clustermetric_id
@param time
@param value

@return values

=end classdoc
=cut

sub updateTimeDataStore {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'clustermetric_id', 'time', 'time_step', 'storage_duration' ]);

    my $time = $args{'time'};
    my $name = _formatName(name => $args{'clustermetric_id'});

    TimeData::RRDTimeData::createTimeDataStore(skip_if_exists    => 1,
                                               name              => $args{'clustermetric_id'},
                                               collect_frequency => $args{'time_step'},
                                               storage_duration  => $args{'storage_duration'},
                                               time              => $args{time});

    my $datasource = (defined $args{'datasource'}) ? $args{'datasource'} : 'aggregate';
    my $value      = (defined $args{'value'})      ? $args{'value'}      : 'U';

    my $cmd = $rrd.' updatev '.$dir.$name.' -t '.$datasource.' '.$time.':'.$value;
#    $log->debug($cmd);
    # print $cmd."\n";

    my $exec =`$cmd 2>&1`;
    # print $exec."\n";
#    $log->debug($exec);

    if ($exec =~ m/^ERROR.*/) {
        throw Kanopya::Exception::Internal(error => 'RRD update failed: '.$exec);
    }
}


=pod
=begin classdoc

This method get the last updated value into a RRD file.
throw 'RRD fetch failed for last updated value' if the fetch is a failure
Warning the code only catch the keyword 'ERROR' in the command return...

@param metric_uid

@optional fresh_only return undef if last value date is < now - heartbeat

@return %values

=end classdoc
=cut

sub getLastUpdatedValue {
    my %args = @_;
    General::checkParams(args => \%args, required => ['metric_uid'], optional => {fresh_only => undef});

    my $name = _formatName(name => $args{'metric_uid'});

    my $cmd = $rrd.' lastupdate '.$dir.$name;

    my $exec =`$cmd 2>&1`;

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

    if (scalar(keys %values) == 0) {
        throw  Kanopya::Exception::Internal(error => 'no values could be retrieved from RRD');
    }

    my $heartbeat = 0;
    if ($args{fresh_only}) {
        $cmd = $rrd.' info '.$dir.$name;
        my $res = `$cmd`;
        if ($res =~ /minimal_heartbeat = (\d+)/) {
            $heartbeat = $1;
        }
    }

    #we replace the '-1.#IND000000e+000' values for "undef"
    # and we keep only fresh value if wanted
    while (my ($timestamp, $value) = each %values) {
        if ($value eq '-1.#IND000000e+000' || $value eq 'U') {
            $values{$timestamp} = undef;
        }
        if ($args{fresh_only} && (time() - $timestamp > $heartbeat)) {
            delete $values{$timestamp};
        }
    }


    #print Dumper(\%values);
#    $log->debug(Dumper(\%values));
    return %values;
}


=pod
=begin classdoc

This method grows or shrink a rrd

@param storage_duration
@param old_storage_duration
@param collect_frequency
@param clustermetric_id

=end classdoc
=cut

sub resizeTimeDataStore {
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'storage_duration', 'old_storage_duration',
                                       'collect_frequency', 'clustermetric_id' ]);

    my $new_duration = $args{storage_duration};
    my $rrd_name     = _formatName(name => $args{clustermetric_id});

    #get collect frequency value
    my $collect_frequency = $args{collect_frequency};
    my $old_duration      = $args{old_storage_duration};

    my $delta       = abs($new_duration - $old_duration);
    my $resize_type = ($new_duration > $old_duration) ? 'GROW' : 'SHRINK';

    #Generate the CPD number to be added or remove and then resize the rrd
    #grow
    if ($delta != 0) {
        my $CDPDiff = $delta / $collect_frequency;
        my $cmd     = qq{$rrd resize $dir$rrd_name 0 $resize_type $CDPDiff};

        #resize the rrd
        my $exec = `cd $dir && $cmd 2>&1`;
        #replace old rrd by newly generated resize.rrd
        my $mv   = qq{$move resize.rrd $dir$rrd_name};
        $exec    = `cd $dir && $mv 2>&1`;
    }
    #do nothing
    else {
        return 'the requested new stogare duration is the same than the old one'."\n";
    }

}

#########################################################################################################
#########################################INNER FUNCTIONS#################################################
#########################################################################################################


=pod
=begin classdoc

This method configure the step, heartbeat, and CDP number for a rrd

@param storage_duration Storing time desired

@param collect_frequency (if storage_duration not defined) Frequency desired

@return \%config

=end classdoc
=cut

sub _configTimeDataStore {
    my %args = @_;

    my %config;

    #NOTE: the two first case should not happen, because the configuration
    #file will at least hold the setup default values (furthermore, a null
    #value in the configuration file markups would result in a code error
    #at parsing

    #if the frequency only is defined, we generate CDP number and heartbeat 
    #in this case, by default we will set the rrd to store data for 1 week
    if (defined $args{collect_frequency} && ! defined $args{storage_duration}) {
        $config{step}      = $args{collect_frequency};
        $config{CDP}       = 604800 / $config{step};
        $config{heartbeat} = $config{step} * 2; 
    }
    #if the storage duration only is defined, we generate step, heartbeat, and CDP number
    #step by default will be 5 mn
    elsif (defined $args{storage_duration} && ! defined $args{collect_frequency}) {
        $config{step}      = 300 ;
        $config{CDP}       = $args{storage_duration} / $config{step};
        $config{heartbeat} = $config{step} * 2; 
    }
    #if both storage duration and frequency are defined, we generate heartbeat and CDP number
    elsif (defined $args{collect_frequency} && defined $args{storage_duration}) {
        $config{step}      = $args{collect_frequency};
        $config{CDP}       = $args{storage_duration} / $config{step};
        $config{heartbeat} = $config{step} * 2; 
    }
    else {
        throw Kanopya::Exception::Internal(
            error => 'A collect frequency and/or a storage duration must be available to TimeData'
        );
    }

    return \%config;
}


=pod
=begin classdoc

This method format a name argument for RRD.
'name' => timeDB_name.rrd

@param string name

@return formated name

=end classdoc
=cut

sub _formatName {
    my %args = @_;
    my $name = 'timeDB_'.$args{'name'}.'.rrd';
    return $name;
}

1;
