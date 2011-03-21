#!/usr/bin/perl -W

#This script handle the generation of libkanopya-perl.deb
#@Author: Maxime <maxime.demoulin@hederatech.com>
#@Date: 10/02/11
#@Args: package's version number
#Conf: the package's conf file must contain path relatives to $orig_kanopya_dir
#See the comments near else condition

use strict;

#version number is mandatory#
if (!$ARGV[0] || !$ARGV[1]) {
	print "usage: package_builder.pl <package name> <package_version_number>, e.g: lib.pl 0.9\n";
	exit;
}

#package to build#
my $package = $ARGV[0];
#dir where to build packages#
my $temp_kanopya_dir = "/tmp/kanopya";
#dir where is stored kanopya's source code#
my $orig_kanopya_dir = "/opt/kanopya";
#debian directory path#
my $kanopya_debian = $orig_kanopya_dir."/tools/deployment/packaging/$package/debian/";
#print $kanopya_debian."\n";
unless ( -d $temp_kanopya_dir ){mkdir $temp_kanopya_dir}   
#package's directory#
my $this_package = $temp_kanopya_dir."/".$package."-".$ARGV[1];
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
		system ("cp -vr $orig_kanopya_dir$line* $this_package$line"); 
	#we gather files that are not directories#
	#script is static and find files under sbin, conf, and scripts/init directories#
	}else{
		my @values = split('/', $line);
		if ($values[1] eq "conf" || $values[1] eq "sbin"){
			system ("mkdir -p $this_package/$values[1]");
			system ("cp -v $orig_kanopya_dir$line $this_package/$values[1]/$values[2]");
		}elsif ($values[1] eq "scripts"){
			system ("mkdir -p $this_package/$values[2]");
			system ("cp -v $orig_kanopya_dir$line $this_package/$values[2]/$values[3]");
		}
	}
}
close(FILE);
#we add debian directory to the package#
system("cp -vr $kanopya_debian $this_package/debian");

#we now run the debuild utility#
chdir $this_package;
system ("debuild");

#we archive the logs of the build#
my $build_logs = $this_package."-logs";
mkdir $build_logs;
chdir $temp_kanopya_dir;
system ('cp -vr *.dsc *.build *.changes '.$ARGV[0].'_'.$ARGV[1].'.tar.gz '.$build_logs);
system ("tar czf $build_logs.tar.gz $build_logs"); 
system ("rm -rf $build_logs");
