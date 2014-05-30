use strict;
use warnings;

=pod
=begin classdoc

A model for a database migration. Allows to run SQL and Perl migration files.

Instances of this class are NOT stored in the database. Instead, for each successful
migration, the method runAll() will persist one new instance of "DatabaseMigration".

Copyright © 2014 Hedera Technology SAS

@see <a href="http://www.kanopya.org/projects/mcs/wiki/Database_Migrations">Wiki:
Database Migrations</a>

@see <cpan>DBIx::Class::Migration</cpan> for some inspiration
(though we only cover a small part of that module)

=end classdoc
=cut

package DatabaseMigration::Transient;

use DatabaseMigration;
use File::Basename;
use File::Slurp;
use IO::Dir;
use IO::File;
use Kanopya::Config;
use Kanopya::Database;
use Kanopya::Exceptions;
use TryCatch;

=pod
=begin classdoc

@constructor

@param name (String) The name of this migration.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'name' ]);
                         
    my $self = { name => $args{name} };
    bless $self, $class;
    return $self;
}

=pod
=begin classdoc

@return (String) The name of this migration.

=end classdoc
=cut

sub name () {
    my ($self) = @_;
    return $self->{name};
}

=pod
=begin classdoc

Get or set the full path to the SQL script to run in this migration.

@param sql_script (String) If given, set the full path to the SQL script.

@return (String) If no parameter was given, return the full path to the SQL script.

=end classdoc
=cut

sub sql_script ($) {
    my ($self, $sql_script) = @_;
    if (defined $sql_script) {
        $self->{sql_script} = $sql_script;
    } else {
        return $self->{sql_script};
    }
}

=pod
=begin classdoc

Get or set the full path to the Perl script to run in this migration.

@param sql_script (String) If given, set the full path to the Perl script.

@return (String) If no parameter was given, return the full path to the Perl script.

=end classdoc
=cut

sub perl_script ($) {
    my ($self, $perl_script) = @_;
    if (defined $perl_script) {
        $self->{perl_script} = $perl_script;
    } else {
        return $self->{perl_script};
    }
}

=pod
=begin classdoc

Run this migration - execute SQL and Perl scripts.
Throws exceptions for errors.

=end classdoc
=cut

sub run () {
    my ($self) = @_;
    if (defined($self->{sql_script}) and -r $self->{sql_script}) {
        $self->runSQL();
    }
    if (defined($self->{perl_script}) and -r $self->{perl_script}) {
        $self->runPerl();
    }
}

=pod
=begin classdoc

Run the SQL script of this migration (which must exist).
Also, set up the "down" block for possibly undoing the migration later. 
Throws exceptions for errors.

=end classdoc
=cut

sub runSQL () {
    my ($self) = @_;
    $self->{down_sql} = [];
    my $sql_contents = read_file($self->{sql_script});
    
    # Based on DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator 0.002210
    my @sql = map { split /\n/, $_ } $sql_contents;
    for ( @sql ) {
        # trim whitespaces
        s/^\s+//gm;
        s/\s+$//gm;
        # remove blank lines
        s/^\n//gm;
    }
    
    my (@up_sql, @down_sql);
    {
        my $marker_found = 0;
        foreach my $sql_line (@sql) {
            if ($sql_line =~ /^--\s+DOWN\s+--$/) {
                $marker_found = 1;
            } else {
                if ($marker_found) {
                    push @down_sql, $sql_line;
                } else {
                    push @up_sql, $sql_line;
                }
            }
        }
        unless ($marker_found) {
            my $migration_base = basename($self->{sql_script});
            throw Kanopya::Exception(error => 
                "Migration $migration_base does not contain the \"-- DOWN --\" block");
        }
    }
    
    for ( @up_sql, @down_sql ) {
        # remove comments
        s/^--.*//gm;
    }
    
    # Delete all newlines except those at the end of a line.
    # Consequence: don't put several statements on the same line!
    # (or we'd need a real SQL parser)
    
    @up_sql   = @{_reformatSQL(\@up_sql)};
    @down_sql = @{_reformatSQL(\@down_sql)};
        
    $self->{down_sql} = \@down_sql;
    
    _executeSQLBlock(\@up_sql);
}

=pod
=begin classdoc

Private helper function.
Reformat SQL lines into statements. Just looks for combinations of
semicolons and linebreaks. You'd need a proper SQL parser to do this
better (e.g. recognise multiple SQL statements in one single line).

@param script_lines (Arrayref) A list of SQL script lines

@return (Arrayref) A list of SQL statements

=end classdoc
=cut

sub _reformatSQL ($) {
    my ($listref) = @_;
    return [ split(/;\n/, join("\n", @$listref)) ];        
}

=pod
=begin classdoc

Private helper function.
Execute the given bunch of SQL statements.
Throws an exception for a runtime error.

@param sql_statements (Arrayref) A list of SQL statments

=end classdoc
=cut

sub _executeSQLBlock ($) {
    my ($up_sql) = @_;
    my $storage = Kanopya::Database::schema()->storage();
    foreach my $line (@$up_sql) {
        next if $line eq '';
        $storage->_query_start($line);
        # the whole reason we do this is so that we can see the line that was run
        try {
            $storage->dbh_do (sub { $_[1]->do($line) });
        }
        catch {
            throw Kanopya::Exception(error => "$_ (running line '$line')");
        };
        $storage->_query_end($line);
    }
}

=pod
=begin classdoc

Run the DOWN block of this migration.

You must have called run() or runSQL() before calling this method.

=end classdoc
=cut

sub runDownSQL {
    my ($self) = @_;
    unless (defined($self->{down_sql})) {
        throw Kanopya::Exception(error => "First you must run the migration before doing the cleanup!");
    }
    _executeSQLBlock($self->{down_sql});
}

=pod
=begin classdoc

Run the Perl script of this migration (which must exist).

=end classdoc
=cut

sub runPerl {
    my ($self) = @_;
    do $self->{perl_script};
    if ($@ || $!) {
        throw Kanopya::Exception(error => ($@ || $!));
    }    
}

=pod
=begin classdoc

Class or object method.

@return (String) The full path to the migration directory

=end classdoc
=cut

sub migrationsDirectory {
    my ($clob) = @_;
    return Kanopya::Config->getKanopyaDir()."/scripts/database/mysql/migrations";
}

=pod
=begin classdoc

Class method. Scan the migrations directory for all migrations,
filter out those that have been run, and sort and return the rest.

@return (Arrayref) A list of DatabaseMigration::Transient objects to run.

=end classdoc
=cut

sub sortedPending {
    my ($class) = @_;
    
    my @sorted_pending_migrations = ();
    my $migrations_dir_str = $class->migrationsDirectory;
    my $migrations_dir = IO::Dir->new($migrations_dir_str);
    if (defined $migrations_dir) {
        my %migrations;
        {
            my $dir_entry;
            while ($dir_entry = $migrations_dir->read()) {
                if ($dir_entry =~ /^([\d_\-]+.+)\.(sql|pl)$/) {
                    my ($name, $suffix) = ($1, $2);
                    unless (exists $migrations{$name}) {
                        $migrations{$name} = $class->new(name => $name);
                    }
                    my $full_path = "${migrations_dir_str}/${dir_entry}";
                    if ($suffix eq 'sql') {
                        $migrations{$name}->sql_script($full_path);
                    } else {
                        $migrations{$name}->perl_script($full_path);
                    }
                }
            }
        }
        
        foreach my $past_migration (DatabaseMigration->search()) {
            delete $migrations{$past_migration->name()};        
        }

        foreach my $pending_migration_name (sort(keys(%migrations))) {
            print STDERR "Pushing: $pending_migration_name\n";
            push @sorted_pending_migrations, $migrations{$pending_migration_name};
        }
    }
    return \@sorted_pending_migrations;
}

=pod
=begin classdoc

Class method. Run all pending migrations.
Exceptions get caught, informational messages are printed to STDOUT.

=end classdoc
=cut

# Class method: Run all pending migrations.
sub runAll {
    
    # Nested transactions should work, see
    # https://metacpan.org/pod/DBIx::Class::Manual::Cookbook#Nested-transactions-and-auto-savepoints
    my ($class) = @_;
    Kanopya::Database::global_user_check(value => 0);
        
    my @migrations = @{$class->sortedPending()};
        
    foreach my $migration (@migrations) {
        try {
            Kanopya::Database::beginTransaction();
            print "Running migration: ".$migration->name()."\n";
            $migration->run();
            DatabaseMigration->new(name => $migration->name());
            Kanopya::Database::commitTransaction();
            print "Migration ".$migration->name()." run successfully.\n";
        } catch ($err) {
            print "Migration encountered an error.\n$err\nRolling back the database.\n";
            Kanopya::Database::rollbackTransaction();
            print "Running the cleanup block in its own transaction.\n";
            try {
                Kanopya::Database::beginTransaction();
                print "Running CLEANUP migration for: ".$migration->name()."\n";
                $migration->runDownSQL();
                Kanopya::Database::commitTransaction();
                print "Cleanup migration ".$migration->name().
                    " run.\nNOT ALL MIGRATIONS HAVE RUN SUCCESSFULLY !\n";
            } catch ($err) {
                Kanopya::Database::rollbackTransaction();
                print "Cleanup migration encountered an error.\n$err\n".
                    "CLEANUP MIGRATION FAILED - BASE NEEDS MANUAL CLEANUP !\n";
            }
            last;
        }
    }
    Kanopya::Database::global_user_check(value => 1);
}

1;