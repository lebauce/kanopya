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

my %operators = (eq => '=',
                 ne => '<>',
                 le => '<=',
                 lt => '<',
                 ge => '>=',
                 gt => '>',
                 bw => 'LIKE',
                 bn => 'NOT LIKE');

my %filters = ('='  => 'disabled',
               '<>' => 'enabled',
               '<=' => 1,
               '<'  => 2,
               '>'  => 1,
               '>=' => 2,
               'LIKE'     => 'in%',
               'NOT LIKE' => 'in%');

my %attributes = ($operators{bw} => 'node_state',
                  $operators{bn} => 'node_state',
                  $operators{eq} => 'monitoring_state',
                  $operators{ne} => 'monitoring_state',
                  $operators{le} => 'node_id',
                  $operators{lt} => 'node_id',
                  $operators{ge} => 'node_id',
                  $operators{gt} => 'node_id');


while (my ($operator, $attribute) = each %attributes) {
    my ($filtered, $contents);

    $filtered = dancer_response GET => '/api/node',
                                { params => { $attribute => "$operator,$filters{$operator}" } };
    is $filtered->{status},
       200,
       "GET on /api/node with attribute ($attribute) filtered by operator ($operator,$filters{$operator}) is 200";
    $contents = Dancer::from_json($filtered->{content});

    foreach my $content (@$contents) {
        my $attr = $content->{$attribute};

        if ($operator eq 'LIKE') {
            like $attr,
                 '/in:.*/',
                 "node $content->{node_id} has good filtered state for ($operator,$filters{$operator})";
        }
        elsif ($operator eq 'NOT LIKE') {
            like $attr,
                 '/[^in]*/',
                 "node $content->{node_id} has good filtered state for ($operator,$filters{$operator})";
        }
        elsif ($operator eq '<' || $operator eq '<=' || $operator eq '>' || $operator eq '>=') {
            cmp_ok $attr, $operator, $filters{$operator},
                   "node $content->{node_id} has good filtered state for ($operator,$filters{$operator})";
        }
        elsif ($operator eq '=' || $operator eq '<>') {
            is $attr, 'disabled',
               "node $content->{node_id} has good filtered state for ($operator,$filters{$operator})";
        }
    }
}
