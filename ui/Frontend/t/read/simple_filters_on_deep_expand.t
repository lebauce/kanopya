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
use Kanopya::Test::TestUtils 'expectedException';

use Data::Dumper;
$DB::deep = 500;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%d [ %H - %P ] %p -> %M - %m%n'});
my $log = get_logger("");

# Firstly login to the api
APITestLib::login();

my $hosts = dancer_response GET => '/api/host';
is $hosts->{status}, 200, 'response from GET on /api/host is 200';
my $hosts_content = Dancer::from_json($hosts->{content});
my $host = $hosts_content->[0];

my @expanded_hosts = ();

push @expanded_hosts, dancer_response GET => '/api/host', { params => {
                      expand => 'host_manager.component_type',
                          'host_manager.component_type.component_name' => 'Physicalhoster',
                      } };

push @expanded_hosts, dancer_response GET => '/api/host', { params => {
                          expand => 'host_manager.component_type',
                          'component_name' => 'Physicalhoster',
                      } };

push @expanded_hosts, dancer_response GET => '/api/host', { params => {
                          'host_manager.component_type.component_name' => 'Physicalhoster',
                      } };

push @expanded_hosts, dancer_response GET => '/api/host', { params => {
                          'component_name' => 'Physicalhoster',
                      } };

lives_ok {
    my $expanded_hosts_content = Dancer::from_json($expanded_hosts[0]->{content});

    if (ref($expanded_hosts_content) ne 'ARRAY') {
        die 'return ARRAY expected'
    }

    my $expand = $expanded_hosts_content->[0];

    if ($expanded_hosts[0]->{status} != 200) {
        die 'Status received <'
        .$expanded_hosts[0]->{status}
        .'> expected <200>';
    }

    if ($expand->{host_manager}->{component_type}->{component_name} ne 'Physicalhoster') {
        die "Wrong component name got <"
            . $expand->{host_manager}->{component_type}->{component_name}
            . "> expected <Physicalhoster>";
    }

} 'Deep expansion and whole name filter';

lives_ok {
    my $expanded_hosts_content = Dancer::from_json($expanded_hosts[1]->{content});

    if (ref($expanded_hosts_content) ne 'ARRAY') {
        die 'return ARRAY expected'
    }

    my $expand = $expanded_hosts_content->[0];

    if ($expanded_hosts[0]->{status} != 200) {
      die 'Status received <'
      .$expanded_hosts[0]->{status}
      .'> expected <200>';
    }

    if ($expand->{host_manager}->{component_type}->{component_name} ne 'Physicalhoster') {
        die "Wrong component name got <"
            . $expand->{host_manager}->{component_type}->{component_name}
            . "> expected <Physicalhoster>";
    }
} 'Deep expansion and short name filter';

lives_ok {
    my $expanded_hosts_content = Dancer::from_json($expanded_hosts[2]->{content});

    if (ref($expanded_hosts_content) ne 'ARRAY') {
        die 'return ARRAY expected'
    }

    my $expand = $expanded_hosts_content->[0];

    if ($expanded_hosts[0]->{status} != 200) {
      die 'Status received <'
      .$expanded_hosts[0]->{status}
      .'> expected <200>';
    }

    if ($expand->{host_id} ne $host->{host_id}) {
        print $expand->{host_id}.' vs '.$host->{host_id}."\n";
        die 'Filter has failed expect to have selected host <'.$host->{host_id}.'>';
    }

    if (defined $expand->{host_manager}) {
        die "Host manager expected not to be expanded";
    }

} 'No expansion and whole name filter';

lives_ok {
    my $expanded_hosts_content = Dancer::from_json($expanded_hosts[3]->{content});
    
    if (ref($expanded_hosts_content) eq 'ARRAY') {
        die 'Exception expected, HASH return expected'
    }

    if (! ( defined $expanded_hosts_content->{reason}
        && $expanded_hosts_content->{reason} =~ m/DBI Exception/ )) {
        die 'die <DBI::Exception> expected';
    }

} 'No expansion and short name filter';
