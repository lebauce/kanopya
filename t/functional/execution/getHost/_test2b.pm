#   TEST 2.B :
#
#     HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 2       |     CPU Core number = 4       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 8192    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |_______________________________|_______________________________|_______________________________|
#
#     CONSTRAINTS (Cluster) :
#
#       /---------------------------------\
#       /                                 \
#       /   Min CPU Core number = 8       \
#       /   Min RAM quantity    = 512     \
#       /   Interfaces :                  \
#       /       interface 1 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /                                 \
#       /---------------------------------\
#
sub test2b {
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
                    core => 8,
                    ram  => 512*1024*1024,
                    tags => [],
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
                interface_name => "eth0",
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
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => "eth0",
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 2
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 2,
            ram           => 8192*1024*1024,
            ifaces        => [
                {
                    name => "eth0",
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 3
    my $host3 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 4,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => "eth0",
                    pxe  => 0,
                },
            ],
        },
    );

    ##########################
    #### Perform the test ####
    ##########################

    throws_ok {
        my $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);
    } 'Kanopya::Exception',
      'Test 2.b : None of the hosts match the minimum CPU constraint';
}

1;
