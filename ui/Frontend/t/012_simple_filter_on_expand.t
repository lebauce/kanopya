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

my $netconf_vms = dancer_response GET => '/api/netconfrole', { params => { netconf_role_name => 'vms' } };
is $netconf_vms->{status}, 200, "response from GET /api/netconfrole is 200";
my $role = Dancer::from_json($netconf_vms->{content});

my $netconfs = dancer_response GET => '/api/netconf',
               { params => {
                     expand            => 'netconf_role',
                     netconf_role_name => "vms",
                 }
               };
my $netconfs_content = Dancer::from_json($netconfs->{content});

foreach my $netconf (@$netconfs_content) {
    is $netconf->{netconf_role}->{netconf_role_name},
       'vms',
       "netconf has good filtered netconf role vms";

    is $netconf->{netconf_role_id},
       $role->[0]->{netconf_role_id},
       "netconf filtered by role has good role id $role->[0]->{netconf_role_id}";
}
