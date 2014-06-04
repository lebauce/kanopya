# update.pl - run migrations for the MySQL database.
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

use strict;
use warnings;

use Daemon;
use DatabaseMigration::Transient;
use Getopt::Long;
use POSIX;

my $mark_as_applied_until;
GetOptions('mark_as_applied_until=s' => \$mark_as_applied_until);

if ($mark_as_applied_until) {
    if ($mark_as_applied_until eq 'now') {
        $mark_as_applied_until = POSIX::strftime("%Y%m%d%H%M", localtime(time));
    } elsif ($mark_as_applied_until !~ /^\d{12}$/) {
        showHelp();
        exit 1;
    }
    my $i = DatabaseMigration::Transient->markAsAppliedUntil($mark_as_applied_until);
    print(($i == 1 ? "$i migration" : "$i migrations")." marked as applied.\n");
    exit 0;
}

my @running_services = @{ Daemon->runningDaemons() };
if (@running_services > 0) {
    foreach my $service (@running_services) {
        print STDERR "Still running: $service\n";
        die "Stop the services listed above before running migrations.";
    }
}

DatabaseMigration::Transient->runAll();



sub showHelp() {
    print <<"HELP";
Usage: update.pl [ --mark_as_applied_until YearMonthDayHourMinute ]

Without arguments, apply all pending migrations.

With --mark_as_applied_until, does not execute any migration but
mark all migrations earlier or equal to the given time as applied.    
HELP
}