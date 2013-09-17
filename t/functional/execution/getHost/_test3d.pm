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
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface1',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 2
    my $master_iface_name2 = 'master_iface2';
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
                        name   => 'slave_iface21',
                        pxe    => 0,
                        master => $master_iface_name2,
                    },
                    {
                        name   => 'slave_iface22',
                        pxe    => 0,
                        master => $master_iface_name2,
                    },
            ],
        },
    );
    # Create Host 3
    my $master_iface_name3 = 'master_iface3';
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
                        name   => 'slave_iface31',
                        pxe    => 0,
                        master => $master_iface_name3,
                    },
            ],
        },
    );
    # Create Host 4
    my $master_iface_name4 = 'master_iface4';
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
                        name   => 'slave_iface41',
                        pxe    => 0,
                        master => $master_iface_name4,
                    },
                    {
                        name   => 'slave_iface42',
                        pxe    => 0,
                        master => $master_iface_name4,
                    },
                    {
                        name   => 'slave_iface43',
                        pxe    => 0,
                        master => $master_iface_name4,
                    },
            ],
        },
    );
    # Create Host 5
    my $master_iface_name5 = 'master_iface5';
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
                        name   => 'slave_iface51',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
                    {
                        name   => 'slave_iface52',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
                    {
                        name   => 'slave_iface53',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
                    {
                        name   => 'slave_iface54',
                        pxe    => 0,
                        master => $master_iface_name5,
                    },
            ],
        },
    );
    # Create Host 6
    my $master_iface_name6 = 'master_iface6';
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
                        name   => 'slave_iface61',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'slave_iface62',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'slave_iface63',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'slave_iface64',
                        pxe    => 0,
                        master => $master_iface_name6,
                    },
                    {
                        name   => 'slave_iface65',
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
