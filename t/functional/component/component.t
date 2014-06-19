#!/usr/bin/perl -w

use Test::More 'no_plan';

use Test::Exception;
use Test::Pod;

use General;
use Kanopya::Exceptions;
use Entity::Component::KanopyaExecutor;
use Entity::Node;
use EEntity;

use Data::Dumper;
use File::Basename;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => basename(__FILE__) . '.log',
    layout => '%F %L %p %m%n'
});



my $componenttype = "Lvm2";
my $ip = "10.0.0.1";
my $hostname = `hostname`;

Kanopya::Database::authenticate(login => 'admin', password => '_tamere23');

eval {
    # Firstly initialize the execution lib with the local host on which the code is running.
    # TODO: Do not require a Host object for the execution lib initialization...
    my $hostname = `hostname`;
    chomp($hostname);
    EEntity->new(entity => Entity::Host->find(hash => { 'node.node_hostname' => $hostname }));

    # Firstly find/register the node where to test the running component
    diag('Find/Register the node where to test the component ' . $componenttype);
    my $node = Entity::Node->findOrCreate(node_hostname => $hostname);
    if (! defined $node->admin_ip_addr) {
        $node->admin_ip_addr($ip);
    }

    my $component;
    eval {
        (my $componentname = $componenttype) =~ s/\d+//g;
        $component = $node->getComponent(name => $componentname);
        diag('Component ' . $componenttype . ' found on node ' . $node->label);
    };
    if ($@) {
        my $componentclass = BaseDB->_classType(classname => $componenttype);

        General::requireClass($componentclass);

        diag('Get any executor');
        my $executor = Entity::Component::KanopyaExecutor->find();

        # Create the component
        $component = $componentclass->new(executor_component => $executor);

        # And register it on the node
        $component->registerNode(node => $node, master_node => 1);
        diag('Created and registred ' . $componenttype . ' on node ' . $node->label);
    }

    diag('Check for component ' . $component->label . ' up');
    lives_ok {
        if (! EEntity->new(entity => $component)->isUp(node => EEntity->new(entity => $node))) {
            die 'Component ' . $component->label . ' not up';
        }

    } 'Check for component ' . $component->label . ' up';

    diag('Run test suite for component ' . $component->label);
    my $testsuiteclass = "Kanopya::Test::Test" . $componenttype;

    General::requireClass($testsuiteclass);

    $testsuiteclass->runTestSuite(component => $component);

};
if ($@) {
    my $error = $@;
    print Dumper $error;
};
