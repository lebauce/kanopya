#!/usr/bin/perl -w

use Log::Log4perl qw(:easy);

use lib "../../Administrator/Lib";
use Administrator;

use CGI;
use HTML::Template;
use Error qw(:try);


# get Administrator
my $adm = Administrator->new( login =>'thom', password => 'pass' );

# open html template
my $template = HTML::Template->new(filename => 'templates/motherboardForm.tmpl');

$template->param(MENU_MOTHERBOARDS => 1);

# get url params (POST or GET)
my $cgi = new CGI;

################################################################

# fill form choices (select)
my @template_ids = ( {id => '32'}, {id => '42'}, {id => '6666'} );
$template->param(TEMPLATES => \@template_ids);


# if this script is called when form is submitted (in opposition to just display form)
# then we treat the form (depending on mode Add or Modify)
if ( $cgi->param("submit_add") )
{
	#my $model = $cgi->param("model");

	my $new_mb;
	try {
		$new_mb = $adm->newObj( type => "Motherboard",
								params => { 
											"motherboard_sn" => $cgi->param("sn"),
											"motherboardtemplate_id" => $cgi->param("template_id"),
											"motherboard_desc" => $cgi->param("desc"),
											} );
		$new_mb->save();
	}
	catch Error with {
		my $ex = shift;
		$template->param(ERROR_OCCURS => 1);
		$template->param(ERROR_MESS => $ex);
	};
	
	if ( !undef $new_mb ) {
		$template->param(RESULT => "Add ok!");
	}
}
elsif ( $cgi->param("submit_modify") )
{
	$template->param(RESULT => "Not implemented non mais oh!");
}

################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;