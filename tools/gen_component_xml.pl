#!/usr/bin/perl -W
#
# Script to generate default component package description xml file
# You can edit generate file to add/remove files
# After you can call package_component.pl with the generate file as parameter
#
use XML::Simple;

my $VERSION=0.1;

my $ROOT_PATH = "/opt/kanopya/";

# get user input
my %comp_info = getComponentInfo();
my ($comp_name, $comp_version, $comp_cat) = ($comp_info{name},$comp_info{version},$comp_info{category});

my $comp_fullname = $comp_name . $comp_version;
my $comp_name_lc = lc $comp_fullname;

my $xml_filename = "component_" . $comp_cat . "_" . $comp_fullname . ".xml";


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


# Generate component package info xml file
print "Generate package info...\n";
XMLout( \%info, RootName => 'info', OutputFile => "/tmp/$xml_filename" );

print "=> /tmp/$xml_filename\n";

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
