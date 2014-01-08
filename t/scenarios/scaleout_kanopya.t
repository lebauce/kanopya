#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ClassType::ComponentType;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'scaleout_kanopya.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;
use Entity::ServiceProvider::Cluster;
use Entity::Container::LocalContainer;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 0;

main();

sub main {
    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    my $executor = $kanopya->getComponent(name => 'KanopyaExecutor');
    my $front = $kanopya->getComponent(name => 'KanopyaFront');

    $kanopya->masterimage_id($masterimage->id);
    $kanopya->kernel_id($masterimage->masterimage_defaultkernel_id);

    my $nfs = $kanopya->getComponent(name => 'Nfsd');

    my %shares = (
        clusters => "/var/lib/kanopya/clusters",
        tftp => "/var/lib/kanopya/tftp",
        masterimages => "/var/lib/kanopya/masterimages"
    );

    for my $name (keys %shares) {
        my $folder = Entity::Container::LocalContainer->new(
            container_name => $name,
            container_device => $shares{$name},
            container_size => "1000000",
        );

        Kanopya::Tools::Execution->executeOne(
            entity => $nfs->createExport(
                          container => $folder,
                          client_name => "*",
                          client_options => "rw,no_root_squash"
                      )
        );
    }

    my $system = $kanopya->getComponent(category => "System");

    for my $export ($nfs->container_accesses) {
        $system->addMount(
            mountpoint => (split(':', $export->container_access_export))[1],
            filesystem => "nfs",
            device => $export->container_access_export
        );
    }

    diag('Adding new executor node');
    lives_ok {
        my $node = Kanopya::Tools::Execution->addNode(
                       cluster => $kanopya,
                       component_types => [
                           $executor->component_type_id,
                           $front->component_type_id
                       ]
                   );
    } 'Adding new executor node';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
