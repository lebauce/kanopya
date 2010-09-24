#!/usr/bin/perl

use lib "/workspace/mcs/Monitor/Lib";

use strict;
use warnings;
use HTML::Template;
use CGI;

# open html template
my $template = HTML::Template->new(filename => 'templates/graph.tmpl');

# get url params (POST or GET)
my $cgi = new CGI;


$template->param(AUTO_REFRESH => 1);

my $dir = "/tmp";
my $dir_alias = "/graph/";

my @graphs = ();
for my $subdir ( ("monitor/graph", "orchestrator/graph") ) {
	my $graph_dir = "$dir/$subdir";

	opendir DIR, $graph_dir or die "$graph_dir doesn't exist !";
	my @files = readdir DIR;
	for my $file (@files) {
		if ( $file =~ "^graph_" ) {
			push @graphs, { dir_alias => $dir_alias, file => "$subdir/$file"};
		}
	}
}

#my @graphs = ( 	{ file => '/graph/graph_cluster_1_nodecount.png'},
#				{ file => '/graph/graph_localhost_gen.png'});
$template->param(GRAPHS => \@graphs);



################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;