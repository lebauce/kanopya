#!/usr/bin/perl -W

#This script handle the generation of kanopya's packages (.deb)
#@Author: Maxime <maxime.demoulin@hederatech.com>
#@Date: 10/02/11
#@Args: package's name
#Conf: the package's conf file must contain path relatives to $orig_kanopya_dir
#Please read the comments for more explanations

use strict;

#version number is mandatory#
if (!$ARGV[0]) {
	print "usage: package_builder.pl <package name>, e.g: ./package_builder.pl lib.pl\n";
	exit;
}

#package to build#
my $package = $ARGV[0];
#version of the package to build
my $version;
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
        print "Please be sure to respect the changelog convention as described on the Hedera's wiki\n";
        chdir $kanopya_debian;
        system('debchange --increment');
        open(F,"$kanopya_debian/changelog");
        my $line=<F>;close F;
        #gather the full version (valid for ubuntu package and so forth)
        #my $this='(\(\d*\.\d*.*\))';
        #gather only version number, valid for Debian)
        my $this='(\d*\.\d*)';
        my @f=grep /$this/,$line;
        $f[0] =~ $this; 
        $version = $1;
	chdir $building_dir;
}elsif ($prompt eq 'n'){
        print "Old version will be kept \n";
        open(F,"$kanopya_debian/changelog");
        my $line=<F>;close F;
        #gather the full version (valid for ubuntu package and so forth)
        #my $this='(\(\d*\.\d*.*\))';
        #gather only version number, valid for Debian)
        my $this='(\d*\.\d*)';
        my @f=grep /$this/,$line;
        $f[0] =~ $this; 
        $version = $1;
}
#package's directory#
my $this_package = $temp_kanopya_dir."/".$package."-".$version;
#print $this_package."\n";
mkdir $this_package;
#parse configuration file#
open(FILE,"<$package.conf") or die "open: $!";
my $line;
LINE:
while( defined( $line = <FILE> ) )
{
	chomp ($line);	
	if ($line eq "none"){ last LINE; }
	my $final = $this_package."".$line;
	#we gather directories - lines ended by a "/" in the conf file#
	if ( $final =~ m/\/$/){
		system ("mkdir -p $final");
		system ("cp -r $orig_kanopya_dir$line* $this_package$line"); 
	#we gather files that are not directories#
	#script is static and find files under sbin, conf, and scripts/init directories#
	}else{
		my @values = split('/', $line);
		if ($values[1] eq "conf" || $values[1] eq "sbin"){
			system ("mkdir -p $this_package/$values[1]");
			system ("cp $orig_kanopya_dir$line $this_package/$values[1]/$values[2]");
		}elsif ($values[1] eq "scripts"){
			system ("mkdir -p $this_package/$values[2]");
			system ("cp $orig_kanopya_dir$line $this_package/$values[2]/$values[3]");
		}
	}
}
close(FILE);
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
