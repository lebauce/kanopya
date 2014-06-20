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

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

my $envargs = \%ENV;

# Arg the optional mechanism accept undef values
if (exists $envargs->{NODE_IP} && (! defined $envargs->{NODE_IP} || $envargs->{NODE_IP} eq '')) {
    delete $envargs->{NODE_IP};
}
if (exists $envargs->{NODE_HOSTNAME} && (! defined $envargs->{NODE_HOSTNAME} || $envargs->{NODE_HOSTNAME} eq '')) {
    delete $envargs->{NODE_HOSTNAME};
}

General::checkParams(args     => $envargs,
                     required => [ 'COMPONENTS' ],
                     optional => { 'NODE_IP' => Entity::Node->find(hash => { 'node_hostname' => 'kanopyamaster' })->adminIp,
                                   'NODE_HOSTNAME' => 'kanopyamaster' });

my @types = split(',', $envargs->{COMPONENTS});
my $componenttype = pop(@types);
my $ip = $envargs->{NODE_IP};
my $hostname = $envargs->{NODE_HOSTNAME};


# Firstly initialize the execution lib with the local host on which the code is running.
# TODO: Do not require a Host object for the execution lib initialization...
my $localhostname = `hostname`;
chomp($localhostname);
EEntity->new(entity => Entity::Host->find(hash => { 'node.node_hostname' => $localhostname }));

diag("Running test suite of components $envargs->{COMPONENTS} installed on existing node $hostname ($ip)");

# Firstly find/register the node where to test the running component
diag('Find/Register the node where to test the component ' . $componenttype);
my $node = Entity::Node->findOrCreate(node_hostname => $hostname);
if (! defined $node->adminIp) {
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

