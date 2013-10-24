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
    file   => 'basedb_getattr.log',
    layout => '%F %L %p %m%n'
});

my $log = get_logger("");

my $testing = 1;

use Kanopya::Database;
use BaseDB;
use General;
use ClassType;
use Kanopya::Exceptions;

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

        my @hierarchy = $instance->_classHierarchy;
        for my $classname (reverse @hierarchy) {
            my $dbix = $instance->_dbixParent(classname => $classname);

            ATTRIBUTE:
            for my $attrname ($dbix->columns) {
                my $dbixvalue   = $dbix->get_column($attrname);
                my $definition  = $instance->_attributesDefinition->{$attrname};

                my $basedbvalue = $instance->getAttr(name => $attrname);
                lives_ok {
                    # Check the raw value
                    if ("$dbixvalue" ne "$basedbvalue") {
                        die "Value from dbix <$dbixvalue> differs from basedb value <$basedbvalue>";
                    }
                    
                    # Skip the foreign key that belong to the parent Entity.
                    # Skip the tag_id foreign key on Entity::Tag cause there exists an attribute <tag>.
                    if ($definition->{is_primary}) {
                        next ATTRIBUTE;
                    }

                    # If the attribute is a relation
                    if ($attrname =~ m/_id$/ && $dbixvalue =~ m/^\d+$/) {
                        $attrname =~ s/_id$//g;

                        my $classname = BaseDB->_className(class => $dbix->relationship_info($attrname)->{class});
                        my $relclass;
                        try {
                            $relclass = BaseDB->_classType(class => $classname);
                        }
                        catch ($err) {
                            $relclass = $classname;
                        }

                        # Check the if of the returned object
                        my $relation_instance = $instance->getAttr(name => $attrname);
                        if ($relation_instance->id ne $dbixvalue) {
                            die "Value from dbix <$dbixvalue> differs from basedb value gotten from relation attr <$attrname>";
                        }

                        # Also check with an instance gotten from the id value and the relation class type
                        try {
                            General::requireClass($relclass);
                        }
                        catch (Kanopya::Exception::Internal::UnknownClass $err) {
                            next ATTRIBUTE;
                        }

                        # Check the if of the returned object
                        $relation_instance = $relclass->get(id => $dbixvalue);
                        if ($relation_instance->id ne $dbixvalue) {
                            die "Value from dbix <$dbixvalue> differs from basedb value gotten from id and class attr <$relclass->get(id => $dbixvalue)>";
                        }
                    }
                } "Check consistency of the value of attribute <$attrname> for instance $instance";
            }
        }
    }

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
