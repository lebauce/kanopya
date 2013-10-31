#!/usr/bin/perl

use Hash::Merge;
use YAML;
# use YAML::Tiny;
use Data::Dumper;

Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );

local $YAML::UseHeader = 0;
local $YAML::Stringify = 1;
local $YAML::UseFold = 1;
local $YAML::UseBlock = 1;

my $yaml = {};

for my $file(@ARGV) {
    $yaml = Hash::Merge::merge($yaml, YAML::LoadFile($file));
    # $yaml = Hash::Merge::merge($yaml, YAML::Tiny->read($file));
}

# print $yaml = YAML::Tiny->write_string($yaml);
print YAML::Dump($yaml);
