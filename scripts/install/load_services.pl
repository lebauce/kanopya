#!/usr/bin/perl -w
use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Kanopya::Database;
use Entity::ServiceTemplate;

use JSON;
use Getopt::Std;
use XML::Simple;
use TryCatch;
use Data::Dumper;
use File::Basename;


sub print_usage {
    print "Usage: load_services.pl services_file.json\n";
    print "       load_services.pl -f services_file.json\n";
    print "Load services and policies initial environment.\n";
    exit(1);
}

my %opts = ();
getopts("f", \%opts) or print_usage;

my $main_file = $ARGV[0];
if (not defined $main_file) {
    print_usage;
    exit 1;
}
elsif (! -e $main_file) {
    print "File $main_file not found\n";
    exit 2;
}

# Authenticate to Kanopya
my $conf = XMLin("/opt/kanopya/conf/executor.conf");
General::checkParams(args => $conf->{user}, required => [ "name","password" ]);


Kanopya::Database::authenticate(login    => $conf->{user}->{name},
                                password => $conf->{user}->{password});


sub findReferencedObject {
    my $pattern = shift;

   General::checkParams(args => $pattern, required => [ "class_type" ]);

    my $referenced_class = delete $pattern->{class_type};
    print " - Found search pattern as value for referenced id of type $referenced_class\n";

    General::requireClass($referenced_class);

    my $referenced;
    try {
        $referenced = $referenced_class->find(hash => $pattern)->id;
    }
    catch ($err) {
        throw Kanopya::Exception(
                  error => "Unable to find referenced object of type $referenced_class:\n$err"
              );
    }
    print " - Referenced object of type $referenced_class found as id: " . $referenced . "\n";

    return $referenced;
}


sub validateTemplate {
    my $node = shift;

    if (ref($node) eq 'HASH') {
        for my $key (keys $node) {
            if ($key =~ m/^.*_id$/) {
                if (ref($node->{$key}) eq "HASH") {
                    $node->{$key} = findReferencedObject($node->{$key});
                }
                else {
                    # TODO: validate the id
                }
            }
            # BEGIN EXCEPTIONS
            elsif ($key eq "netconfs") {
                # Specific job for netconfs, we can not handle
                # its as the key does not contain "_id", and it is an array...
                my @referenced;
                for my $netconf (@{ $node->{$key} }) {
                    push @referenced, defined ref($netconf)
                                          ? findReferencedObject($netconf)
                                          : $netconf;
                }
                $node->{$key} = \@referenced;
            }
            elsif ($key eq "component_type") {
                # Argg, why component_type key has not initially be named component_type_id ?
                if (ref($node->{$key}) eq "HASH") {
                    $node->{$key} = findReferencedObject($node->{$key});
                }
                else {
                    # TODO: validate the id
                }
            }
            # END EXCEPTIONS
            elsif (ref($node->{$key})) {
                validateTemplate($node->{$key});
            }
        }
    }
    elsif (ref($node) eq 'ARRAY') {
        for my $item (@{ $node }) {
            validateTemplate($item);
        }
    }
}


Kanopya::Database::beginTransaction;

my $dir = dirname($main_file);
my @files = (basename($main_file));

my $templates = {};
while (scalar(@files)) {
    # Handle the first file of the list
    my $json_file = $dir . '/' . $files[0];

    print "Load service file '$json_file'...\n\n";

    if (! defined $templates->{$json_file}) {
        # Open and parse services definition json file.
        my $json = do {
            open(my $json_fh, "<:encoding(UTF-8)", $json_file)
                or die("Can't open $json_file: $!\n");
            local $/;
            <$json_fh>
        };

        try {
            $templates->{$json_file} = JSON->new->decode($json);
        }
        catch ($err) {
            throw Kanopya::Exception::IO(
                      error => "Malformed json file:\n$err"
                  );
        }
    }

    if (defined $templates->{$json_file}->{require}) {
        if (ref($templates->{$json_file}->{require}) ne 'ARRAY') {
            throw Kanopya::Exception(
                      error => "Malformed json file: 'required' key must have an array as value"
                  );
        }
        for my $required (@{ $templates->{$json_file}->{require} }) {
            print " - Found required json service file '$required.json'\n";
            unshift @files, $required . ".json";
        }
        delete $templates->{$json_file}->{require};
        next;
    }

    try {
        # Firstly create policies
        if (defined $templates->{$json_file}->{policies}) {
            print "Create policies...\n\n";
            for my $policy (values $templates->{$json_file}->{policies}) {
                General::checkParams(args => $policy, required => [ "policy_name", "policy_type" ]);

                print "Policy: $policy->{policy_name}...\n";

                # Build the type
                my $policy_type = "Entity::Policy::" . ucfirst($policy->{policy_type}) . "Policy";
                General::requireClass($policy_type);

                # Validate the policy template
                validateTemplate($policy);

                # Create
                my $instance = $policy_type->findOrCreate(%$policy);

                print " - ok, policy created with id " . $instance->id . "\n";
            }
        }

        # Then create services
        if (defined $templates->{$json_file}->{services}) {
            print "\nCreate services...\n\n";
            for my $service (values $templates->{$json_file}->{services}) {
                General::checkParams(args => $service, required => [ "service_name" ]);

                print "Service: $service->{service_name}...\n";

                # Validate the service template
                validateTemplate($service);

                # Create
                my $instance = Entity::ServiceTemplate->findOrCreate(%$service);

                print " - ok, service created with id " . $instance->id . "\n";
            }
        }
    }
    catch ($err) {
        print "\n";
        Kanopya::Database::rollbackTransaction;

        throw Kanopya::Exception(
                  error => "Load services from $json_file failed:\n$err"
              );
    }

    # remove the handled file from the file list
    shift @files;
}

Kanopya::Database::commitTransaction;


