#   TEST 3.D :
#
#     HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 1       |     CPU Core number = 1       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 4096    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 2  |             Bonds number = 1  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |_______________________________|_______________________________|_______________________________|
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 4 -                      | Host 5 -                      | Host 6 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 1       |     CPU Core number = 1       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 4096    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 3  |             Bonds number = 4  |             Bonds number = 5  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |_______________________________|_______________________________|_______________________________|
#
#     CONSTRAINTS (Cluster) :
#
#       /---------------------------------\
#       /                                 \
#       /   Min CPU Core number = 1       \
#       /   Min RAM quantity    = 4096    \
#       /   Interfaces :                  \
#       /       interface 1 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /                                 \
#       /---------------------------------\
#
sub test3d {
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
                    ram  => 4096*1024*1024,
                    tags => [],
                },
            },
        }
    };
    # Create Cluster and add network interfaces to it
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
                    name => 'eth0',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 2
    my $master_iface_name2 = 'eth0';
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 1,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => $master_iface_name2,
                    pxe  => 0,
                },
                    {
                        name   => 'eth1',
                        pxe    => 0,
                        master => $master_iface_name2,
                    },
                    {
                        name   => 'eth2',
                        pxe    => 0,
                        master => $master_iface_name2,
                    },
            ],
        },
    );
    # Create Host 3
    my $master_iface_name3 = 'eth0';
    my $host3 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 1,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => $master_iface_name3,
                    pxe  => 0,
                },
                    {
                        name   => 'eth1',
                        pxe    => 0,
                        master => $master_iface_name3,
                    },
            ],
        },
    );
    # Create Host 4
    my $master_iface_name4 = 'eth0';
    my $host4 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 4,
            core          => 1,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => $master_iface_name4,
                    pxe  => 0,
                },
                    {
                        name   => 'eth1',
                        pxe    => 0,
                        master => $master_iface_name4,
                    },
                    {
                        name   => 'eth2',
                        pxe    => 0,
                        master => $master_iface_name4,
                    },
                    {
                        name   => 'eth3',
                        pxe    => 0,
                        master => $master_iface_name4,
                    },
            ],
        },
    );
    # Create Host 5
    my $master_iface_name5 = 'eth0';
    my $host5 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 5,
            core          => 1,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => $master_iface_name5,
                    pxe  => 0,
                },
                    {
                        name   => 'eth1',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
                    {
                        name   => 'eth2',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
                    {
                        name   => 'eth3',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
                    {
                        name   => 'eth4',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
            ],
        },
    );
    # Create Host 6
    my $master_iface_name6 = 'eth0';
    my $host6 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 6,
            core          => 1,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => $master_iface_name6,
                    pxe  => 0,
                },
                    {
                        name   => 'eth1',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'eth2',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'eth3',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'eth4',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'eth5',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
            ],
        },
    );

    ##########################
    #### Perform the test ####
    ##########################

    lives_ok {
        my $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);

        # The selected host must be the 1st.
        if ($selected_host->id != $host1->id) {
            die ("Test 3.d : Wrong host selected");
        }
    } "Test 3.d : Choosing the host with the best bonding configuration cost";
}

1;
