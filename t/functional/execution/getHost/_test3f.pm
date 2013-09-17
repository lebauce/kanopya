#   TEST 1.F :
#
#       HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 2       |     CPU Core number = 2       |     CPU Core number = 2       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 4096    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |     Tags : [1,2,3,5,6]        |     Tags : [1,2,3]            |     Tags : [1,2,3,4,5]        |
#       |_______________________________|_______________________________|_______________________________|
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 4 -                      | Host 5 -                      | Host 6 -                      |
#       |     CPU Core number = 2       |     CPU Core number = 2       |     CPU Core number = 2       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 4096    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |     Tags : [1,2,3,4]          |     Tags : [1,2,3,6]          |     Tags : [1,2,3,5]          |
#       |_______________________________|_______________________________|_______________________________|
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
#       /   Min Tags : [1,2,3]            \
#       /                                 \
#       /---------------------------------\
#

use Entity::Tag;

sub test3f {
    ########################
    #### Create Tags    ####
    ########################
    my $tag1 = Entity::Tag->new(tag => "Not free Massage");
    my $tag2 = Entity::Tag->new(tag => "High Performance");
    my $tag3 = Entity::Tag->new(tag => "Beer dispenser");
    my $tag4 = Entity::Tag->new(tag => "Free Massage");
    my $tag5 = Entity::Tag->new(tag => "Popcorn Machine");
    my $tag6 = Entity::Tag->new(tag => "PS3");

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
                    core => 1,
                    ram  => 512*1024*1024,
                    tags => [$tag1->id, $tag2->id, $tag3->id],
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
            core          => 2,
            ram           => 4096*1024*1024,
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
            entity_tags => [$tag1, $tag2, $tag3, $tag4, $tag5, $tag6],
        }
    );

    # Create Host 2
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
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
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host3->populateRelations(
        relations => {
            entity_tags => [$tag1, $tag2, $tag3, $tag4, $tag5],
        }
    );

    # Create Host 4
    my $host4 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 4,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host4->populateRelations(
        relations => {
            entity_tags => [$tag1, $tag2, $tag3, $tag4],
        }
    );

    # Create Host 5
    my $host5 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 5,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host5->populateRelations(
        relations => {
            entity_tags => [$tag1, $tag2, $tag3, $tag6],
        }
    );

    # Create Host 6
    my $host6 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 6,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host6->populateRelations(
        relations => {
            entity_tags => [$tag1, $tag2, $tag3, $tag5],
        }
    );

    ##########################
    #### Perform the test ####
    ##########################

    lives_ok {
        my $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);

        # The selected host must be the 2nd.
        if ($selected_host->id != $host2->id) {
            die ("Test 3.f : Wrong host selected");
        }
    } "Test 3.f : Choosing the host with the best tags cost";
}

1;
