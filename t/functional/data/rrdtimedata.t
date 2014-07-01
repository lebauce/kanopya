  #!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Entity::Metric;

use Data::Dumper;
use TryCatch;
use Log::Log4perl qw(:easy get_logger);

use Kanopya::Database; Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );
use Kanopya::Tools::TestUtils 'expectedException';

use TimeData::RRDTimeData;

Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => __FILE__ . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

my $testing = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    general();
    fetchOptions();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub general {
    lives_ok {
        my $td = TimeData::RRDTimeData->new();
        my $name = 'rrdtimedata_test_'.time();
        my $rrd_name = $td->_formatName(name => $name);
        my $time_step = 60;
        my $storage_duration = 24*60*60;

        my $time = time();
        # Synchro data in the middle of 2 rrd values
        my $time_synchro = $time - ($time % $time_step) - 50*$time_step;
        $time = $time_synchro;

        my $file_path = $td->getDir() . $rrd_name;

        if (-e $file_path) {
            die '.rrd file should not exist'
        }

        $td->createTimeDataStore(
            name              => $name,
            time_step         => $time_step,
            storage_duration  => $storage_duration,
            time              => $time - 100*$time_step,
        );

        if (not (-e $file_path)) {
            die '.rrd file  should exist'
        }

        my $data = $td->fetchTimeDataStore(
            name => $name,
            start => $time,
            end  => $time + 5 * $time_step,
        );

        map { if (defined $_) {die 'All values should be undefined'} } values %$data;

        $td->updateTimeDataStore(
            metric_id        => $name,
            time             => $time,
            value            => $time,
        );

        $time += $time_step;

        $td->updateTimeDataStore(
            metric_id => $name,
            time      => $time,
            value     => $time,
        );

        # This second fetch will store the first one
        $data = $td->fetchTimeDataStore(
                    name => $name,
                    start => $time,
                    end  => $time + 5 * $time_step,
                );

        map { if (! defined $data->{$_}) {delete $data->{$_}} } keys %$data;

        if (scalar keys %$data != 1) {
            die 'Only one value should be defined'
        }

        my @timestamps = keys %$data;
        my $timestamp = pop @timestamps;

        if ($timestamp ne $time) {
            die 'the only data must be time '. $time . ' not ' . $timestamp;
        }

        my $value = $data->{$timestamp};
        if ($value - $time > 10**-5) {
            die 'Stored value must be close to given one';
        }

        my $start_time = $time;
        for my $i (1..100) {
            $time += $time_step;
            $td->updateTimeDataStore(
                metric_id => $name,
                time      => $time,
                value     => $time,
            );
        }

        $data = $td->fetchTimeDataStore(
                    name => $name,
                    start => $time - 100 * $time_step,
                    end  => $time,
                );

        $time = $start_time;

        for my $i (1..101) {
            if (! defined $data->{$time}) {
                die "data->{$time} should be defined ($i)";
            }
            if (($data->{$time} - $time) > 10**-5) {
                die "data->{$time} should eq <$time>, got <" . $data->{$time} . ">";
            }
            $time += $time_step;
        }

        $val = $td->getLastUpdatedValue(
                   metric_uid => $name,
               );

        if ($val->{timestamp} - $time > 10**-5 || $val->{value} - $time > 10**-5) {
            die 'Got <' . $val->{timestamp} . ' => ' . $val->{value}
                . '>, expected <' . $time . ' => ' . $time . '>';
        }

        for my $i (1..5) {
            if (defined $data->{$time}) {
                die "data->{$time} should not be defined. Got <" . $data->{$time} . ">";
                $time += $time_step;
            }
        }

        $td->deleteTimeDataStore(
            name => $name,
        );

        if (-e $file_path) {
            die '.rrd file should not exist'
        }

    } 'General RRDTimeData test';
}

sub fetchOptions {
    lives_ok {
        use Data::Dumper; #remove me
        $Data::Dumper::Sortkeys = 1;
        my $td = TimeData::RRDTimeData->new();
        my $time = time();
        my $name = 'rrdtimedata_test_'.$time;
        my $time_step = 60;
        my $storage_duration = 2*24*60*60; # 2 days
        my $time_synchro = $time - ($time % $time_step);

        $td->createTimeDataStore(
            name              => $name,
            time_step         => $time_step,
            storage_duration  => $storage_duration,
            time              => $time - 100*$time_step,
        );

        $time = $time_synchro;
        for my $i (1..100) {
            $td->updateTimeDataStore(
                metric_id => $name,
                time      => $time,
                value     => $time,
            );
            $time += $time_step;
           }

        expectedException {
            $td->fetchTimeDataStore(
                name  => $name,
                start => $time + 1,
                end   => $time - 1,
            );
        } 'Kanopya::Exception::Internal', 'start before end';

        my $fetch_hash = $td->fetchTimeDataStore(
                             name  => $name,
                             start => $time_synchro + $time_step,
                             end   => $time_synchro + 10 * $time_step
                         );


        my $fetch_array = $td->fetchTimeDataStore(
                              name   => $name,
                              start  => $time_synchro + $time_step,
                              end    => $time_synchro + 10 * $time_step,
                              output => 'arrays',
                          );

        if ((scalar keys %$fetch_hash) ne scalar @{$fetch_array->{timestamps}} ||
            (scalar keys %$fetch_hash) ne scalar @{$fetch_array->{values}}) {
                die 'Wrong hash / array dimentions';
        }

        for my $i (0..scalar @{$fetch_array->{timestamps}}-1) {
            if ($fetch_hash->{$fetch_array->{timestamps}[$i]} - $fetch_array->{values}[$i] > 10**-5) {
                die 'arrays output differs from hash output'
            }
        }

        for my $i (0..scalar @{$fetch_array->{timestamps}}-2) {
            if ($fetch_array->{timestamps}[$i + 1] - $fetch_array->{timestamps}[$i] ne $time_step) {
                die 'Timestamps are not rightly separated'
            }
        }

        if ($fetch_array->{timestamps}->[0] ne $time_synchro + $time_step) {
            die 'Wrong start value when start match timestamp'
        }
        if ($fetch_array->{timestamps}->[-1] ne $time_synchro + 10 * $time_step) {
            die 'Wrong end value when end match timestamp'
        }

        $fetch_array = $td->fetchTimeDataStore(
                   name   => $name,
                   start  => $time_synchro + $time_step + 1,
                   end    => $time_synchro + 10 * $time_step - 1,
                   output => 'arrays',
               );

        if ($fetch_array->{timestamps}->[0] ne $time_synchro + 2 * $time_step) {
            die 'Wrong start value when start does not match timestamp'
        }

        if ($fetch_array->{timestamps}->[-1] ne $time_synchro + 9 * $time_step) {
            die 'Wrong end value when end does not match timestamp'
        }

    } 'Fetch options';
}

1;
