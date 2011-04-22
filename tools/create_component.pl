#!/usr/bin/perl -W

# This script generate some skeleton files needed to develop a new component
# User must edit generated files to implement specific component behaviour 

use Template;

my $ROOT_PATH = "/opt/kanopya/";
my %PATHS = (
	component 	=> "lib/administrator/Entity/Component/",
	ecomponent 	=> "lib/executor/EEntity/EComponent/",
	table 		=> "scripts/database/mysql/schemas/components/",
	form 		=> "ui/web/KanopyaUI/templates/Components/",
);

createComp();

sub createComp {
	my %comp_info = getComponentInfo();
	checkValidCategory( category => $comp_info{category} );
	genFiles( name => $comp_info{name}, category => $comp_info{category}, version => $comp_info{version} );
	#showTodo();
}

sub getComponentInfo {
	my %comp_info = ();
	for my $info ('name', 'category', 'version') {
		print "Component $info: ";
		$comp_info{$info} = ucfirst <STDIN>;
		chomp $comp_info{$info};
	}
	return %comp_info;
}

sub checkValidCategory {
	my %args = @_;
	
	for my $dir ( 	$ROOT_PATH . $PATHS{component} . $args{category}, 
					$ROOT_PATH . $PATHS{ecomponent} . 'E' . $args{category} ) {					
		if ( not -d $dir ) {
	    print "	This category doesn't exists. You have to manually create category directory and category module before launch this script ($dir)\n";
	    exit;
		}
	}
}

sub genFiles {
	my %args = @_;
	
	my ($comp_name, $comp_cat) = ($args{name} . $args{version}, $args{category} ); 
	my $comp_name_lc = lc $comp_name;
	
	my %data = (
	    component_name 		=> $comp_name,
	    component_category 	=> $comp_cat,
	    master_table_name 	=> $comp_name_lc,
	);
	
	my %files = (
	    "Component.pm.tt" 		 => $ROOT_PATH . $PATHS{component} 	. "$comp_cat/$comp_name.pm",
	    "EComponent.pm.tt" 		 => $ROOT_PATH . $PATHS{ecomponent} . "E$comp_cat/E$comp_name.pm",
	    "ComponentTable.sql.tt"  => $ROOT_PATH . $PATHS{table} 		. "$comp_name_lc.sql",
	    "form_component.tmpl.tt" => $ROOT_PATH . $PATHS{form} 		. "form_$comp_name_lc.tmpl",
	);
	
	my $config = {
	    INCLUDE_PATH => '/opt/kanopya/tools/componentModel/',
	    POST_CHOMP   => 1,
	};
	my $template = Template->new($config);
	
	while ( my ($input, $output) = each %files ) { 
	    print "Generate $output...\n";
	    $template->process($input, \%data, $output) || do {
			print "error while generating file '$output' from '$input' : $!\n";
	    };
	}
}

sub showTodo {
	print "####################################\n";
	print "1. Edit generated files\n";
	print "2. Install comp in db and make schema\n";
	print "3. Install component on a system image\n";
}
