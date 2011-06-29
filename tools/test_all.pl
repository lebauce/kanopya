#!usr/bin/perl
#
# USAGE: perl test_all.pl [dir]
# [dir] is the name of a subdir in t/ with some test files
# without dir test all file under t/*

use lib </opt/kanopya/lib/*>;

use Test::Harness qw(&runtests);

my $test_dir = shift || "*";

@test_files = </opt/kanopya/t/$test_dir/*.t>;

runtests @test_files;
