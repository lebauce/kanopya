#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Dancer::Test;
use Frontend;
use REST::api;
use APITestLib;

use Data::Dumper;
$DB::deep = 500;

use Log::Log4perl;
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%F %L %p %m%n'});

# Firstly login to the api
APITestLib::login();

my $post = dancer_response POST => '/api/vlan', { params => { vlan_name => 'testvlan', vlan_number => '102' } };
is $post->{status}, "200", "response for POST /vlan is 200";
my $post_content = Dancer::from_json($post->{content});
my $post_id = $post_content->{vlan_id};

my $delete = dancer_response DELETE => '/api/vlan/' . $post_id;
is $delete->{status}, "200", "response for DELETE /vlan is 200";

my $test_delete = dancer_response GET => '/api/vlan/' . $post_id;
is $test_delete->{status}, "404", "response for GET /vlan is 404";
