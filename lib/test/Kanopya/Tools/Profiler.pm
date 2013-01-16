# Copyright © 2013 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Kanopya module for profiling tools.

@since 15/01/2013
@instance hash
@self $self

=end classdoc

=cut

package Kanopya::Tools::Profiler;
use base qw<DBIx::Class::Storage::Statistics>;

use strict;
use warnings;

use General;

use Data::Dumper qw<Dumper>;
use Time::HiRes qw(time);
use Benchmark qw(:all);

my $stats;


=pod

=begin classdoc

Return an instance of the kanopya profiler.

@param schema the database schema

@optional print_queries option to display query when excecuted
@optional no_report option to activate automatic report at end

@return a kanopya profiler instance

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'schema' ],
                         optional => { 'print_queries' => 0, 'no_report' => 0 });

    if(not defined $stats) {
        # See also BEGIN { $ENV{DBIC_TRACE} = 1 }
        $args{schema}->storage->debug(1);

        # Create an instance of our subclassed (see below)
        # DBIx::Class::Storage::Statistics class
        $stats = $class->SUPER::new();

        # Set the debugobj object on our schema's storage
        $args{schema}->storage->debugobj($stats);
    }

    $stats->{active}  = 0;
    $stats->{count}   = undef;
    $stats->{elapsed} = undef;
    $stats->{queries} = {};
    $stats->{options} = {
        printqueries => $args{print_queries},
        noreport     => $args{no_report},
    };

    $stats->{querystart} = undef;
    $stats->{totalstart} = undef;
    $stats->{totalend}   = undef;

    bless $stats, $class;

    return $stats;
}


=pod

=begin classdoc

Override DBIx::Class::Storage::Statistics method.
It is a classback called before excecuting an sql query.
Count, display and time the excecuted sql queries between
calls to method start ans stop.

=end classdoc

=cut

sub query_start {
    my ($self, $sql_query, @params) = @_;

    if ($self->{active}) {
        if ($self->{options}->{printqueries}) {
            print "- Sql query: \n$sql_query\n\n";
        }

        my @words  = split (' ', $sql_query);
        my @from   = split ('FROM', $sql_query);
        my @tables = split (' ', $from[1]);
        my $table  = shift @tables;
        my $type   = shift @words;

        if (not defined $self->{queries}->{$table}) {
            $self->{queries}->{$table} = {};
        }
        if (not defined $self->{queries}->{$table}->{$type}) {
            $self->{queries}->{$table}->{$type} = 0;
        }
        $self->{queries}->{$table}->{$type} ++;

        $self->{count} ++;

        $self->{querystart} = time();
    }
}


=pod

=begin classdoc

Override DBIx::Class::Storage::Statistics method.
Increase the elapsed time of sql queries.

=end classdoc

=cut

sub query_end {
    my $self = shift();
    my $sql = shift();
    my @params = @_;

    if ($self->{active}) {
        $self->{elapsed} += (time() - $self->{querystart});

        $self->{querystart} = undef;
    }
}


=pod

=begin classdoc

Display a report of all metrics collected.

=end classdoc

=cut

sub report {
    my $self = shift();

    print "- Elapsed time            :" . timestr(timediff($self->{totalend}, $stats->{totalstart})) . "\n";
    print "- Number of sql queries   : " . $self->{count} . "\n";
    print "- Elapsed time in queries : " .  sprintf("%0.5f", $self->{elapsed}) . " s. \n";
    print "- Queries by table        : \n";
    for my $table (keys %{ $self->{queries} }) {
        print "    - " . $table . "\t: ";
        for my $type (keys %{ $self->{queries}->{$table} }) {
            print $type . " : " . $self->{queries}->{$table}->{$type} . ", "
        }
        print "\n";
    }
    print "\n";
}


=pod

=begin classdoc

Start profiling excecution, reset all metrics.

@optional print_queries option to display query when excecuted

=end classdoc

=cut

sub start {
    my $self = shift();
    my %args = @_;

    General::checkParams(args     => \%args,
                         optional => { 'print_queries' => 0 });

    $self->{options}->{printqueries} = $args{print_queries} || $self->{options}->{printqueries};
    
    $self->{count}   = 0;
    $self->{elapsed} = 0;
    $self->{queries} = {};

    $self->{querystart} = undef;
    $self->{totalend}   = undef;
    $self->{totalstart} = Benchmark->new;

    $self->{active}  = 1;
}


=pod

=begin classdoc

Stop profiling excecution.

@optional no_report option to activate automatic report at end

=end classdoc

=cut

sub stop {
    my $self = shift();
    my %args = @_;

    General::checkParams(args     => \%args,
                         optional => { 'no_report' => 0 });

    $self->{totalend} = Benchmark->new;
    $self->{active} = 0;
    
    if (not ($args{no_report} || $self->{options}->{noreport})) {
        $self->report();
    }
}

1;
