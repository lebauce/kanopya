#   TEST 3.B :
#
#     HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 4       |     CPU Core number = 2       |     CPU Core number = 1       |
#       |     RAM quantity    = 2048    |     RAM quantity    = 2048    |     RAM quantity    = 2048    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |_______________________________|_______________________________|_______________________________|
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 4 -                      | Host 5 -                      | Host 6 -                      |
#       |     CPU Core number = 8       |     CPU Core number = 2       |     CPU Core number = 16      |
#       |     RAM quantity    = 2048    |     RAM quantity    = 2048    |     RAM quantity    = 2048    |
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
#       /   Min CPU Core number = 1       \
#       /   Min RAM quantity    = 2048    \
#       /   Interfaces :                  \
#       /       interface 1 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /                                 \
#       /---------------------------------\
#
sub test3b {
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
                    ram  => 2048*1024*1024,
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
                interface_name => interface1
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
            core          => 4,
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'Iface1',
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
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'Iface2',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 3
    my $host3 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 1,
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'Iface3',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 4
    my $host4 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 8,
            core          => 1,
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'Iface4',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 5
    my $host5 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 1,
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'Iface5',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 6
    my $host6 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 16,
            core          => 1,
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'Iface6',
                    pxe  => 0,
                },
            ],
        },
    );

    ##########################
    #### Perform the test ####
    ##########################

    lives_ok {
        my $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);

        # The selected host must be the 3rd.
        if ($selected_host->id != $host3->id) {
            die ("Test 3.b : Wrong host selected");
        }
    } "Test 3.b : Choosing the host with the best CPU cost";
}

1;
