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

my $matrix = { eq => {
                   operator => '=',
                   filter   => 'disabled',
                   param    => 'monitoring_state',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; is $got, 'disabled', $msg; },
               },
               ne => {
                   operator => '<>',
                   filter   => 'enabled',
                   param    => 'monitoring_state',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; is $got, 'disabled', $msg; },
               },
               le => {
                   operator => '<=',
                   filter   => 1,
                   param    => 'node_id',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; cmp_ok $got, $operator, $filter, $msg; },
               },
               lt => {
                   operator => '<',
                   filter   => 2,
                   param    => 'node_id',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; cmp_ok $got, $operator, $filter, $msg; },
               },
               ge => {
                   operator => '>=',
                   filter   => 2,
                   param    => 'node_id',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; cmp_ok $got, $operator, $filter, $msg; },
               },
               gt => {
                   operator => '>',
                   filter   => 1,
                   param    => 'node_id',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; cmp_ok $got, $operator, $filter, $msg; },
               },
               bw => {
                   operator => 'LIKE',
                   filter   => 'in%',
                   param    => 'node_state',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; like $got, '/in:.*/', $msg; },
               },
               bn => {
                   operator => 'NOT LIKE',
                   filter   => 'in%',
                   param    => 'node_state',
                   function => sub { my ($got, $operator, $filter, $msg) = @_; unlike $got, '/in:.*/', $msg; },
               },
             };

while (my ($line, $attributes) = each %$matrix) {
    my ($filtered, $contents);
    my $operator = $attributes->{operator};
    my $filter = $attributes->{filter};
    my $param = $attributes->{param};

    $filtered = dancer_response GET => '/api/node', { params => { $param => "$operator,$filter" } };
    is $filtered->{status},
       200,
       "GET on /api/node with attribute ($param) filtered by operator ($operator,$filter) is 200";
    $contents = Dancer::from_json($filtered->{content});

    foreach my $content (@$contents) {
        my $attr = $content->{$param};
        my $msg = "attribute ($param) with value ($attr) on node $content->{node_id} was well filtered with ($operator,$filter)";

        $matrix->{$line}->{function}($attr, $operator, $filter ,$msg);
    }
}
