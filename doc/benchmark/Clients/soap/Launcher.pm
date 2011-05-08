#!/usr/bin/perl
package Launcher;

use strict;
use Template;
use Data::Dumper;
sub generate {
    my $self = shift;
    my %args = @_;
     #print "donnees passees a generate: ", Dumper (\%args)."<br/>";    

    my $data = {};
    $data->{client_num_start} = $args{client_num_start};
    $data->{url} = $args{url};
    $data->{cycles_num} = $args{cycles_num};
    $data->{client_num_max} = $args{client_num_max};
    $data->{client_ramup_inc} = $args{client_ramup_inc};
    
    print "donnees passees a la fonction process(): ", Dumper ($data), "<br/>";
    my $config = {
    INCLUDE_PATH => '/var/www/soap/',
    EVAL_PERL => 1,
    RELATIVE => 1,
    POST_CHOMP => 0,
    INTERPOLATE => 1,
    };
    my $confFile = "/var/www/soap/curl-loader.conf";
    my $template = Template->new($config) || die $Template::ERROR, "\n";
    my $input = "curl-loader.conf.tt";
    my $nodes = $args{nodes};

    foreach my $n (@$nodes){
        print Dumper ($n), "<br/>";
        if ($template->process($input, $data, $confFile)){
            system ("scp /var/www/soap/curl-loader.conf localhost:/tmp/curl-loader.conf");
            if ( $? == -1 ){
                print "command failed to execute: $!\n";
            }else{
                print "code de retour de la commande precedente (scp du coup..): ", Dumper ($?);
                system ("ssh localhost sudo curl-loader -f '/tmp/curl-loader.conf' &");
            }
        }        
    }
}
1;
