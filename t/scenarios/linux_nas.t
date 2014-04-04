#!/usr/bin/perl -w

=head1 SCOPE

This scenario starts a NAS cluster with Lvm, iSCSITarget and Nfsd.
It then starts an other cluster that use the previously created cluster
as its disk and export managers.

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ClassType::ComponentType;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'linux_nas.t.log',
    layout=>'%F %L %p %m%n'
});

use BaseDB;
use Entity::ServiceProvider::Cluster;
use Entity::Masterimage;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 0;
my $NB_HYPERVISORS = 1;

main();

sub main {
    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    diag('Register master image');
    my $masterimage = Kanopya::Tools::Register::registerMasterImage();
    
    diag('Create and configure NAS cluster');
    my $nas;
    lives_ok {
        $nas = Kanopya::Tools::Create->createCluster(
            cluster_conf => {
                masterimage_id       => $masterimage->id,
                cluster_name         => 'NAS',
                cluster_basehostname => "nas"
            },
            components => {
                nfsd  => { },
                iscsitarget => { },
                lvm => {
                    lvm2_vgs => [ {
                        lvm2_vg_name => "kanopya",
                        lvm2_vg_size => 10 * 1024 * 1024 * 1024,
                        lvm2_pvs => [ {
                            lvm2_pv_name => "/dev/sda",
                        } ]
                    } ]
                }
            }
        );
    } 'Create cluster';

    # We start the cluster now has the IscsiPortal entry
    # required for the cluster creation is only available once
    # the cluster has been started
    diag('Start NAS');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $nas);
    } 'Start NAS';

    diag('Create and configure cluster with the NAS as its disk manager');
    my $cluster;
    my $lvm = $nas->getComponent(name => "Lvm");
    my @vgs = $lvm->lvm2_vgs;
    my $iscsitarget = $nas->getComponent(name => "Iscsitarget");
    my @iscsi_portals = map { $_->id } $iscsitarget->iscsi_portals;

    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster(
            cluster_conf => {
                masterimage_id       => $masterimage->id,
                cluster_name         => 'UseNAS',
                cluster_basehostname => "usenas"
            },
            managers => {
                disk_manager => {
                    manager_id     => $lvm->id,
                    manager_type   => "DiskManager",
                    manager_params => {
                        vg_id => $vgs[0]->id,
                        systemimage_size => 4 * 1024 * 1024 * 1024,
                    },
                },
                export_manager => {
                    manager_id     => $iscsitarget->id,
                    manager_type   => "ExportManager",
                    manager_params => {
                        iscsi_portals => \@iscsi_portals,
                    }
                },
            }
        );
    } 'Create cluster with the NAS as its disk manager';

    diag('Start cluster');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    diag('Stopping cluster');
    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }
        Kanopya::Tools::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Stopping cluster';

    diag('Stopping NAS');
    lives_ok {
        my ($state, $timestamp) = $nas->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }
        Kanopya::Tools::Execution->executeOne(entity => $nas->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Stopping NAS';

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

1;
