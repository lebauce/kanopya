#!/usr/bin/perl -w

use Test::More 'no_plan';

use Test::Exception;
use Test::Pod;

use General;
use Kanopya::Exceptions;
use Entity::Component::KanopyaExecutor;
use Entity::Node;
use EEntity;

use Kanopya::Test::Register;

use Data::Dumper;
use File::Basename;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => basename(__FILE__) . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

my $testing = 1;

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
                     optional => { 'NODE_IP'       => undef,
                                   'NODE_HOSTNAME' => 'kanopyamaster' });

my @types = split(',', $envargs->{COMPONENTS});
my $ip = $envargs->{NODE_IP} || Entity::Node->find(hash => { 'node_hostname' => 'kanopyamaster' })->adminIp;
my $hostname = $envargs->{NODE_HOSTNAME};


# Firstly initialize the execution lib with the local host on which the code is running.
# TODO: Do not require a Host object for the execution lib initialization...
my $localhostname = `hostname`;
chomp($localhostname);
EEntity->new(entity => Entity::Host->find(hash => { 'node.node_hostname' => $localhostname }));

diag("Running test suite of components $envargs->{COMPONENTS} installed on existing node $hostname ($ip)");

for my $componenttype (@types) {
    # Firstly find/register the node where to test the running component
    diag('Find/Register the node where to test the component ' . $componenttype);

    my $component = Kanopya::Test::Register->registerComponentOnNode(
                        componenttype => $componenttype,
                        hostname      => $hostname,
                        ip_addr       => $ip
                    );

    my $node = Entity::Node->findOrCreate(node_hostname => $hostname);
    diag('Check for component ' . $component->label . ' up');
    lives_ok {
        if (! EEntity->new(entity => $component)->isUp(node => EEntity->new(entity => $node))) {
            die 'Component ' . $component->label . ' not up';
        }

    } 'Check for component ' . $component->label . ' up';

    diag('Run test suite for component ' . $component->label);
    my $testsuiteclass = "Kanopya::Test::Test" . $componenttype;

    General::requireClass($testsuiteclass);

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    $testsuiteclass->runTestSuite(component => $component);

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}


