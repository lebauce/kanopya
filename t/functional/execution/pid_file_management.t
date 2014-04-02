#!/usr/bin/perl -w

=pod
=begin classdoc

Start/stop Kanopya daemons and make sure the PID files are correctly handled

=end classdoc
=cut

use strict;
use warnings;

use IO::File;
use IPC::Cmd;
use Test::More tests => 8;

my $pidfile = '/var/run/kanopya-executor.pid';
main();

sub main {
    prepare();
    my $old_pid = test_normal_operation();
    test_with_old_pid($old_pid);
}

sub _executor_pids() {
    return split /\s/, `pidof -x kanopya-executor`;
}

sub _read_file($) {
    my ($file) = @_;
    # http://www.perl.com/pub/2003/11/21/slurp.html
    return do { local( @ARGV, $/ ) = $file ; <> } ;
}

sub _pidfile_contains_valid_pid {
    my ($pid_in_file) = @_;
    unless (defined $pid_in_file) {
        $pid_in_file = _read_file($pidfile);
    }
    if (!defined($pid_in_file)) {
        note("pid_in_file is undef !");
    }
    # note("now testing what we find in the executor PID list. PID in file is: '${pid_in_file}'");
    # note("executor pids are: ".join(', ', _executor_pids()));
    foreach my $pid (_executor_pids()) {
        if ($pid eq $pid_in_file) {
            return 1;
        }
    }
    return 0;
}

sub prepare {
    foreach my $binary ('service', 'pidof') {
        unless (IPC::Cmd::can_run($binary)) {
            die "Did not find the program '$binary'. Abandoning this test suite.";
        }
    }
    if (-e $pidfile) {
        note("Kanopya Executor seems to be still running");
    }
    system("service kanopya-executor stop");
    unlink $pidfile if -e $pidfile;
    is(scalar(_executor_pids()), 0, 'Kanopya Executor is not running');
}

sub test_normal_operation {
    system("service kanopya-executor start");
    ok(-e $pidfile, 'PID file created');
    
    my $old_pid = _read_file($pidfile);
    ok(_pidfile_contains_valid_pid($old_pid), 'PID file contains the right value');
    
    system("service kanopya-executor stop");
    ok(! -e $pidfile, 'PID file has been deleted');
    is(scalar(_executor_pids()), 0, 'Kanopya Executor is not running');
    
    return $old_pid;
    # TODO: write old value into the PID file, see how it reacts
}

sub test_with_old_pid($) {
    my ($old_pid) = @_;
    ok(! -e $pidfile, 'PID file must not exist');
    
    my $pid_fh = IO::File->new($pidfile, 'w');
    $pid_fh->print($old_pid);
    $pid_fh->close();
    
    system("service kanopya-executor start");
    ok(_pidfile_contains_valid_pid(), 'PID file contains the right value even after manipulation.');
    
    system("service kanopya-executor stop");
    ok(! -e $pidfile, 'PID file must not exist');
}