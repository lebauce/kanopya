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
	my $mb = $adm->getEntity( type => "Motherboard", id => $mb_id );
	$mb->delete();
}


######### Display all MB list ###################

my @allMb = $adm->getEntities( type => "Motherboard", hash => {} );

# build loop data for html template and build hash for better motherboard access ( with 'id' as key) 
my @loop_data = ();
my %MotherboardsById = ();
my $i = -1;

my $selected_mb_id = $cgi->param("select_id");
my $selected_mb;

foreach $mb ( @allMb )
{
	my $mb_id = $mb->getAttr( name => 'motherboard_id');
	push( @loop_data, { 'id' =>  $mb_id,
						'sn' =>  $mb->getAttr( name => 'motherboard_serial_number'),
						'is_active' =>  $mb->getAttr( name => 'active'),
						} );
	if ( $selected_mb_id && $selected_mb_id == $mb_id ) {
		$selected_mb = $mb;
	}
}
$template->param(MOTHERBOARDS => \@loop_data);


######### Display selected MB ###################

# if a motherboard is selected then we set info
if ( $selected_mb )
{
	my %mb_params = $selected_mb->getAttrs();
	$template->param(SELECTED_MB_ID => $mb_params{'motherboard_id'} );
	$template->param(SELECTED_MB_SN => $mb_params{'motherboard_serial_number'});
	$template->param(SELECTED_MB_MAC => $mb_params{'motherboard_mac_address'});
	$template->param(SELECTED_MB_DESC => $mb_params{'motherboard_desc'});
	$template->param(SELECTED_MB_ACTIVE => $mb_params{'active'});
	
}


################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;