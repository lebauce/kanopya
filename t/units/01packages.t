#!/usr/bin/perl -w

################################################################
# This test search all perl modules in kanopya lib directories #
#  and do a use_ok on each                                     #
################################################################

use strict;
use warnings;

use File::Find;

use Kanopya::Config;

my $kanopya = Kanopya::Config::getKanopyaDir;

my @kanopyalibs = ($kanopya . '/lib/administrator',
                   $kanopya . '/lib/common',
                   $kanopya . '/lib/executor',
                   $kanopya . '/lib/external',
                   $kanopya . '/lib/monitor',
                   $kanopya . '/lib/orchestrator',
                   glob($kanopya . "/lib/component/*")); 

# find all perl modules files

my @perlmodules = (); 

for my $lib (@kanopyalibs) {
    my @modules = ();
    find(sub { push @modules, $File::Find::name if /\.pm$/ }, $lib);
    push @perlmodules, map { $_ =~ s/$lib\///g; $_ } @modules;
    @perlmodules = map { $_ =~ s/\//::/g; $_ } @perlmodules;
    @perlmodules = map { $_ =~ s/\.pm//g; $_ } @perlmodules;
}

# begin the test                
                
use lib @kanopyalibs;

use Test::More;
plan tests => scalar(@perlmodules); 

for my $module (@perlmodules) {
    use_ok( "$module" );
}


