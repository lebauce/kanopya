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
    my $resp = dancer_response GET => '/api/physicalhoster0';
    my $phs  = Dancer::from_json($resp->{content});

    my $delete = dancer_response DELETE => '/api/entity/'.$phs->[0]->{pk};

    if ($delete->{status} ne '409') {
        die 'Wrong status got <' . $delete->{status} . '> expected <409>';
    }
} 'Delete contraint cascade <409>';


lives_ok {
    my $resp = dancer_response GET => '/api/physicalhoster0';
    my $phs  = Dancer::from_json($resp->{content});

    my $delete = dancer_response DELETE => '/api/physicalhoster0/0';

    if ($delete->{status} ne '404') {
        die 'Wrong status got <' . $delete->{status} . '> expected <404>';
    }
} 'Delete file not found <404>';


lives_ok {
    my $resp = dancer_response GET => '/api/user', { params => { user_login => 'admin' } };
    my $user = Dancer::from_json($resp->{content})->[0];
    my $delete = dancer_response DELETE => '/api/user/' . $user->{pk};
    if ($delete->{status} ne '409') {
        die 'Wrong status got <' . $delete->{status} . '> expected <409>';
    }

    my $user_params = {
        user_password  => 'test',
        user_login     => 'test',
        user_email     => 'test@test.test',
        user_firstname => 'test',
        user_lastname  => 'test'
    };

    $resp = dancer_response POST => '/api/user', { params => $user_params};
    if ($resp->{status} ne '200') {
        die 'POST wrong status got <' . $resp->{status} . '> expected <200>';
    }

    $user = Dancer::from_json($resp->{content});

    $resp = dancer_response POST => '/api/user', { params => $user_params};
    if ($resp->{status} ne '409') {
        die 'POST wrong status got <' . $resp->{status} . '> expected <409>';
    }

    $delete = dancer_response DELETE => '/api/user/' . $user->{pk};
    if ($delete->{status} ne '200') {
        die 'DELETE wrong status got <' . $delete->{status} . '> expected <200>';
    }

} 'Delete and Duplicate Entry';
