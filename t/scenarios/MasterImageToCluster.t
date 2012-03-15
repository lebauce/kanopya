#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use Operation;
use EContext::Local;
use EFactory;

use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => '/tmp/MasterImageToCluster.t.log',
    layout => '%F %L %p %m%n'
});

use Cwd qw(abs_path);
use File::Basename;

my $pwd = dirname(abs_path($0));
my $master_name = 'test_masterimage';
my $master_archive =  $pwd . '/' . $master_name . '.tar.bz2';

my $metadataxml = '<masterimage file=\"' . $master_name . '.img\">
<name>' . $master_name . '</name>
<description>An empty image just for tests</description>
<os>nothing</os>
<arch>amd64</arch>
</masterimage>';

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('EFactory');
use_ok ('EContext');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Systemimage');
use_ok ('Entity::ServiceProvider::Inside::Cluster');

# Test the existance of the master image test file.
if(! -e $master_archive) {

    # Creating fake master image for test
    system("dd if=/dev/zero of=$pwd/$master_name.img bs=1M count=64 2>/dev/null");
    system("losetup /dev/loop7 $pwd/$master_name.img >/dev/null");

    #...
    system("fdisk /dev/loop7 << EOF
n
p
1


w
EOF
 2>/dev/null 1>/dev/null");

    system("kpartx -a /dev/loop7 >/dev/null");
    system("mkfs -t ext3 /dev/mapper/loop7p1 >/dev/null");
    system("mkdir -p /mnt/$master_name.img; mount /dev/mapper/loop7p1 /mnt/$master_name.img >/dev/null");
    system("cp -R --preserve=all /etc/. /mnt/$master_name.img/ >/dev/null");
    system("umount /mnt/$master_name.img/ >/dev/null");
    system("kpartx -d /dev/loop7 >/dev/null");
    system("losetup -d /dev/loop7 >/dev/null");
    system("echo \"$metadataxml\" > $pwd/img-metadata.xml");
    system("tar -cvjf $master_name.tar.bz2 $master_name.img img-metadata.xml >/dev/null");
    system("rm $master_name.img img-metadata.xml >/dev/null");

    if(! -e $master_archive) {
        ok (-e $master_archive, "Test master image required");
    
        BAIL_OUT('Cannot find test master image file: ' . $master_archive);
    }
}

# Test root access
if ($< != 0) {
    ok ($< == 0, "Root access required");

    BAIL_OUT('You need to be root.');
}

eval {
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    Administrator::authenticate(login => 'admin', password => 'K4n0pY4');
    my $adm = Administrator->new;
    my $db  = $adm->{db};

    $db->txn_begin;

    # Deploy master image
    lives_ok {
        Operation->enqueue(
            priority => 200,
            type     => 'DeployMasterimage',
            params   => {
                file_path => $master_archive,
                keep_file => 1,
            },
        );
    } 'DeployMasterimage operation enqueue';

    lives_ok { $executor->oneRun(); } 'DeployMasterimage operation execution succeed';

	my $master_image;
	lives_ok {
		$master_image = Entity::Masterimage->find(
                            hash => {
                                masterimage_name => $master_name,
                            }
                        );
	} 'Retrieve master image';

    # Create and export a container for file image hosting (lvm2/Nfsd3)
    my ($kpc_cluster, $disk_manager, $export_manager);
    lives_ok {
        $kpc_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                           hash => { cluster_name => 'Kanopya' }
                       );

        $edisk_manager   = EFactory::newEEntity(
                               data => $kpc_cluster->getComponent(name => "Lvm", version => "2")
                           );
        $eexport_manager = EFactory::newEEntity(
                               data => $kpc_cluster->getComponent(name => "Nfsd", version => "3")
                           );
    } 'Get KPC cluster, disk manager ans export manager instances';

    my $econtext;
    lives_ok {
        $econtext = EContext::Local->new(local => '127.0.0.1');
    } 'Instanciate an econtext';

    my $container;
    lives_ok {
        $container = $edisk_manager->createDisk(name       => 'test_volume_for_nfs_export',
                                                size       => '5G',
                                                filesystem => 'ext3',
                                                econtext   => $econtext);
    } 'Create a large lvm volume (5G)';

    my $container_access;
    lives_ok {
        $container_access = $eexport_manager->createExport(container   => $container,
                                                           export_name => 'test_volume_for_nfs_export',
                                                           econtext    => $econtext);
    } 'Create nfs export for file image hosting';

    # Loop over disk managers.
    my $storage_provider_id;
    lives_ok {
        $storage_provider_id = $kpc_cluster->getAttr(name => 'cluster_id');
    } 'Get storage_provider_id';


    for my $disk_manager_current ($kpc_cluster->getComponent(name => "Lvm", version => "2"),
                                  $kpc_cluster->getComponent(name => "Fileimagemanager", version => "0")) {

        my $disk_manager_id;
        my $disk_manager_custom_params = { container_access_id => $container_access->getAttr(name => 'container_access_id') };
        lives_ok {
            $disk_manager_id = $disk_manager_current->getAttr(name => 'component_id');
        } 'Get storage_provider_id';

        # Add system image from distribution
        my $systemimage_name = 'TestScenario_' . $storage_provider_id . '_' . $disk_manager_id;

        lives_ok {
            Entity::Systemimage->create(
                storage_provider_id => $storage_provider_id,
                disk_manager_id     => $disk_manager_id,
                systemimage_name    => $systemimage_name,
                systemimage_desc    => 'System image for test scenario MasterImageToCluster.',
                masterimage_id      => $master_image->getAttr(name => 'masterimage_id'),
                %{$disk_manager_custom_params}
            );
        } 'AddSytemImage operation enqueue';
        
        lives_ok { $executor->oneRun(); } 'AddSytemImage operation execution succeed';

        my $systemimage;
        lives_ok {
            $systemimage = Entity::Systemimage->find(
                               hash => {
                                   systemimage_name => $systemimage_name,
                               }
                           );
        } 'Retrieve system image ' . $systemimage_name;

        # Clone system image
        my $systemimage_id = $systemimage->getAttr(name => 'systemimage_id');
        my $clone_name = 'Clone' . $systemimage_name;
        lives_ok {
            Operation->enqueue(
                priority => 200,
                type     => 'CloneSystemimage',
                params   => {
                    storage_provider_id => $storage_provider_id,
                    disk_manager_id     => $disk_manager_id,
                    systemimage_id      => $systemimage_id,
                    systemimage_name    => $clone_name,
                    systemimage_desc    => 'System image for test scenario MasterImageToCluster.',
                    %{$disk_manager_custom_params}
                },
            );
        } 'CloneSystemImage operation enqueue';
        
        lives_ok { $executor->oneRun(); } 'CloneSystemImage operation execution succeed';

        my $clone;
        lives_ok {
            $clone = Entity::Systemimage->find(
                         hash => {
                             systemimage_name => $clone_name,
                         }
                     );
        } 'Retrieve system image ' . $clone_name;

        # Remove clone system image
        lives_ok {
            Operation->enqueue(
                priority => 200,
                type     => 'RemoveSystemimage',
                params   => {
                    systemimage_id => $clone->getAttr(name => 'systemimage_id')
                },
            );
        } 'RemoveSystemImage (clone) operation enqueue';
        
        lives_ok { $executor->oneRun(); } 'RemoveSystemImage operation execution succeed';

        # Remove system image
        lives_ok {
            Operation->enqueue(
                priority => 200,
                type     => 'RemoveSystemimage',
                params   => {
                    systemimage_id => $systemimage_id
                },
            );
        } 'RemoveSystemImage operation enqueue';
        
        lives_ok { $executor->oneRun(); } 'RemoveSystemImage operation execution succeed';

        throws_ok {
            Entity::Systemimage->get(id => $systemimage_id);
        } 'Kanopya::Exception::DB',
          'Systemimage removed ' . $systemimage_name . ', id ' . $systemimage_id;
    }

    lives_ok {
        $eexport_manager->removeExport(container_access => $container_access,
                                       econtext         => $econtext);
    } 'Remove nfs export for file image hosting';

    lives_ok {
        $edisk_manager->removeDisk(container => $container,
                                   econtext  => $econtext);
    } 'Remove large lvm volume';

    $db->txn_rollback;

    };
if($@) {
    my $error = $@;
    print Dumper $error;
};
