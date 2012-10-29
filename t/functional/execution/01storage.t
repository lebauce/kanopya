#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;

use Kanopya::Exceptions;
use EContext::Local;
use EFactory;
use Entity::User;
use ERollback;

use Data::Dumper;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => '/tmp/01storage.t.log',
    layout => '%F %L %p %m%n'
});

use Cwd qw(abs_path);
use File::Basename;
use File::Temp;

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('Entity::ServiceProvider::Inside::Cluster');

#use_ok ('Entity::ServiceProvider::Outside::Netapp');
#use_ok ('Entity::Connector::NetappLunManager');
#use_ok ('Entity::Connector::NetappVolumeManager');
#use_ok ('Entity::Container::NetappVolume');
#use_ok ('Entity::Container::NetappLun');

my @args = ();

my @disks   = ();
my @exports = ();    

lives_ok {
    Administrator::authenticate(login => 'admin', password => 'K4n0pY4');
} 'Connect to database';

my $adm = Administrator->new;
my $db  = $adm->{db};


sub testDiskManager {
    my %args = @_;

    my $disk_manager = $args{component};
    my $create_args  = defined $args{create_args} ? $args{create_args} : {};

    my $size = defined $args{size} ? $args{size} : 64 * 1024 * 1024;

    my $econtext;
    lives_ok {
        $econtext = EContext::Local->new(local => '127.0.0.1');

    } 'Instanciate local EContext';

    my ($edisk_manager, $eexport_manager);
    lives_ok {
        $edisk_manager = EFactory::newEEntity(data => $disk_manager);

    } "Retrieve disk manager $disk_manager";

    # Create a disk
    my $disk;
    lives_ok {
        $disk = $edisk_manager->createDisk(
                    name       => $size . "_" . $disk_manager->id,
                    size       => $size,
                    filesystem => "ext4",
                    econtext   => $econtext,
                    %$create_args
                );

    } "Create disk with $disk_manager";

    if ($disk) {
        # Search for export components within the same service provider
        my $exportcomponents = $disk_manager->getExportManagers;
        for my $export_manager (@$exportcomponents) {
            lives_ok {
                $eexport_manager = EFactory::newEEntity(data => $export_manager);
            } "Retrieve export manager $export_manager";

            my $export;
            lives_ok {
                $export = $eexport_manager->createExport(container   => $disk,
                                                         export_name => "export_" . $disk->id . "_" . $export_manager->id,
                                                         econtext    => $econtext);
            } "Creating export of disk $disk";

            my $mountpoint = mktemp("tmp-mountpoint-XXXXX");
            lives_ok {
                $export->mount(mountpoint => $mountpoint, econtext => $econtext);
            } 'Mounting';

            lives_ok {
                $export->umount(mountpoint => $mountpoint, econtext => $econtext);
            } 'Unmounting';

            lives_ok {
                $eexport_manager->removeExport(container_access => $export, econtext => $econtext);
            } "Removing export $export";
        }
    }
    return $disk;
}

eval {
    $adm->beginTransaction;

    my $econtext;
    lives_ok {
        $econtext = EContext::Local->new(local => '127.0.0.1');

    } 'Instanciate local EContext';

    my $erollback;
    lives_ok {
        $erollback = ERollback->new();

    } 'Instanciate ERollback';
 
    # This test loop over the diskmanagers, create a disk with on each,
    # then create an export with each export manager available for this disk manager.

    # Firstly create the netapp or skip
#    lives_ok {
#        Entity::ServiceProvider::Outside::Netapp->create(
#            netapp_name   => "netapp",
#            netapp_desc   => "netapp",
#            netapp_addr   => "127.0.0.1",
#            netapp_login  => "kanopya",
#            netapp_passwd => "kanopya",
#        );
#    } 'NetApp equipment successfully added';

    # Search for disk managers
    my @fileimagemanagers;
    my @serivceproviders = Entity::ServiceProvider->search(hash => {});
    for $provider (@serivceproviders) {
        
        my @storagecomponents;
        lives_ok {
            @storagecomponents = $provider->getComponents(category => 'Storage');

        } "Retreive storgae components from service provider $provider";

        for $component (@storagecomponents) {
            # Synchronize the component if supported
            if ($component->can('synchronize')) {
                $component->synchronize();
            }

            if ($component->isa('Entity::Component::Fileimagemanager0')) {
                push @fileimagemanagers, $component;
            }
            else {
                my $exportcomponents = $component->getExportManagers;

                # Test the component, create a disk and export it with all possbile
                # export component on its service provider.
                for my $size (256, 128, 64, 32, 16) {
                    my $disk = testDiskManager(component => $component, size => $size * 1024 * 1024);
                    push @disks, $disk;

                    # At the end of the loop, we have exactly the same number of exported disks
                    # of this type as the number of export managers available for this type of disk.
                    my $export_manager = pop @$exportcomponents;
                    if ($export_manager) {
                        my $eexport_manager;
                        lives_ok {
                            $eexport_manager = EFactory::newEEntity(data => $export_manager);
                        } "Retrieve export manager $export_manager";

                        lives_ok {
                            my $export = $eexport_manager->createExport(container   => $disk,
                                                                        export_name => "export_" . $disk->id . "_" . $export_manager->id,
                                                                        econtext    => $econtext);
                            push @exports, $export;
                        } "Creating export of disk $disk";
                    }
                }
            }
        }
    }

    # Specific test for the Fileimage manager that use an existing export to create disks.
    for my $fileimagemanager (@fileimagemanagers) {
        my @fileimagemanager_exports = @exports;
        for $export (@fileimagemanager_exports) {
            my $disk = testDiskManager(component   => $fileimagemanager,
                                       create_args => { container_access_id => $export->id,
                                                        noformat            => 1 },
                                       size        => $export->container->container_size / scalar(@{ $export->container->getAccesses }));
            push @disks, $disk;
        }
    }

    # Copy all containers to the others
    for my $src_disk (@disks) {
        for $dest_disk (@disks) {
            # Search for file containers stored on the destination disk.
            my @destaccesses = $dest_disk->container_accesses;
            my @srcaccesses  = $src_disk->container_accesses;

            # If disks differ, and dest do not host inner disks, copy
            if ($src_disk->id != $dest_disk->id) {
                if ($src_disk->container_size > $dest_disk->container_size) {
                    throws_ok {
                        eval {
                            $src_disk->copy(dest => $dest_disk, econtext => $econtext, erollback => $erollback);
                        };
                        if ($@) {
                            my $error = $@;
                            $erollback->undo();
                            throw $error;
                        }
    
                    } "Kanopya::Exception::Execution",
                      "Try copying $src_disk to $dest_disk, but source size < dest size.";
                }
                elsif (scalar(@destaccesses) or scalar(@srcaccesses)) {
                    throws_ok {
                        eval {
                            $src_disk->copy(dest => $dest_disk, econtext => $econtext, erollback => $erollback);
                        };
                        if ($@) {
                            my $error = $@;
                            $erollback->undo();
                            throw $error;
                        }
    
                    } "Kanopya::Exception::Execution::ResourceBusy",
                      "Try copying $src_disk to $dest_disk, but one of the containers is already exported.";
                }
                else {
                    lives_ok {
                        $src_disk->copy(dest => $dest_disk, econtext => $econtext);
                    } "Copying $src_disk to $dest_disk";
                }
            }
        }
    }

    my $handlefilecontainer = 1;
    while (scalar(@exports) or scalar(@disks)) {
        my (@nextdisks, @nextexports);

        # At the first loop, remove exports from Fileimagemanager and disks from Fileimagemanager,
        # then remove the other exports and disks at the second loop.
        for my $export (reverse @exports) {
            if (not $handlefilecontainer or $export->isa('EEntity::EContainerAccess::EFileContainerAccess')) {
                lives_ok {
                    my $eexport_manager = EFactory::newEEntity(data => $export->getExportManager);
                    $eexport_manager->removeExport(container_access => $export, econtext => $econtext);
        
                } "Remove export $export";   
            }
            else {
                push @nextexports, $export;
            }
        }
        for my $disk (reverse @disks) {
            if (not $handlefilecontainer or $disk->isa('EEntity::EContainer::EFileContainer')) {
                lives_ok {
                    my $edisk_manager = EFactory::newEEntity(data => $disk->getDiskManager);
                    $edisk_manager->removeDisk(container => $disk, econtext => $econtext);
    
                } "Remove disk $disk";
            }
            else {
                if (scalar @{ $disk->getAccesses }) {
                    # Try to remove disks still exported
                    throws_ok {
                        eval {
                            my $edisk_manager = EFactory::newEEntity(data => $disk->getDiskManager);
                            $edisk_manager->removeDisk(container => $disk, econtext => $econtext, erollback => $erollback);
                        };
                        if ($@) {
                            my $error = $@;
                            $erollback->undo();
                            throw $error;
                        }
    
                    } "Kanopya::Exception::Execution::ResourceBusy",
                      "Try remove disk $disk, but still exported.";
                }
                push @nextdisks, $disk;
            }
        }
        $handlefilecontainer = 0;

        @disks = @nextdisks;
        @exports = @nextexports;
    }

    $adm->rollbackTransaction;
};
if($@) {
    my $error = $@;
    print Dumper $error;
};
