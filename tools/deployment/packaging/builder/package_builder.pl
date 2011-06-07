#!/usr/bin/perl -W
#    Copyright 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 10 feb 2011

#This script handle the generation of kanopya's packages (.deb)
#@Args: package's name
#Conf: the package's conf file must contain path relatives to $orig_kanopya_dir
#Please read the comments for more explanations

use strict;
use warnings;

if (!$ARGV[0]) {
    print "usage: package_builder.pl <package name>, e.g: ./package_builder.pl lib.pl\n";
    exit;
}

############################# Init vars
#package to build#
my $package = $ARGV[0];

#version of the package to build
my $version;
if ($ARGV[1]){
    $version = $ARGV[1];
    print "Version directly send by cmd line\n";
}

#dir where to build packages#
my $temp_kanopya_dir = "/tmp/kanopya";
#dir where is stored kanopya's source code#
my $orig_kanopya_dir = "/opt/kanopya";
#packages directory path
my $kanopya_packages = $orig_kanopya_dir."/tools/deployment/packaging";
#this script's home directory:
my $building_dir = $kanopya_packages.'/builder';
#package's debian directory path#
my $kanopya_debian = $kanopya_packages.'/'.$package.'/debian';
#print $kanopya_debian."\n";
unless ( -d $temp_kanopya_dir ){mkdir $temp_kanopya_dir}
#we prompt for version update

print "Building $package \n";
print "Do you want to update the changelog of the package? [y/n]: ";
my $prompt = <STDIN>;
chomp($prompt);
if ($prompt eq 'y'){
    if (! $version){
        print "What is the version you want to publish ?\n";
        $version = <STDIN>;
        chomp($version);
    }
    print "VERSION IS $version";
    print "Please be sure to respect the changelog convention as described on the Hedera's wiki\n";
    chdir $kanopya_debian;
    system('export DEBEMAIL="dev@hederatech.com"; export DEBFULLNAME="Hedera Dev Team" ;debchange --increment --distribution stable  --urgency low --check-dirname-level 0');
#    system('debchange -v $version'."-1");
    chdir $building_dir;
}
my $line;
print "Open $kanopya_debian/changelog\n";
open my $changelog,"<","$kanopya_debian/changelog";
$line=<$changelog>;
#
print "LINE IS $line\n";
my $this='(\d*\.\d*\.\d*)';
my @f=grep /$this/,$line;
$f[0] =~ $this;
$version = $1;
close $changelog;

#package's directory#
my $this_package = $temp_kanopya_dir."/".$package."-".$version;

mkdir $this_package;
#parse configuration file#
open my $package_conf,"<", "$package.conf" or die "open: $!";

while( $line = <$package_conf> )
{
    chomp ($line);
    my $final = $this_package."".$line;
    #we gather directories - lines ended by a "/" in the conf file#
    if ( $line =~ m/\/$/){
        system ("mkdir -p $this_package$line");
        system ("cp -r $orig_kanopya_dir$line* $this_package$line");
    #we gather files that are not directories#
    #script is static and find files under sbin, conf, and scripts/init directories#
    }else{
        my @values = split('/', $line);
        my $file_nb = scalar @values -1;
        my $filename = $values[$file_nb];
        print "Copy file named <$filename> ";
        delete $values[$file_nb];
        my $dir = join('/',@values);
        print "in relative directory <$dir>\n";
        system ("mkdir -p $this_package/$dir");
        system ("cp $orig_kanopya_dir$line $this_package/$dir/$filename");
    }
}
close($package_conf);
#we add debian directory to the package#
system("cp -r $kanopya_debian $this_package/debian");

#we now run the debuild utility#
chdir $this_package;
system ("debuild -us -uc");

#we archive the logs of the build#
my $build_logs = $this_package."-logs";
mkdir $build_logs;
chdir $temp_kanopya_dir;

system ('cp -r *.dsc *.build *.changes '.$ARGV[0].'_'.$version.'.tar.gz '.$build_logs);
system ("tar czf $build_logs.tar.gz $build_logs");
system ("rm -rf $build_logs");
