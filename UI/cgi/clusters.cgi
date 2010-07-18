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

$template->param(MENU_CLUSTERS => 1);

# get url params (POST or GET)
my $cgi = new CGI;

################################################################



################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;