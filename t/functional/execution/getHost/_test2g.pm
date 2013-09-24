#   TEST 2. :
#
#       HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 4       |     CPU Core number = 2       |
#       |     RAM quantity    = 512     |     RAM quantity    = 8192    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |     Deploy_on_disk : NO       |     Deploy_on_disk : NO       |     Deploy_on_disk : NO       |
#       |     Tags : [1]                |     Tags : [1,2,3]            |     Tags : [2,3]              |
#       |_______________________________|_______________________________|_______________________________|
#
#
#       CONSTRAINTS (Cluster) :
#
#       /---------------------------------\
#       /                                 \
#       /   Min CPU Core number = 1       \
#       /   Min RAM quantity    = 512     \
#       /   Interfaces :                  \
#       /       interface 1 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /   Deploy_on_disk : required     \
#       /   Min Tags : []                 \
#       /                                 \
#       /---------------------------------\
#

use Entity::Tag;

sub test2g {
    ########################
    #### Create Tags    ####
    ########################
    my $tag1 = Entity::Tag->new(tag => "Massage");
    my $tag2 = Entity::Tag->new(tag => "High Performance");
    my $tag3 = Entity::Tag->new(tag => "Beer dispenser");

    ########################
    #### Create Cluster ####
    ########################

    # Create NetConf
    my $netConf =  Entity::Netconf->create(
        netconf_name => 'netconf',
    );
    # Host Manager config
    my $host_manager_conf = {
        managers              => {
            host_manager => {
                manager_params => {
                    core           => 1,
                    ram            => 512*1024*1024,
                    deploy_on_disk => 1,
                    tags           => [],
                },
            },
        }
    };
    # Create Cluster and add network interface to it
    my $cluster = Kanopya::Tools::Create->createCluster(
        cluster_conf => $host_manager_conf,
    );

    Kanopya::Tools::Execution->executeAll();

    for my $interface ($cluster->interfaces) {
        $interface->delete();
    }
    $cluster->configureInterfaces(
        interfaces => {
            interface1 => {
                netconfs       => {$netConf->netconf_name => $netConf },
                bonds_number   => 0,
                interface_name => interface1,
            },
        }
    );

    ######################
    #### Create Hosts ####
    ######################

    # Create Host 1
    my $host1 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 1,
            core          => 1,
            ram           => 512*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host1->populateRelations(
        relations => {
            entity_tags => [$tag1],
        }
    );

    # Create Host 2
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 4,
            ram           => 8192*1024*1024,
            ifaces        => [
                {
                    name => 'Une iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host2->populateRelations(
        relations => {
            entity_tags => [$tag1, $tag2, $tag3],
        }
    );

    # Create Host 3
    my $host3 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'i',
                    pxe  => 0,
                },
            ],
        },
    );
    $host3->populateRelations(
        relations => {
            entity_tags => [$tag2, $tag3],
        }
    );

    ##########################
    #### Perform the test ####
    ##########################

    throws_ok {
        my $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);
    } 'Kanopya::Exception',
      'Test 2.g : None of the hosts have a disk for a deployment on disk';
}

1;
