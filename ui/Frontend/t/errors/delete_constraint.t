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

# GET the user ID 
my $get = dancer_response GET => '/api/user', { params => { user_login => 'admin' } };
is $get->{status}, '200', 'response for GET /user is 200';
my $users = Dancer::from_json($get->{content});
# my $get_id = $get_content->{user_id};

foreach my $user (@$users) {
    my $id = $user->{user_id};

    my $delete = dancer_response DELETE => '/api/user/' . $id, { headers => ['Accept: application/json', 'Accept-type: application/json'] };
    is $delete->{status}, '409', 'error message for deleting /user/' . $id  . ' is 409 (conflict) for cascade deleting not supported' ;
    
    # Not working : dancer::test update required for headers. See : https://github.com/PerlDancer/Dancer/pull/819
    # (bug confirmed by "Use of uninitialized value in pattern match (m//) at /opt/kanopya/ui/Frontend/lib/Frontend.pm line 110." message)
    # my $error =  Dancer::from_json($delete->{content});
    # like $error->

}
