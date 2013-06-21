#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Dancer::Test;
use Frontend;
use REST::api;
use Data::Dumper;
$DB::deep = 500;

use Log::Log4perl;
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%F %L %p %m%n'});

my $login = dancer_response(POST => '/login', { params => {login => 'admin', password => 'K4n0pY4'}});

# POST ON A SIMPLE RESOURCE
my $post = dancer_response POST => '/api/vlan', { params => { vlan_name => 'testvlan', vlan_number => '102' } };
is $post->{status}, "200", "response for POST /vlan is 200";
my $post_content = Dancer::from_json($post->{content});
my $post_id = $post_content->{vlan_id};

my $created_post = dancer_response GET => '/api/vlan/' . $post_id;
is $created_post->{status}, "200", "response for GET /vlan/$post_id is 200";
my $created_post_content = Dancer::from_json($created_post->{content});
is $created_post_content->{vlan_name}, 'testvlan', "created vlan $post_id has correct value for param vlan_name";
is $created_post_content->{vlan_number}, '102', "created vlan $post_id has correct value for param vlan_number";

# POST ON A RESOURCE WITH RELATION
my $operation_creation = dancer_response POST => '/api/operation', { params => { type => 'AddNode', priority => 200 } };
is $operation_creation->{status}, '200', 'reponse for POST /api/operation is 200';

my $operation_content = Dancer::from_json($operation_creation->{content});
my $operation_id = $operation_content->{operation_id};
my $workflow_id = $operation_content->{workflow_id};

my $created_operation = dancer_response GET => '/api/operation/' . $operation_id;
is $created_operation->{status}, '200', "response for GET /api/operation/$operation_id is 200";

my $created_workflow_operation = dancer_response GET => '/api/operation/' . $operation_id . '/workflow';
is $created_workflow_operation->{status}, '200', "response for GET /api/operation/$operation_id/workflow is 200";

my $c_w_o_content = Dancer::from_json($created_workflow_operation->{content});
is $c_w_o_content->{workflow_id}, $workflow_id, "workflow found in GET /api/operation/$operation_id/workflow has good id $workflow_id";             

my $created_workflow = dancer_response GET => '/api/workflow/' . $workflow_id;
is $created_workflow->{status}, '200', "response for GET /api/workflow/$workflow_id is 200";
