#!/usr/bin/perl

use lib "../../Monitor/Lib";

use strict;
use warnings;
use Monitor;
use HTML::Template;

my $monitor = Monitor->new();

#$monitor->graph( set_label => "cpu" );
#$monitor->graph( set_label => "mem" );
my $graph_infos = $monitor->makeGraph( time_laps => 300);

# open html template
my $template = HTML::Template->new(filename => 'templates/monitoring.tmpl');

my @loop_data = ();

my @hosts_info = ( 
					{ host_name => "localhost", graph_cpu => "/graph/graph_cpu_localhost.png", graph_mem => "/graph/graph_mem_localhost.png" },
					{ host_name => "127.0.0.1", graph_cpu => "/graph/graph_cpu_127.0.0.1.png", graph_mem => "/graph/graph_mem_127.0.0.1.png" },				
				 ); 

my $graph_dir_alias = "/graph";

while ( my ($host, $graph_info) = each %$graph_infos )
{
	push( @loop_data, { 'host_name' =>  $host,
						'graph_cpu' =>  $graph_dir_alias."/".$graph_info->{'cpu'},
						'graph_mem' =>  $graph_dir_alias."/".$graph_info->{'mem'},
						} );
}
$template->param(HOSTS_INFO => \@loop_data);
#$template->param(HOSTS_INFO => \@hosts_info);

################################################################

# print html page using template
print "Content-Type: text/html\n\n", $template->output;