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

# get url params (POST or GET)
my $cgi = new CGI;

################################################################

my @allMb = $adm->getAllObjs( type => "Motherboard" );

# build loop data for html template and build hash for better motherboard access ( with 'id' as key) 
my @loop_data = ();
my %MotherboardsById = ();
my $i = -1;

foreach $mb ( @allMb )
{
	push( @loop_data, { 'id' =>  $mb->getValue( name => 'motherboard_id'), 'model' =>  $mb->getValue( name => 'motherboard_sn') } );
	#$MotherboardsById{ $result->[$i]{'id'} } = $result->[$i];
}
$template->param(MOTHERBOARDS => \@loop_data);



################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;