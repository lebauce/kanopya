#!/usr/bin/perl

use lib "/workspace/mcs/Monitor/Lib";

use strict;
use warnings;
use Monitor::Retriever;
use HTML::Template;
use CGI;

# open html template
my $template = HTML::Template->new(filename => 'templates/monitoring.tmpl');

# get url params (POST or GET)
my $cgi = new CGI;

# instanciate Monitor
my $monitor = Monitor::Retriever->new();

#$template->param(AUTO_REFRESH => 1);


my $set_def = $monitor->getIndicators();

# Retrieve required set and indicators (form data selected by user)
my $selected_set;
my @required_indicators;
if ( $cgi->param("submit_show") )
{
	$selected_set = $cgi->param("indicator_set");
	@required_indicators = $cgi->param("indicator[]");
}
else {
	$selected_set = "gen";
	@required_indicators = @{ $set_def->{ $selected_set } };
}

my $graph_type = $cgi->param("graph_type") || "line";
$template->param(GRAPH_TYPE_STACK_SELECTION => $graph_type eq "stack" ? "checked" : "");
$template->param(GRAPH_TYPE_LINE_SELECTION => $graph_type eq "line" ? "checked" : "");

my $time_laps = $cgi->param("time_laps") || "86400";
$template->param(GRAPH_TIME_LAPS => $time_laps);

# BUild indicators set loop data	
my @set_loop_data = ();			
while ( my ($set_name, $indicators) = each %$set_def )
{
	my @indicators_loop_data = ();
	for my $indicator (@$indicators) {
		my $checked = grep { $_ eq $indicator } @required_indicators;
		push ( @indicators_loop_data, { indicator_name => $indicator,
										checked =>  $checked > 0 ? "checked" : ""}
			
			
			);
	}
	push ( @set_loop_data, { 	set_name => $set_name,
								selected => $selected_set eq $set_name ? "checked" : "",
								indicators => \@indicators_loop_data });
}

$template->param(INDICATORS_SET => \@set_loop_data);


my $graph_infos = $monitor->graphNodes( time_laps => $time_laps,
										graph_type => $graph_type,
										required_set => $selected_set,
										required_indicators => \@required_indicators);

my @loop_data = ();

my $graph_dir_alias = "/graph";

while ( my ($host, $graph_info) = each %$graph_infos )
{
	push( @loop_data, { 'host_name' =>  $host,
						'graph_file' =>  $graph_dir_alias."/".$graph_info->{ $selected_set },
						} );
}
$template->param(HOSTS_INFO => \@loop_data);

$template->param(SELECTED_SET_NAME => $selected_set);

################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;