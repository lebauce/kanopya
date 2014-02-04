=head1 TEST SUITE

Post all resources

=head1 DESCRIPTION

For each available resources:
1. GET attributes of the resource
2. Generate value for each mandatory attribute:
    a. If attribute is a relationship then GET related resources and keep the first
        - if no resource available, POST one. These temp resources will be deleted at the end (7.)
    b. Else generate a valid value according to the pattern
3. POST the resource with only mandatory attributes
4. Test the response status of the POST request
5. DELETE the resource
6. Test the response status of the DELETE request
7. Delete the related resources possibly created (2.a)

If a test fail, see the log file for more details (failing request response)

You can run this test for a specific resource by giving the name of the resource (command line parameter)

=head1 REQUIREMENTS

Message queuing server must be running (since some POST lead to an operation enqueuing).

=head1 INFO

=head2 Expected status

Expected response status is 200 by default.
However, some POST requests status are 405 ("must implement _delegatee").
The hash %POST_expected_status lists resources with a post status different than 200.
POST test will pass if status correspond to defined status in this hash, otherwise test will fail.
So 405 is considered as correct response, since we don't know if it's a wanted behavior or not.

TODO Implement _delegatee for resources that need it, and remove them from %POST_expected_status.

=head2 Resource delete

Resource are deleted only if the POST request was ok and do not lead to an operation enqueueing. 

TODO Handle DELETE for resource created after operation execution

=head2 Skipped resources

Some resources are skipped in this tests suite.
Reasons are:
 - Nonsense to create through API (base class, kanopya internal resources)
 - Hard to generically automatize. TODO Specific tests suite
 - Produce strange error. TODO Study and fix

All skipped resources are in the array @skip_resources

=head2 Fixed value

Some attribute values can not be correctly generated from the pattern.
These values are fixed in %attribute_fixed_value

=cut

use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Frontend;
use Dancer::Test;
use REST::api;
use APITestLib;

use String::Random 'random_regex';
use Data::Dumper;

require 't/APITestLogger.pm';
use Log::Log4perl 'get_logger';
my $log = get_logger("");

# default : 200
# 405 :  Non entity class <xxx> must implement _delegatee method for permissions check.
my %POST_expected_status = (
    'netconfiface' => 405,
    'netconfpoolip'=> 405,
    'userprofile' => 405,
    'profile' => 405,
    'quota'   => 405,
    'datamodeltype' => 405,
    'entitytimeperiod' => 405,
    'message' => 405,
    'indicatorset' => 405,
    'entitycomment' => 405,
    'ip' => 405,
    'alert'=> 405,
    'netconfinterface' => 405,
    'iscsiportal' => 405,
    'lvm2vg' => 405,
    'apache2virtualhost' => 405,
    'entityright' => 405,
    'parampreset' => 405,
    'linuxmount' => 405,
    'keepalived1vrrpinstance' => 405,
    'haproxy1listen' => 405,
);

my @skip_resources = (

    # Nonsense to create through API
    'entity',
    'classtype',
    'datamodel',
    'component',
    'componenttype',
    'scope',
    'scopeparameter',
    'serviceprovidertype',
    'masterimage',
    'operation',
    'oldoperation',
    'operationtype',

    # Pb : valid formula generation (valid IDs)
    # Need specific tests suite for monitoring and rule
    'rule', #cant instanciate abstract class

    # Repository : foreign key 'virtualization_id' failed
    # Need specific tests suite
    'repository',
    'openstackrepository',
    'opennebula3repository',
    'vsphere5repository',

    # Container and container access (need to be linked to valid container and export manager)
    'container',
    'lvmcontainer', # ??
    'containeraccess',
    'nfscontaineraccess',
    'filecontaineraccess',
    'iscsicontaineraccess',
    'nfscontaineraccessclient',

    # Misc, to study
    'notificationsubscription', # Why 'entity_id' is mandatory ?
    'cinder', # ??
    'ucsmanager',
    'cluster', # owner_id mandatory set not mandatory
    'serviceprovidermanager', # hard to generate valid attributes value
    'netapplunmanager',
    'netappvolumemanager',
    'systemimage', # need to be linked to a valid 'container_access'
    'netconfrole', # Can not cascade delete
    'hpc7000',
);

# Some regexp can not be correctly parsed and bad value are generated, so we fix it
my %attribute_fixed_value = (
    'nodemetriccondition' => {
        'nodemetric_condition_comparator' => '>'
    },
    'aggregatecondition' => {
        'comparator' => '>='
    },
    'user' => {
        'user_email' => 'foo@bar.fr'
    },
    'customer' => {
        'user_email' => 'foo@bar.fr'
    },
    'poolip' => {
        'poolip_first_addr' => '10.0.0.1'
    },
    'mailnotifier0' => {
        'smtp_server' => '0.0.0.0'
    },
    'clustermetric' => {
        'clustermetric_statistics_function_name' => 'mean'
    },
);

sub fillMissingFixedAttr {
    # host_manager_ids
    my $resp = dancer_response(GET => "/api/physicalhoster0", {});
    my $json = Dancer::from_json($resp->{content});
    $attribute_fixed_value{host}{host_manager_id} = $json->[0]->{pk};
    $attribute_fixed_value{hypervisor}{host_manager_id} = $json->[0]->{pk};
    $attribute_fixed_value{virtualmachine}{host_manager_id} = $json->[0]->{pk};
    $attribute_fixed_value{opennebula3hypervisor}{host_manager_id} = $json->[0]->{pk};
    $attribute_fixed_value{openstackhypervisor}{host_manager_id} = $json->[0]->{pk};
    $attribute_fixed_value{openstackvm}{host_manager_id} = $json->[0]->{pk};
    $attribute_fixed_value{opennebula3vm}{host_manager_id} = $json->[0]->{pk};

    # formulas
    # nodemetricrule
    $resp = dancer_response(GET => "/api/nodemetriccondition", {});
    $json = Dancer::from_json($resp->{content});
    $attribute_fixed_value{rule}{formula} = 'id'.$json->[0]->{pk};
    $attribute_fixed_value{nodemetricrule}{formula} = 'id'.$json->[0]->{pk};

    # aggregaterule
    $resp = dancer_response(GET => "/api/aggregatecondition", {});
    $json = Dancer::from_json($resp->{content});
    $attribute_fixed_value{aggregaterule}{formula} = 'id'.$json->[0]->{pk};

    # aggregatecombination
    $resp = dancer_response(GET => "/api/clustermetric", {});
    $json = Dancer::from_json($resp->{content});
    $attribute_fixed_value{aggregatecombination}{aggregate_combination_formula} = 'id'.$json->[0]->{pk};

    #nodemetriccombination
    $resp = dancer_response(GET => "/api/collectorindicator", {});
    $json = Dancer::from_json($resp->{content});
    $attribute_fixed_value{nodemetriccombination}{nodemetric_combination_formula} = 'id'.$json->[0]->{pk};

    # cluster for node
    $resp = dancer_response(GET => "/api/cluster", {});
    $json = Dancer::from_json($resp->{content});
    $attribute_fixed_value{node}{service_provider_id} = $json->[0]->{pk};

}

sub run {
    my $resource = shift;

    # Firstly login to the api
    APITestLib::login();
    fillMissingFixedAttr();

    my %_skip_resources = map {$_ => 1} @skip_resources;
    my @api_resources = $resource ? ($resource) : keys %REST::api::resources;
    #@api_resources = @api_resources[0 .. 20];
    #@api_resources = ('operation', 'netapp');
    RESOURCE:
    for my $resource_name (@api_resources) {
        if (exists $_skip_resources{$resource_name}) {
            SKIP: {
                skip "POST '$resource_name' not managed in this test", 1;
                is 0, 0, '';
            }
            next RESOURCE;
        }
        post_resource($resource_name);
    }
}

# Generate values for (mandatory) attributes of a resource
sub _generate_values {
    my ($resource_name) = @_;

    my $resource_info_resp = dancer_response(GET => "/api/attributes/$resource_name", {});
    my $resource_info = Dancer::from_json($resource_info_resp->{content});

    my %params;
    while (my ($attr_name, $attr_def) = each %{$resource_info->{attributes}}) {
        if ($attr_def->{is_mandatory}) {
            my $value = '';
            if (exists $attribute_fixed_value{$resource_name}{$attr_name}) {
                # value can not be generated
                $value = $attribute_fixed_value{$resource_name}{$attr_name};
            }
            elsif ($attr_def->{'relation'} || $attr_name =~ /.*_id$/) {
                # Relation
                (my $relation = $attr_name) =~ s/_id$//;
                my $related_resource = $resource_info->{relations}{$relation}{resource};
                if (not defined $related_resource) {($related_resource = $relation) =~ s/_//g;}
                $value = get_resource($related_resource);
            }
            else {
                # Generate value using pattern
                my $pattern = $attr_def->{pattern} || '^.*$';

                my @pattern_split = split '', $attr_def->{pattern};
                $pattern_split[0]  = '' if $pattern_split[0] eq '^';
                $pattern_split[-1] = '' if $pattern_split[-1] eq '$';
                $pattern = join '', @pattern_split;

                if ($pattern =~ m/^\((\w+\|)+\w+\)$/) {
                    $pattern =~ s/^.//;
                    $pattern =~ s/.$//;
                    my @split = split '\|', $pattern;
                    $value = $split[0];
                }
                else {
                    eval {
                        $value = random_regex($pattern);
                    };
                    if ($@) {
                        $log->error("Can not generate a string for pattern '$pattern'");
                    }
                }
            }
            $params{$attr_name} = $value;
        }
    }
    return \%params;
}

my @temp_resources = ();

# POST a resource and test response status
# Attributes values are generated
sub post_resource {
    my ($resource_name, $persistent) = @_;

    $log->debug("POST $resource_name");

    my $params = _generate_values($resource_name);
    $log->debug("POST '$resource_name' with attributes : " . (Dumper $params));

    my $new_resp = dancer_response(POST => "/api/$resource_name", { params => $params});

    my $expect_status = $POST_expected_status{$resource_name} || 200;
    if (!$persistent) {
        is $new_resp->{status}, $expect_status,
           "response status is $expect_status for POST $resource_name with only mandatory attributes";
    }

    # If POST succeed
    if ($new_resp->{status} == 200) {
        my $new_resource = Dancer::from_json($new_resp->{content});
        if ($persistent) {
            push @temp_resources, $new_resource->{pk};
            return $new_resource->{pk};
        } else {
            # If resource created (i.e do not need operation execution) then we delete it
            if (!$new_resource->{operation_id}) {
                delete_resource($resource_name, $new_resource->{pk});
            }
            # Delete related resources created before (persistent)
            foreach (@temp_resources) {delete_resource('entity', $_, 1)};
            @temp_resources = ();
        }
    } else {
       $log->error(Dumper $new_resp) if ($new_resp->{status} != $expect_status);
    }
}

sub delete_resource {
    my ($resource_name, $resource_id, $notest) = @_;

    $log->debug("DELETE $resource_name/$resource_id");
    my $delete_resp = dancer_response(DELETE => "/api/$resource_name/$resource_id", {});

    if (!$notest) {
        is $delete_resp->{status}, 200, "response status is 200 for DELETE $resource_name";
    }
    $log->error(Dumper $delete_resp) if ($delete_resp->{status} != 200);
}

# Get or create if empty
sub get_resource {
    my $resource_name = shift;

    $log->debug("GET $resource_name");
    my $resource_resp = dancer_response(GET => "/api/$resource_name", {});

    $log->error(Dumper $resource_resp) if ($resource_resp->{status} != 200);

    my $resource;
    eval {
        $resource = Dancer::from_json($resource_resp->{content});
    };
    if ($@) {
        my $error = $@;
        if ($error =~ 'malformed') {
            $log->error(
                "Can not parse response for GET '$resource_name' due to special characters in some attributes value."
                . " Considered as empty."
            );
        } else {
            $log->error($error);
        }
    }

    if ((ref $resource) eq 'ARRAY' && $resource->[0]) {
        return $resource->[0]{pk};
    } else {
        $log->info("No resource of type '$resource_name', we will create it");
        return post_resource($resource_name, 1);
    }
}

run($ARGV[0]);
