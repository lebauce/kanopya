#!/usr/bin/perl -W
#
# Script to create component package which can be deployed on kanopya
# Use a component package desc xml file
#
# Usage: perl package_component.pl <component_desc.xml>
#
use XML::Simple;

my $VERSION=0.1;

my $ROOT_PATH = "/opt/kanopya/";

my $component_xml_file = $ARGV[0];

if (not defined $component_xml_file) {
    print "Need a xml file as parameter\n";
    exit;
}

# Load xml
my $comp_info_ref = XMLin( "$component_xml_file", ForceArray => ['nas', 'executor'] );
my %comp_info = %$comp_info_ref;

my ($comp_name, $comp_version, $comp_cat) = ($comp_info{description}{name},$comp_info{description}{version},$comp_info{description}{category});
my $comp_fullname = $comp_name . $comp_version;
my $comp_name_lc = lc $comp_fullname;
my $archive_root_dir = "component_" . $comp_cat . "_" . $comp_fullname ;

# Temporary dir to be archived
`mkdir -p /tmp/$archive_root_dir`;

# Build file list
my @files = ();
for my $srv ('executor', 'nas') {
    if (defined $comp_info{$srv}) {
	push @files, ( map { $_->{src} } @{ $comp_info{$srv} }  );
    }
}

# Copy all files in a tmp directory (to have a root directory in the tar and manage tar content (tree) as we want)
print "Copy files...\n";
for my $file_path (@files) {
    my $tmp_dest = "/tmp/$archive_root_dir/\$(dirname $file_path)";
    # Create directory path in archive dir
    `mkdir -p $tmp_dest`;
    # Cp file following the same path
    my $ret = `cd .. && cp $file_path $tmp_dest`;
    if ($? != 0) {
	print "ERROR: file missing. stop\n";
	exit;
    }
}

# Add all files under templates dir
if ( -d "../" . $comp_info{templates_dir} ) {
    print "Copy template files...\n";
    my $tmp_dest = "/tmp/$archive_root_dir/$comp_info{templates_dir}";
    `mkdir -p $tmp_dest`;
    `cd .. && cp $comp_info{templates_dir}/* $tmp_dest`;
} else {
    print "No templates dir found ($comp_info{templates_dir}) => skip templates\n";
    delete $comp_info{templates_dir};
}

# Add desc file
`cp $component_xml_file /tmp/$archive_root_dir`;

# Tar directory and move tarball in this script dir (tools)
print "Create archive...\n";
my $tar_name = $archive_root_dir . ".tar";
`cd /tmp && tar -cjf $tar_name $archive_root_dir && mv $tar_name $ROOT_PATH/tools`;


# Remove tmp directory
print "clean...\n";
`rm -r /tmp/$archive_root_dir`;

print "Component packaged!\n";
print "=> $tar_name\n";
