#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

# the order is important
use Dancer::Test;
use Frontend;
use REST::api;
use APITestLib;
use Test::Exception;

use Data::Dumper;
$DB::deep = 500;

use Log::Log4perl;
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%F %L %p %m%n'});

# Firstly login to the api
APITestLib::login();

lives_ok {

    my $get_hosts = dancer_response GET => '/api/host';

    if ($get_hosts->{status} ne 200) {
        die 'Wrong status GET /api/response got <' . $get_hosts->{status} . '> expected <200>';
    }

    my $hosts_content = Dancer::from_json($get_hosts->{content});
    my $host = $hosts_content->[0];

    my $expand = dancer_response GET => '/api/host/' . $host->{host_id},
                 { params => { expand => 'host_manager,node' } };

    if ($expand->{status} ne 200) {
        die 'response for GET: got <' . $expand->{status} . '>, expected <200>';
    }

    my $content = Dancer::from_json($expand->{content});

    if ($content->{node}->{host_id} ne $host->{host_id}) {
        die 'Wrong node: got <' . $content->{node}->{host_id}
            . '> expected <' . $host->{host_id} . '>';
    }

    if ($content->{host_manager}->{component_id} ne $host->{host_manager_id}) {
        die 'Wrong host_manager: got <' . $content->{host_manager}->{component_id}
            . '> expected <' . $host->{host_manager_id} . '>';
    }

} "Two simple expands on 1-1 relationships";


lives_ok {
    my $get_hosts = dancer_response GET => '/api/host';

    if ($get_hosts->{status} ne 200) {
        die 'Wrong status GET /api/response got <' . $get_hosts->{status} . '> expected <200>';
    }

    my $hosts_content = Dancer::from_json($get_hosts->{content});
    my $host = $hosts_content->[0];

    my $expand = dancer_response GET => '/api/host/' . $host->{host_id},
                 { params => { expand => 'host_manager.component_type,node' } };

    if ($expand->{status} ne 200) {
        die 'response for GET: got <' . $expand->{status} . '>, expected <200>';
    }

    my $content = Dancer::from_json($expand->{content});

    if ($content->{node}->{host_id} ne $host->{host_id}) {
        die 'Wrong node: got <' . $content->{node}->{host_id}
            . '> expected <' . $host->{host_id} . '>';
    }

    if ($content->{host_manager}->{component_id} ne $host->{host_manager_id}) {
        die 'Wrong host_manager: got <' . $content->{host_manager}->{component_id}
            . '> expected <' . $host->{host_manager_id} . '>';
    }

    my $component = dancer_response GET => '/api/component/' . $host->{host_manager_id};

    if ($component->{status} ne 200) {
        die 'Wrong status GET /api/component/' . $host->{host_manager_id}
            . ' got <' . $get_hosts->{status} . '> expected <200>';
    }

    my $component_content = Dancer::from_json($component->{content});

    if ($content->{host_manager}->{component_type}->{component_type_id}
        ne $component_content->{component_type_id}) {

        die 'Wrong component type (id): got <'
            . $content->{host_manager}->{component_type}->{component_type_id}
            . '> expected <' . $component_content->{component_type_id} . '>';
    }
} "Two deep expands on 1-1 relationships";

