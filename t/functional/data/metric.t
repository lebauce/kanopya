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

    simple_metric();
    rrd_metric();
    formula_metric();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub simple_metric {
    lives_ok {
        my $metric = Entity::Metric->new();

        if ($metric->_hasFormula) {
            die 'Metric should not have formula';
        }
        if ($metric->_hasStore) {
            die 'Metric should not have storage';
        }
        expectedException {
            $metric->_timedata;
        } 'Kanopya::Exception::Internal', 'Metric should not have _timedata';

        expectedException {
            $metric->computeFormula(values => {});
        } 'Kanopya::Exception::Internal', 'ComputeFormula should not be available';

        expectedException {
            $metric->evaluate;
        } 'Kanopya::Exception::Internal', 'evaluate should not be available';

        expectedException {
            $metric->evaluateTimeSerie(start_time => time(), stop_time => time());
        } 'Kanopya::Exception::Internal', 'evaluateTimeSerie should not be available';

        expectedException {
            $metric->fetch;
        } 'Kanopya::Exception::Internal', 'fetch should not be available';

        expectedException {
            $metric->lastData;
        } 'Kanopya::Exception::Internal', 'lastData should not be available';

        expectedException {
            $metric->lastValue;
        } 'Kanopya::Exception::Internal', 'lastValue should not be available';

        expectedException {
            $metric->resetData;
        } 'Kanopya::Exception::Internal', 'resetData should not be available';

        expectedException {
            $metric->resizeData(storage_duration     => 60*60,
                                old_storage_duration => 60*60,
                                time_step            => 60);
        } 'Kanopya::Exception::Internal', 'resizeData should not be available';

        expectedException {
            $metric->updateData(time => time());
        } 'Kanopya::Exception::Internal', 'updateData should not be available';

        if ($metric->getUnit ne '') {
            die 'Generic metric unit is an empty string';
        }

        $metric->delete();
    } 'Simple Entity::Metric testing'
}

sub rrd_metric {
    lives_ok {
        expectedException {
            Entity::Metric->new(store => 'sql');
        } 'Kanopya::Exception::Internal::IncorrectParam', 'only rrd storage is available';

        my $metric = Entity::Metric->new(store => 'rrd');

        if ($metric->_hasFormula) {
            die 'RRD metric should not have formula';
        }

        if (! $metric->_hasStore) {
            die 'RRD metric should have storage';
        }

        $timedata = $metric->_timedata;

        if (! $timedata->isa('TimeData::RRDTimeData')) {
            die 'TimeData must be TimeData::RDDTimeData';
        }

        expectedException {
            $metric->computeFormula(values => {});
        } 'Kanopya::Exception::Internal', 'ComputeFormula should not be available';

        expectedException {
            $metric->updateData();
        } 'Kanopya::Exception::Internal::MissingParam', 'Need time_step if db not created';

        my $time_step = 5;
        expectedException {
            $metric->updateData(time => $time_step);
        } 'Kanopya::Exception::Internal::MissingParam', 'Need storage_duration if db not created';


        my $time = time();
        my $time_synchro = $time - $time % $time_step + $time_step;

        sleep(5);

        $metric->updateData(time_step => $time_step, storage_duration => 60, time => $time_synchro);
        $time_synchro += 5;

        if (defined $metric->lastValue) {
            die 'lastValue should not be defined'
        }

        sleep(5);

        $metric->updateData(
            time  => $time_synchro,
            value => 100,
        );
        $time_synchro += 5;

        sleep(5);

        my $data       = $metric->lastData();
        my $value      = $metric->lastValue();
        my $evaluation = $metric->evaluate();

        if ((! defined $data->{value}) || $data->{value} ne 100
             || (! defined $value) || $value ne 100
             || (! defined $evaluation) || $evaluation ne 100) {
            die 'Wrong last data or value';
        }

        $metric->updateData(
            time  => $time_synchro,
            value => 100,
        );

        sleep(5);

        my %timeserie = $metric->evaluateTimeSerie(start_time => $time_synchro - 11,
                                                   stop_time  => $time_synchro + 1);

        if (scalar keys %timeserie ne 3) {
            die 'Wrong number of values';
        }

        if ((! exists $timeserie{$time_synchro-10})
            || (! exists $timeserie{$time_synchro-5})
            || (! exists $timeserie{$time_synchro})) {
            die 'Wrong timestamps';
        }

        if (defined $timeserie{$time_synchro-10}
            || (! defined $timeserie{$time_synchro-5})
            || $timeserie{$time_synchro-5} ne 100
            || $timeserie{$time_synchro} ne 100) {
            die 'Wrong values';
        }


        my $lastData = $metric->lastData();
        if ($lastData->{value} ne 100 && $lastData->{timestamp} ne $time_synchro) {
            die 'Wrong last data';
        }

        my $lastValue = $metric->lastValue();
        if ($lastValue ne 100) {
            die 'Wrong last value';
        }


        my $fetch = $metric->fetch(start_time => $time_synchro - 11,
                                    stop_time  => $time_synchro + 1);

        if ((! exists $fetch->{$time_synchro-10})
            || (! exists $fetch->{$time_synchro-5})
            || (! exists $fetch->{$time_synchro})) {
            die 'Wrong timestamps fetch';
        }

        if (defined $fetch->{$time_synchro-10}
            || (! defined $fetch->{$time_synchro-5})
            || $fetch->{$time_synchro-5} ne '100'
            || $fetch->{$time_synchro} ne '100') {
            die 'Wrong values fetch';
        }


        my $db_name = $metric->_timedata->_formatName(name => $metric->id);
        my $file_path = $metric->_timedata->getDir() . $db_name;

        $metric->delete();

        if (-e $file_path) {
            die "RRD <$file_path> should have been deleted";
        }

    } 'Test rrd metric';
}

sub formula_metric {
    lives_ok {
        my $metric = Entity::Metric->new(formula => 'id1 * id3');
        my $res = $metric->computeFormula(values => {1 => 2});

        if (defined $res) {
            die "formula computation should not be possible because one value is missing"
        }

        $res = $metric->computeFormula(values => {1 => 2, 3 => 3});

        if (! defined $res || $res ne 6) {
            die "formula computation should be equals to 6"
        }

        $metric->delete();
    } 'Test formula metric';
}