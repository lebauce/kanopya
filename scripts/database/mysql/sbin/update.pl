# update.pl - run migrations for the MySQL database.
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

use strict;
use warnings;

use DatabaseMigration::Transient;
use Daemon;

my @running_services = @{ Daemon->runningDaemons() };
if (@running_services > 0) {
    foreach my $service (@running_services) {
        print STDERR "Still running: $service\n";
        die "Stop the services listed above before running migrations.";
    }
}

DatabaseMigration::Transient->runAll();