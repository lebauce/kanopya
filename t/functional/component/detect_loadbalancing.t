#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use Kanopya::Test::Execution;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'detect_loadbalancing.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});
my $log = get_logger("");

use Kanopya::Database;
use BaseDB;

use Entity::Node;
use Entity::Component::Apache2;
use Entity::Component::Haproxy1;

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

# Get Executor
my $executor = Entity::Component::KanopyaExecutor->find();

# Create nodes and components
my $node = Entity::Node->new(node_hostname  => 'node');
my $apache2 = Entity::Component::Apache2->new(executor_component => $executor);
$apache2->registerNode(node => $node, master_node => 1);

# TEST ! (Before cake time)
ok($node->isLoadBalanced() == 0, 'Node without HAProxy');

# Add loadbalancer
my $haproxy = Entity::Component::Haproxy1->new(executor_component => $executor);
$haproxy->registerNode(node => $node, master_node => 1);

# Re-TEST (Think to delicious cake)
ok($node->isLoadBalanced() == 1, 'Node with HAProxy');

# THE CAKE IS A LIE !
