#   TEST 3.A :
#
#       HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 1       |     CPU Core number = 1       |
#       |     RAM quantity    = 2048    |     RAM quantity    = 8192    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |_______________________________|_______________________________|_______________________________|
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 4 -                      | Host 5 -                      | Host 6 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 1       |     CPU Core number = 1       |
#       |     RAM quantity    = 1536    |     RAM quantity    = 1024    |     RAM quantity    = 16384   |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |_______________________________|_______________________________|_______________________________|
#
#       CONSTRAINTS (Cluster) :
#
#       /---------------------------------\
#       /                                 \
#       /   Min CPU Core number = 1       \
#       /   Min RAM quantity    = 1024    \
#       /   Interfaces :                  \
#       /       interface 1 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /                                 \
#       /---------------------------------\
#
sub test3a {
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
                    ram      => 1024*1024*1024,
                    tags_ids => [],
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
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'iface1',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 2
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 1,
            ram           => 8192*1024*1024,
            ifaces        => [
                {
                    name => 'iface2',
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
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface3',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 4
    my $host4 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 4,
            core          => 1,
            ram           => 1536*1024*1024,
            ifaces        => [
                {
                    name => 'iface4',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 5
    my $host5 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 5,
            core          => 1,
            ram           => 1024*1024*1024,
            ifaces        => [
                {
                    name => 'iface5',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 6
    my $host6 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 6,
            core          => 1,
            ram           => 3072*1024*1024,
            ifaces        => [
                {
                    name => 'iface6',
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

        # The selected host must be the 5th.
        if ($selected_host->id != $host5->id) {
            die ("Test 3.a : Wrong host selected");
        }
    } "Test 3.a : Choosing the host with the best RAM cost";
}

1;
