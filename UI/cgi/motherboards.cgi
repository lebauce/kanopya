#!/usr/bin/perl -w

use Log::Log4perl qw(:easy);

use lib "../../Administrator/Lib";
use Administrator;

use CGI;
use HTML::Template;

# get Administrator
my $adm = Administrator->new( login =>'thom', password => 'pass' );

# open html template
my $template = HTML::Template->new(filename => 'templates/motherboards.tmpl');

$template->param(MENU_MOTHERBOARDS => 1);

# get url params (POST or GET)
my $cgi = new CGI;

################################################################


######### manage selected MB ###################

# if user submit delete selected motherboard
if ( $cgi->param("submit_delete") )
{
	my $mb_id = $cgi->param("mb_id");
	my $mb = $adm->getObj( type => "Motherboard", id => $mb_id );
	$mb->delete();
}


######### Display all MB list ###################

my @allMb = $adm->getAllObjs( type => "Motherboard" );

# build loop data for html template and build hash for better motherboard access ( with 'id' as key) 
my @loop_data = ();
my %MotherboardsById = ();
my $i = -1;

my $selected_mb_id = $cgi->param("select_id");
my $selected_mb;

foreach $mb ( @allMb )
{
	my $mb_id = $mb->getValue( name => 'motherboard_id');
	push( @loop_data, { 'id' =>  $mb_id,
						'sn' =>  $mb->getValue( name => 'motherboard_sn'),
						'is_active' =>  $mb->getValue( name => 'motherboard_active'),
						} );
	if ( $selected_mb_id == $mb_id ) {
		$selected_mb = $mb;
	}
}
$template->param(MOTHERBOARDS => \@loop_data);


######### Display selected MB ###################

# if a motherboard is selected then we set info
if ( $selected_mb )
{
	my %mb_params = $selected_mb->getAllParams();
	$template->param(SELECTED_MB_ID => $mb_params{'motherboard_id'} );
	$template->param(SELECTED_MB_SN => $mb_params{'motherboard_sn'});
	$template->param(SELECTED_MB_DESC => $mb_params{'motherboard_dec'});
	$template->param(SELECTED_MB_ACTIVE => $mb_params{'motherboard_active'});
	
		#my $i = -1;
		#while ( ref $result->[++$i] )
		#{
		#	if ( $mb_id == $result->[$i]{'id'} )
		#	{
		#		# we found the selected mb
		#		$template->param(SELECTED_MB_ID => $result->[$i]{'id'});
		#		$template->param(SELECTED_MB_MODEL => $result->[$i]{'model'});
		#	}
		#}


	}


################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;