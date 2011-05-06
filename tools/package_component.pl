#!/usr/bin/perl -W
#
# Script to create component package which can be deployed on kanopya
# Very simple version
#
use XML::Simple;

my $VERSION=0.1;

my $ROOT_PATH = "/opt/kanopya/";

# get user input
my %comp_info = getComponentInfo();
my ($comp_name, $comp_version, $comp_cat) = ($comp_info{name},$comp_info{version},$comp_info{category});

my $comp_fullname = $comp_name . $comp_version;
my $comp_name_lc = lc $comp_fullname;

my $archive_root_dir = "component_" . $comp_cat . "_" . $comp_fullname ;

# Temporary dir to be archived
`mkdir -p /tmp/$archive_root_dir`;


#TODO get input (xml file) defining additional files to  archive

# build component package info
my %info = (
    meta => { packager_version => $VERSION },
    description => { name => $comp_name, category => $comp_cat, version => $comp_version },
    'nas' => [
	{ # Component module
	    src => "lib/administrator/Entity/Component/$comp_cat/$comp_fullname.pm",
	    dest => "lib/administrator/Entity/Component/$comp_cat/$comp_fullname.pm",
	},
	{ # DB schema
	    src => "lib/administrator/AdministratorDB/Schema/Result/$comp_fullname.pm",
	    dest => "lib/administrator/AdministratorDB/Schema/Result/$comp_fullname.pm",
	},
	{ # DB Tables 
	    src => "scripts/database/mysql/schemas/components/$comp_name_lc.sql",
	    dest => "scripts/database/mysql/schemas/components/$comp_name_lc.sql",
	},
	{ # Instance relationship
	    src => "lib/administrator/AdministratorDB/Component/$comp_fullname"."Instance.pm",
	    dest => "lib/administrator/AdministratorDB/Component/$comp_fullname"."Instance.pm",
	},
        { # Web ui configuration template
	    src => "ui/web/KanopyaUI/templates/Components/form_$comp_name_lc.tmpl",
            dest => "ui/web/KanopyaUI/templates/Components/form_$comp_name_lc.tmpl",
        },
    ],
    'executor' => [
	{ # EComponent module
	    src => "lib/executor/EEntity/EComponent/E$comp_cat/E$comp_fullname.pm",
	    dest => "lib/executor/EEntity/EComponent/E$comp_cat/E$comp_fullname.pm",
	},
    ],
    'tables_file' => "scripts/database/mysql/schemas/components/$comp_name_lc.sql",
    'templates_dir' => "templates/components/$comp_name_lc",
);


# Build file list
my @files = ();
for my $srv ('executor', 'nas') {
    if (defined $info{$srv}) {
	push @files, ( map { $_->{src} } @{ $info{$srv} }  );
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
if ( -e $info{templates_dir} ) {
    print "Copy template files...\n";
    my $tmp_dest = "/tmp/$archive_root_dir/$info{templates_dir}";
    `mkdir -p $tmp_dest`;
    `cd .. && cp $info{templates_dir}/* $tmp_dest`;
} else {
    print "No templates dir found ($info{templates_dir}) => skip templates\n";
    delete $info{templates_dir};
}


# Generate component package info xml file
print "Generate package info...\n";
XMLout( \%info, RootName => 'info', OutputFile => "/tmp/$archive_root_dir/info.xml" );


# Tar directory and move tarball in this script dir (tools)
print "Create archive...\n";
my $tar_name = $archive_root_dir . ".tar";
`cd /tmp && tar -cjf $tar_name $archive_root_dir && mv $tar_name $ROOT_PATH/tools`;


# Remove tmp directory
print "clean...\n";
`rm -r /tmp/$archive_root_dir`;

print "Component packaged!\n";
print "=> $tar_name\n";



sub getComponentInfo {
    my %comp_info = ();
    for my $info ('name', 'category', 'version') {
	print "Component $info: ";
	my $input = ucfirst <STDIN>;
	chomp($input);
	$input =~ s/[^\w\d]//g;
	$comp_info{$info} = $input;
    }
    return %comp_info;
}
