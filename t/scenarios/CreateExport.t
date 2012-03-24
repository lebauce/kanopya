#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use Operation;
use EContext::Local;
use EFactory;
use Entity::User;

use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => '/tmp/DiskManagement.t.log',
    layout => '%F %L %p %m%n'
});

use Cwd qw(abs_path);
use File::Basename;
use File::Temp;

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('Entity::ServiceProvider::Outside::Netapp');
use_ok ('Entity::Connector::NetappLunManager');
use_ok ('Entity::Connector::NetappVolumeManager');
use_ok ('Entity::Container::NetappVolume');
use_ok ('Entity::Container::NetappLun');

my @args = ();
my $executor = new_ok("Executor", \@args, "Instantiate an executor");
Administrator::authenticate(login => 'admin', password => 'K4n0pY4');
my $adm = Administrator->new;
my $db  = $adm->{db};

sub testCluster {
    my %args = @_;

    my $cluster = $args{cluster};
    my $attr_name = $args{attr_name};
    my %create_args = defined $args{create_args} ? %{$args{create_args}} : ();
    my $econtext = EFactory::newEContext(ip_source      => '127.0.0.1',
                                         ip_destination => '127.0.0.1');

    my ($disk_manager, $edisk_manager);
    my ($export_manager, $eexport_manager);
    my ($disk, $container);

    lives_ok {
        $disk_manager = defined $args{manager} ?
                            $args{manager} :
                            $cluster->getDefaultManager(category => 'DiskManager');

        $edisk_manager = EFactory::newEEntity(data => $disk_manager);
    } 'Retrieve disk manager';

    lives_ok {
        $disk = $edisk_manager->createDisk(
            volume_id  => defined $args{volume_id} ? $args{volume_id} : 0,
            name       => "test_disk",
            size       => $args{size},
            filesystem => "ext4",
            econtext   => $econtext,
            %create_args
        );
    } 'Create disk';

    my $export;
    lives_ok {
        if ($disk_manager->can('createExport')) {
            $eexport_manager = $edisk_manager;
        }
        else {
            $export_manager = defined $args{export_manager} ?
                                  $args{export_manager} :
                                  $cluster->getDefaultManager(category => 'ExportManager');

            $eexport_manager = EFactory::newEEntity(data => $export_manager);
        }

        $export = $eexport_manager->createExport(container   => $disk,
                                                 export_name => "test_disk",
                                                 typeio      => "fileio",
                                                 iomode      => "wb",
                                                 econtext    => $econtext);
    } 'Creating export';

    lives_ok {
        my $eexport = EFactory::newEEntity(data => $export);
        $eexport->connect(econtext => $econtext);
    } 'Connecting to it';

    my $mountpoint = mktemp("tmp-mountpoint-XXXXX");
    lives_ok {
        my $eexport = EFactory::newEEntity(data => $export);
        $eexport->mount(mountpoint => $mountpoint,
                        econtext   => $econtext);
    } 'Mounting';

    lives_ok {
        my $eexport = EFactory::newEEntity(data => $export);
        $eexport->umount(mountpoint => $mountpoint,
                         econtext => $econtext);
    } 'Unmounting';

    lives_ok {
        my $eexport = EFactory::newEEntity(data => $export);
        $eexport->disconnect(econtext => $econtext);
    } 'Disconnecting from it';

    return { disk   => $disk,
             export => $export };

    # Uncomment when ERemoveDisk is implemented
    # lives_ok {
    #     $disk_manager->removeDisk(
    #         container => $disk
    #     );
    # } 'Remove created disk';

    # lives_ok { $executor->oneRun(); } 'RemoveDisk operation execution succeed';
}

eval {
    my $cluster;
    my $physical_hoster;
    my $disk_manager;

    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->find(
            hash => { cluster_name => 'Kanopya' }
        );
        $disk_manager = $cluster->getDefaultManager(category => 'DiskManager');
        $physical_hoster = $cluster->getDefaultManager(category => 'HostManager');
    } 'Retrieve kanopya cluster';

    my $admin_user;
    lives_ok {
		$admin_user = Entity::User->find(hash => { user_login => 'admin' });
     } 'Retrieve the admin user';

    $db->txn_begin;

    my $disks = ();

    push @disks, testCluster(cluster     => $cluster,
                             attr_name   => "lvm2_lv_id",
                             size        => 64 * 1024 * 1024,
                             create_args => { vg_id => 1 });

    my ($lun_manager, $vol_manager);

	SKIP: {
        lives_ok {
            $netapp = Entity::ServiceProvider::Outside::Netapp->create(
                netapp_name         => "netapp",
                netapp_desc         => "netapp",
                netapp_addr         => "127.0.0.1",
                netapp_login        => "kanopya",
                netapp_passwd       => "kanopya",
            );

            $vol_manager = Entity::Connector::NetappVolumeManager->new();
            $netapp->addConnector(connector => $vol_manager);

            $lun_manager = Entity::Connector::NetappLunManager->new();
            $netapp->addConnector(connector => $lun_manager);
	    } 'NetApp equipment successfully added';

        skip("Could not login to the NetApp", 7 * 2);

        my $netapp_volume = testCluster(cluster     => $netapp,
                                        attr_name   => "name",
                                        size        => 128 * 1024 * 1024,
                                        manager     => $vol_manager,
                                        create_args => { noformat => 1 });

        push @disks, $netapp_volume;

        push @disks, testCluster(cluster     => $netapp,
                                 attr_name   => "name",
                                 manager     => $lun_manager,
                                 size        => 4 * 1024 * 1024,
                                 volume_id   => $netapp_volume->{disk}->getAttr(name => "volume_id"),
                                 create_args => { });
    }

    for my $hash (reverse @disks) {
        lives_ok {
            my $disk = $hash->{disk};
            my $export = $hash->{export};
            my $econtext = EFactory::newEContext(ip_source      => "127.0.0.1",
                                                 ip_destination => "127.0.0.1");

            my $manager = Entity->get(id => $export->getAttr(name => "export_manager_id"));
            my $eexport_manager = EFactory::newEEntity(data => $manager);
            $eexport_manager->removeExport(container_access => $export,
                                           econtext  => $econtext);

            $manager = Entity->get(id => $disk->getAttr(name => "disk_manager_id"));
            my $edisk_manager = EFactory::newEEntity(data => $manager);
            $edisk_manager->removeDisk(container => $disk,
                                       econtext  => $econtext);
        } 'Remove create disk';
    }

    $db->txn_rollback;
};
if($@) {
    my $error = $@;
    print Dumper $error;
};
