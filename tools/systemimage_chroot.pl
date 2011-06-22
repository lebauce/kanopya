#!/usr/bin/perl -w

# microcluster chroot environment to customize system image
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);
use strict;
use warnings;
use Term::ReadKey;
use Administrator;
use Entity::Systemimage;

my $currentuser = `whoami`;
chomp($currentuser);
if($currentuser ne 'root') {
    die("You must be root to use this script.\n");
}

my $lsof = `which fuser`;
if(!$lsof) {
    die("fuser command not found but required !\n");  
}

my ($sysimg_name) = @ARGV;
if(not defined $sysimg_name) {
	print "We must specify systemimage name to chroot ; this systemimage must be deactivated\n";
	print "Usage: systemimage_chroot.pl sysimage_name \n";
	exit 1;
} 

my ($login, $passwd);
print "User login : ";
chomp($login = <STDIN>);
print "password for login $login : ";
ReadMode('noecho');
chomp($passwd = <STDIN>);
ReadMode('original');

Administrator::authenticate(login => $login, password => $passwd);

my $admin = Administrator->new();
my @systemimages = Entity::Systemimage->getSystemimages(hash => {systemimage_name => $sysimg_name});
if(not scalar @systemimages) {
	die("System image $sysimg_name not found !\n");
} elsif(scalar @systemimages > 1) {
	die("BUG : several system images found with name $sysimg_name !\n");
} 

my $systemimage = pop @systemimages;

if($systemimage->getAttr(name => 'active')) {
    die($sysimg_name." is still active. Deactivate it before using this script.\n");
}

my $devices = $systemimage->getDevices();
my $root_device = "/dev/".$devices->{root}->{vgname}."/".$devices->{root}->{lvname};
my $etc_device = "/dev/".$devices->{etc}->{vgname}."/".$devices->{etc}->{lvname};

#my $row = $admin->{db}->resultset('Iscsitarget1Target')->search(
#	{iscsitarget1_target_name => { like => "%root_$sysimg_name" }})->single;

#my $root_target = $row->get_column('iscsitarget1_target_name');

if(! -e $root_device) {
    print "Device for rootdisk $root_device no found.\n";
    exit 1;
}
if(! -e $etc_device) {
    print "Device for etcisk $etc_device no found.\n";
    exit 1;
}

system("clear");
print "#######################################################\n";
print "   :: System Image <$sysimg_name> Customization ::\n";
print "#######################################################\n";

# we mount all devices

if(! -e '/mnt/chroot') { 
	mkdir '/mnt/chroot';
	mkdir '/mnt/chroot/etc';
}

if(! -e '/mnt/chroot/etc') { 
	mkdir '/mnt/chroot/etc';
}

print "mounting $root_device on /mnt/chroot...";
my $out = `mount $root_device /mnt/chroot`;
print "done\n";

print "mounting $etc_device on /mnt/chroot/etc...";
$out = `mount $etc_device /mnt/chroot/etc`;
print "done\n";

print "mounting procsfs on /mnt/chroot/proc...";
$out = `mount -t proc proc /mnt/chroot/proc`;
print "done\n";

print "mounting sysfs on /mnt/chroot/sys...";
$out = `mount -t sysfs sysfs /mnt/chroot/sys`;
print "done\n";

print "mounting devpts on /mnt/chroot/dev/pts...";
$out = `mount -t devpts devpts /mnt/chroot/dev/pts`;
print "done\n";

$out = `echo $sysimg_name > /mnt/chroot/etc/debian_chroot`;

# we chroot in the new environment 
print "starting the new environment\n";
system("/usr/sbin/chroot /mnt/chroot /bin/bash"); 

# after exiting the chroot...      
print "flush file system buffers\n";
system('sync');

print "kill processes launched from chroot environment... ";
$out = `fuser -skm /mnt/chroot`;
print "done\n";
 
print "umount devpts... ";
$out = `umount /mnt/chroot/dev/pts`;
print "done\n";

print "umount sysfs... ";
$out = `umount /mnt/chroot/sys`;
print "done\n";

print "umount procfs... ";
$out = `umount /mnt/chroot/proc`;
print "done\n";

print "umount etc container... ";
$out = `umount /mnt/chroot/etc`;
print "done\n";

print "umount root container...";
$out = `umount /mnt/chroot`;
print "done\n";



   