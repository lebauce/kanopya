#!/usr/bin/perl -w
use strict;
use warnings;

my $version = "";

print "Do you want to specify a global version for all packages (y/n)?\n";
my $want_version = <STDIN>;
chomp($want_version);
if ($want_version eq "y"){
	print "What is the new version ? X.Y.Z (X : major version number, Y : sprint number, Z : release number\n";
	$version = <STDIN>;
	chomp($version);
    }
open my $package_list,"<", "build_list" or die "open: $!";
my $line;
while ($line = <$package_list>) {
    chomp($line);
    print "./package_builder.pl $line $version\n";
    system("./package_builder.pl $line $version");
}

close $package_list;
