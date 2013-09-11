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
    file   => 'tojson.log',
    layout => '%F %L %p %m%n'
});

my $log = get_logger("");

my $testing = 1;

use BaseDB;
use General;
use ClassType;
use Kanopya::Exceptions;

use TryCatch;
my $err;

BaseDB->authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {
    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    # Get the JSON of all class types and ne instance of each if exists
    my @classes = ClassType->search();
    for my $class (map { $_->class_type } @classes) {
        try {
            BaseDB::requireClass($class);
        }
        catch (Kanopya::Exception::Internal::UnknownClass $err) {
            next;
        }

        lives_ok {
            my $attributes = $class->toJSON();

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

        lives_ok {
            my $json = $instance->toJSON();

            exists $json->{pk} or die "Malformed JSON: key <pk> not found.";
            (! exists $json->{attributes} && ! exists $json->{relations} && ! exists $json->{methods})
                or die "Malformed JSON: keys <attributes|relations|methods> should not exists.";

        } 'Get the JSON (attributes values) for instance ' . ref($instance);
    }

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}
