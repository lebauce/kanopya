#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/component.t.log', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok ('Administrator');
use_ok ('Entity::Component');

eval {
    #BEGIN { $ENV{DBIC_TRACE} = 1 }
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};

    $db->txn_begin;

    my $comp_types_rs = $adm->{db}->resultset('ComponentType')->search();
    while ( my $comp_type = $comp_types_rs->next ) {
        my $comp_name = $comp_type->get_column('component_name');
        my $comp_version = $comp_type->get_column('component_version');

        my $comp_class= "Entity::Component::" . $comp_name . $comp_version;

        use_ok ($comp_class);

        $db->txn_begin;

        my $comp_instance;
        lives_ok {
            $comp_instance = $comp_class->new();
            $comp_instance->insertDefaultConfiguration();
        }   $comp_class . ' component instanciation and insert default conf';

        $db->txn_rollback;
    }
};
if($@) {
    my $error = $@;
    print Dumper $error;
};

