#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'basedb_tojson.log',
    layout => '%F %L %p %m%n'
});

my $log = get_logger("");

my $testing = 1;

use Kanopya::Database;
use General;
use ClassType;
use Kanopya::Exceptions;
use BaseDB;

use TryCatch;
my $err;

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {
    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    # Get the JSON of all class types and ne instance of each if exists
    my @classes = ClassType->search();
    for my $class (map { $_->class_type } @classes) {
        try {
            General::requireClass($class);
        }
        catch (Kanopya::Exception::Internal::UnknownClass $err) {
            next;
        }
        catch ($err) {
            $err->rethrow();
        }

        my $attributes;
        lives_ok {
            $attributes = $class->toJSON();
            for my $key ('pk', 'attributes', 'relations', 'methods') {
                exists $attributes->{$key} or die "Malformed class JSON: key <$key> not found.";
            }
        } 'Get the class JSON (attributes definition) for ' . $class;

        my $instance;
        try {
            $instance = $class->find();
        }
        catch (Kanopya::Exception::Internal::NotFound $err) {
            next;
        }
        catch ($err) {
            next;
        }

        my $json;
        lives_ok {
            $json = $instance->toJSON();

            exists $json->{pk} or die "Malformed JSON: key <pk> not found.";
            (! exists $json->{attributes} && ! exists $json->{relations} && ! exists $json->{methods})
                or die "Malformed JSON: keys <attributes|relations|methods> should not exists.";

        } 'Get the JSON (attributes values) for instance ' . ref($instance);

        # Skip some class types
        # - Entity is not an instantiable class
        # - Policies have specific attribute management
        if ($class eq "Entity" || $instance->isa("Entity::Policy")) {
            next;
        }

        lives_ok {
            delete $json->{pk};
            my $processed = $instance->checkAttributes(attrs => $json);

            (my $hierarchy = $class) =~ s/^Entity:://g;

            for my $module (split('::', $hierarchy)) {
                try {
                    Kanopya::Database::schema->source($module);
                }
                catch {
                    # No table for module
                    next;
                }

                my $table = BaseDB->_tableName(classname => $module);
                if (! defined $processed->{$table}) {
                    die "Malformed processed attrs, unable to find relation <" . $table .  "> in the hierarchy: " . Dumper($processed);
                }
                $processed = $processed->{$table};
            }
        } 'Get the processed attributes splited as hierarchy ' . ref($instance);
    }

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
