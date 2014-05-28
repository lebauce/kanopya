#!/usr/bin/perl -w

=pod
=begin classdoc

Test some database migrations. Does only operate on test tables.
Despite best efforts, only cleans up everything if tests are successful.

=end classdoc
=cut

use strict;
use warnings;

use DatabaseMigration::Transient;
use File::Glob;
use IO::Dir;
use IO::File;
use IPC::Cmd;
use Kanopya::Config;
use Kanopya::Database;
use Test::More tests => 7;

my $migration_basedir = DatabaseMigration::Transient->migrationsDirectory;
my $migration_base = "201405111624_migrationtest";

prepare();

###############################################################################

writeMigration('01.sql', <<"MIGRATION_TEST_1" );
CREATE TABLE migrations_test1 (
    name1   varchar(255),
    number1 int(8) unsigned
);
MIGRATION_TEST_1

like( runOutput(),
    qr/Migration 201405111624_migrationtest01.sql does not contain the "-- DOWN --" block/,
    "Migration without a DOWN block must fail" );

##############################################################################

writeMigration('01.sql', <<"MIGRATION_TEST_2" );
CREATE TABLE migrations_test1 (
    name1   varchar(255),
    number1 int(8) unsigned
);
-- intentionally broken, we want the DOWN migration to run
INSERT INTO migrations_test1
    (name1, number1) VALUES ('dupont', 30;

-- DOWN --
DROP TABLE IF EXISTS migrations_test1;
MIGRATION_TEST_2

like( runOutput(),
    qr/Cleanup migration 201405111624_migrationtest01 run./,
    "Migration must run the DOWN block" );

##############################################################################

writeMigration('01.sql', <<"MIGRATION_TEST_3" );
SELECT * FROM migrations_test1;
-- DOWN --
MIGRATION_TEST_3

like( runOutput(),
    qr/Migration encountered an error.+SELECT \* FROM migrations_test1/s,
    "Migration must fail due to non-existing table" );

##############################################################################

writeMigration('01.sql', <<"MIGRATION_TEST_4A" );
CREATE TABLE migrations_test1 (
    name1   varchar(255),
    number1 int(8) unsigned
);
INSERT INTO migrations_test1
    (name1, number1) VALUES ('dupont', 30);

-- DOWN --
DROP TABLE IF EXISTS migrations_test1;
MIGRATION_TEST_4A

writeMigration('01.pl', <<'MIGRATION_TEST_4B' );
use strict;
use warnings;
use Kanopya::Database;

my $dbh = Kanopya::Database::dbh;
my $sth = $dbh->prepare('SELECT name1 FROM migrations_test1');
my $rv  = $sth->execute;
my $arrayref = $sth->fetchrow_arrayref;
if ($arrayref->[0] eq 'dupont') {
    print "Perl migration found the expected value.\n";
}
MIGRATION_TEST_4B

like( runOutput(),
    qr/Perl migration found the expected value/,
    "Migration runs both SQL and Perl" );

writeMigration('02.sql', <<"MIGRATION_TEST_5" );
DROP TABLE migrations_test1;
-- DOWN --
MIGRATION_TEST_5

like( runOutput(),
    qr/Migration .+_migrationtest02 run successfully/,
    "Second migration drops table" );

cleanup();

##############################################################################

writeMigration('01.sql', <<"MIGRATION_TEST_6A" );
CREATE TABLE migrations_test1 (
    name1   varchar(255),
    number1 int(8) unsigned
);
INSERT INTO migrations_test1
    (name1, number1) VALUES ('dupont', 30);

-- DOWN --
DROP TABLE IF EXISTS migrations_test1;
MIGRATION_TEST_6A

writeMigration('01.pl', <<'MIGRATION_TEST_6B' );
use strict;
use warnings;
use Kanopya::Database;
use Kanopya::Exceptions;

my $dbh = Kanopya::Database::dbh;
my $sth = $dbh->prepare('SELECT name1 FROM migrations_test1');
my $rv  = $sth->execute;
my $arrayref = $sth->fetchrow_arrayref;
throw Kanopya::Exception(error => "voluntary error");
MIGRATION_TEST_6B

writeMigration('02.sql', <<"MIGRATION_TEST_6C" );
-- This migration must never run.
NONSENSE
MIGRATION_TEST_6C

my $output = runOutput();

like( $output, qr/Cleanup migration .+_migrationtest01 run/,
    "After failed Perl part of first migration, bring it down");

unlike( $output,
    qr/Running migration: .+_migrationtest02/,
    "After a failed first migration, the second one must not run" );

cleanup();
cleanup_final();

# end of main script, subroutines follow



sub writeMigration {
    my ($migration_suffix, $content) = @_;
    my $migration_file = IO::File->new(
        "${migration_basedir}/${migration_base}${migration_suffix}", 'w');
    $migration_file->print($content);
    $migration_file->close();
}

sub runOutput {
    my $output;
    IPC::Cmd::run(
        command => "/usr/bin/perl ${migration_basedir}/../sbin/update.pl",
        buffer  => \$output
    );
    return $output;
}

sub prepare {
    # Prepare a clean migration directory
    if (-d $migration_basedir) {
        # disable existing migrations by renaming them
        foreach my $suffix ('pl', 'sql') {
            foreach my $file_to_rename (File::Glob::bsd_glob("${migration_basedir}/*.${suffix}")) {
                rename $file_to_rename, "${file_to_rename}.migrationtest-disabled";
            }
        }
    } else {
        mkdir $migration_basedir; # empty directories do not make it into Git
    }

    system("perl ".Kanopya::Config->getKanopyaDir."/tools/kanopya_services.pl stop");
}

# Cleanup that can be called several times
sub cleanup {
    foreach my $file_to_remove (File::Glob::bsd_glob("${migration_basedir}/${migration_base}*")) {
        unlink $file_to_remove;
    }
    my $dbh = Kanopya::Database::dbh;
    my $cmd = "DELETE FROM database_migration WHERE name LIKE '${migration_base}%'"; 
    $dbh->do($cmd);
}

# Only call this once, at the very end.
sub cleanup_final {
    my %renamings;
    my $dir = IO::Dir->new($migration_basedir);
    my $file;
    while (defined($file = $dir->read)) {
        if ($file =~ /^(.*)\.migrationtest-disabled$/) {
            $renamings{$file} = $1;
        }
    }
    $dir->close();
    
    my $orig_file;
    while (($file, $orig_file) = each %renamings) {
        rename "${migration_basedir}/${file}", "${migration_basedir}/${orig_file}";
    }    
}