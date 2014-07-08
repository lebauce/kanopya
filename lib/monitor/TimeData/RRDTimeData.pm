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
use RRDTool::OO;

use TryCatch;
my $err;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("timedata");

my $dir    = '/var/cache/kanopya/monitor/';
my $rrd    = '/usr/bin/rrdtool';
my $delete = 'rm';
my $move   = 'mv';

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;
    return $self;
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
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'name', 'time_step', 'storage_duration' ],
                         optional => { 'skip_if_exists' => undef, time => undef });

    my $name = $self->_formatName(name => $args{'name'});

    # Do nothing if rrd already exists and skip_if_exists option is set
    return if (-e $dir.$name && $args{'skip_if_exists'});


    #configure the heartbeat, number of CDP and step according to the configuration
    my $config;
    try {
        $config = $self->_configTimeDataStore(time_step => $args{time_step},
                                              storage_duration  => $args{storage_duration});
    }
    catch ($err) {
        throw Kanopya::Exception(error => "$err");
    }

    my $rrdoo = RRDTool::OO->new(file => $dir.$name);

    my $time = $args{time} || time();
    my $finalTime = $time - ($time % 60) - $args{time_step};

    $rrdoo->create(
        step => $args{time_step},
        start => $finalTime,
        data_source => {
            name => 'aggregate',
            type => 'GAUGE',
            min => '0',
            max => 'U',
            heartbeat =>$config->{heartbeat},
        },
        archive => {
            rows => $args{storage_duration} / $args{time_step},
            cfunc => 'LAST',
            xff => 0
        },
    );
    return;
}


=pod
=begin classdoc

This method delete a RRD file.

@param name RRD name

=end classdoc
=cut

sub deleteTimeDataStore {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['name']);

    my $name = $self->_formatName(name => $args{'name'});
    if (-e $dir.$name) {
        my $cmd = $delete.' '.$dir.$name;
        return system ($cmd);
    }

    return;
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
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['name', 'start', 'end'],
                         optional => {output => 'hash'});

    my $name = $self->_formatName(name => $args{'name'});
    my $CF    = 'LAST';

    #if not defined, start is (end - 1 day), and end is (now)
    my $end = $args{end};
    my $start = $args{start};

    my $rrdoo = RRDTool::OO->new(file => $dir.$name);

    try {
        $rrdoo->fetch_start(start => ($start - 1), end => $end, cfunc => $CF);
    }
    catch ($err) {
        throw  Kanopya::Exception::Internal(error => 'no values could be retrieved from RRD');
    }

    my $data = $rrdoo->{fetch_data};
    my $start_time = $rrdoo->{fetch_time_current};
    my $step = $rrdoo->{fetch_time_step};

    my @timestamps = map {$start_time + $_ * $step} (0..scalar @$data - 1);
    my @values = map {pop $_} @$data;

    while ($timestamps[-1] > $end) {
        pop @values;
        pop @timestamps;
    }

    if (defined $args{output} && $args{output} eq 'arrays') {
        return {
            timestamps => \@timestamps,
            values     => \@values,
        }
    }

    my %hvalues;
    while (@timestamps) {
        $hvalues{pop @timestamps} = pop @values;
    }

    return \%hvalues;
}


=pod
=begin classdoc

This method update values into a RRD file.
throws 'RRD update failed' if the update is a failure
WARNING: the code only catch the keyword 'ERROR' in the command return...

@param metric_id
@param time
@param value

@return values

=end classdoc
=cut

sub updateTimeDataStore {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'metric_id', 'time'],
                         optional => {datasource        => 'aggregate',
                                      value             => 'U',
                                      time_step         => undef,
                                      storage_duration  => undef});

    if (not (-e $dir.$self->_formatName(name => $args{metric_id}))) {
        $self->createTimeDataStore(name              => $args{metric_id},
                                   time_step         => $args{time_step},
                                   storage_duration  => $args{storage_duration},
                                   time              => $args{time});
    }

    my $rrdoo = RRDTool::OO->new(file => $dir . $self->_formatName(name => $args{metric_id}));
    $rrdoo->update(time => $args{time}, values => [$args{value}]);
    return;
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
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['metric_uid'], optional => {fresh_only => undef});

    my $name = $self->_formatName(name => $args{'metric_uid'});

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

    if (scalar(@values) == 0) {
        throw  Kanopya::Exception::Internal(error => 'no values could be retrieved from RRD');
    }


    my $timestamp = $values[0];
    my $value     = $values[1];

    my $heartbeat = 0;
    if ($args{fresh_only}) {
        $cmd = $rrd.' info '.$dir.$name;
        my $res = `$cmd`;
        if ($res =~ /minimal_heartbeat = (\d+)/) {
            $heartbeat = $1;
        }
        if (time() - $timestamp > $heartbeat) {
            return {};
        }
    }


    #we replace the '-1.#IND000000e+000' values for "undef"
    # and we keep only fresh value if wanted
    if (defined $value && ($value eq '-1.#IND000000e+000' || $value eq 'U')) {
        $value = undef;
    }

    return {timestamp => $timestamp, value => $value};
}


=pod
=begin classdoc

This method grows or shrink a rrd

@param storage_duration
@param old_storage_duration
@param time_step
@param metric_id

=end classdoc
=cut

sub resizeTimeDataStore {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'storage_duration', 'old_storage_duration',
                                       'time_step', 'metric_id' ]);

    my $new_duration = $args{storage_duration};
    my $rrd_name     = $self->_formatName(name => $args{metric_id});

    #get collect frequency value
    my $time_step = $args{time_step};
    my $old_duration      = $args{old_storage_duration};

    my $delta       = abs($new_duration - $old_duration);
    my $resize_type = ($new_duration > $old_duration) ? 'GROW' : 'SHRINK';

    #Generate the CPD number to be added or remove and then resize the rrd
    #grow
    if ($delta != 0) {
        my $CDPDiff = $delta / $time_step;
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

@param time_step (if storage_duration not defined) Frequency desired

@return \%config

=end classdoc
=cut

sub _configTimeDataStore {
    my ($self, %args) = @_;

    my %config;

    #NOTE: the two first case should not happen, because the configuration
    #file will at least hold the setup default values (furthermore, a null
    #value in the configuration file markups would result in a code error
    #at parsing

    #if the frequency only is defined, we generate CDP number and heartbeat
    #in this case, by default we will set the rrd to store data for 1 week
    if (defined $args{time_step} && ! defined $args{storage_duration}) {
        $config{step}      = $args{time_step};
        $config{CDP}       = 604800 / $config{step};
        $config{heartbeat} = $config{step} * 2;
    }
    #if the storage duration only is defined, we generate step, heartbeat, and CDP number
    #step by default will be 5 mn
    elsif (defined $args{storage_duration} && ! defined $args{time_step}) {
        $config{step}      = 300 ;
        $config{CDP}       = $args{storage_duration} / $config{step};
        $config{heartbeat} = $config{step} * 2;
    }
    #if both storage duration and frequency are defined, we generate heartbeat and CDP number
    elsif (defined $args{time_step} && defined $args{storage_duration}) {
        $config{step}      = $args{time_step};
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

Return rrd directory.

@return string rrd directory

=end classdoc
=cut

sub getDir {
    return $dir;
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
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'name' ]);

    my $name = 'timeDB_'.$args{'name'}.'.rrd';
    return $name;
}


sub info {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args, required => [ 'name' ]);

    my $rrd = RRDTool::OO->new(file => $dir.$self->_formatName(name => $args{'name'}));
    my $info = $rrd->info();
    return { time_step => $info->{step},
             storage_duration => $info->{rra}->[0]->{rows} * $info->{step} };
}
1;
