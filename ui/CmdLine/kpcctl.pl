#!/usr/bin/perl

use strict;
use warnings;

use Administrator;
use General;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});


sub handle_new {
    my ($class) = @_;
    print "NEW $class\n";
    
    my $loc = General::getLocFromClass(entityclass=>$class);
    require $loc;
    my $obj = $class->new();
    #my $id = $obj->getAttr(name => 'entity_id');
    my $id = $obj->{_dbix}->id;
    print "New $class object inserted with id $id\n";
}

sub authenticate {
    
    while (1) {
        print "User: ";
        my $user = <STDIN>;
        chomp $user;
        print "Password: ";
        my $pwd = <STDIN>;
        chomp $pwd;
         
        eval {
            #Administrator::authenticate( login => $user, password => $pwd );
            Administrator::authenticate( login => 'admin', password => 'K4n0pY4' );
        };
        if ($@) {
            print $@, "\n";
        } else {
            last;
        }
    }
}

# Prompt user for command (<action> <params>)) and forward to the specific action handler
sub prompt {
    print "## Welcome ##\n";
    while (1) {
        print "> ";
        my $entry = <STDIN>;
        chomp $entry;
        my @entries = split ' ', $entry;
        my $action = shift @entries;
        next if not defined $action;
        my $params = join ',', map { "'$_'" } @entries;
        eval("handle_$action($params)");
        if ($@) {
            my $error = $@;
            if ($error =~ 'Undefined subroutine') {
                print "Action not implemented: '$action'\n";
            } else {
                print "$@\n";
            }
        }
    }
}

authenticate();
prompt();