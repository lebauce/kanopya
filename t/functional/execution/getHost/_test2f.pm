#   TEST 2.F :
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
#       |     Tags : [1]                |     Tags : [1,2]              |     Tags : [2,3]              |
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

sub test2f {
    ########################
    #### Create Tags    ####
    ########################
    my $tag1 = Entity::Tag->new(tag => "Storage");
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
                    core     => 1,
                    ram      => 512*1024*1024,
                    tags_ids => [$tag1->id, $tag2->id, $tag3->id],
                },
            },
        }
    };
    # Create Cluster and add network interface to it
    my $cluster = Kanopya::Tools::Create->createCluster(
        cluster_conf => $host_manager_conf,
    );
    for my $interface ($cluster->interfaces) {
        $interface->delete();
    }
    $cluster->configureInterfaces(
        interfaces => {
            interface1 => {
                interface_netconfs => {$netConf->netconf_name => $netConf },
                bonds_number        => 0,
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
            entity_tags => [$tag1, $tag2],
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
      'Test 2.f : None of the hosts match the minimum tags set constraint';
}

1;
