#!/usr/bin/perl -w
use CGI;
use strict;
use warnings;
use Data::Dumper;
use lib ".";
use Launcher;
my $html= new CGI;

print $html->header,$html->start_html(-title=>'declenchez des tests de charge');
print $html->p('Veuillez entrer des parametres pour votre test de charge: ');
print $html->start_form(-method=>'POST', -action=>'http://localhost/cgi-bin/web_http.cgi'),
	$html->p('veuillez indiquer des parametres pour le bench: '),
	$html->label('nombre maximum de clients simules: '),$html->textfield(-name=>'client_num_max'),$html->br,
	$html->label('nombre de clients simules lors du premier cycle: '),$html->textfield(-name=>'client_num_start'),$html->br,
	$html->label('nombre de clients simules a chaque nouveau cycle: '),$html->textfield(-name=>'client_ramup_inc'),$html->br,
	$html->label('nombre de cycles: '),$html->textfield(-name=>'cycles_num'),$html->br,
	$html->label('url du serveur web a benchmarquer: '),$html->textfield(-name=>'url'),$html->br,
	$html->p('veuillez selectionner les nodes clients utilises dans le cadre du bench'),$html->checkbox_group(-name=>'nodes', -values=>['node1','node2','node3...']),$html->br,$html->br,$html->submit(-value=>'Lancer curl-loader'), $html->end_form();

my %params=$html->Vars;
my $nodes=$html->param_fetch('nodes');
$params{nodes}=$nodes;

if (scalar (keys %params)){
	#print "contenu des parametres: ", Dumper(%params)." <br/>";
	my $generate = Launcher->generate(%params);
}else{
	print "veuillez renseigner des parametres pour le bench"
}
print $html->$html->end_html;
