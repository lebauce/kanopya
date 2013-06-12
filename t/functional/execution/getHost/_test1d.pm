#   TEST 1.D :
#
#     HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 2       |     CPU Core number = 4       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 8192    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 2  |             Bonds number = 2  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |         iface 2 :             |                               |         iface 2 :             |
#       |             Bonds number = 0  |                               |             Bonds number = 0  |
#       |             NetIps       = [] |                               |             NetIps       = [] |
#       |         iface 3 :             |                               |                               |
#       |             Bonds number = 1  |                               |                               |
#       |             NetIps       = [] |                               |                               |
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
#       /       interface 2 :             \
#       /           Min Bonds number = 2  \
#       /           Min NetIps       = [] \
#       /                                 \
#       /---------------------------------\
#
sub test1d {
    ########################
    #### Create Cluster ####
    ########################
    
    # Create NetConf
    my $netConf =  Entity::Netconf->create(
        netconf_name => 'Being a netconf is exhausting',
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
            interface2 => {
                netconfs       => {$netConf->netconf_name => $netConf },
                bonds_number   => 2,
                interface_name => interface2,
            },
        }
    );

    ######################
    #### Create Hosts ####
    ######################

    # Create Host 1
    my $master_iface_name1 = 'I am the King';
    my $host1 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 1,
            core          => 1,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'I would like to be a King iface',
                    pxe  => 0,
                },
                {
                    name => 'Me too but I have no slaves',
                    pxe  => 0,
                },
                {
                    name => $master_iface_name1,
                    pxe  => 0,
                },
                    {
                        name   => 'I am a slave iface and its not funny',
                        pxe    => 0,
                        master => $master_iface_name1,
                    },
            ],
        },
    );
    # Create Host 2
    my $master_iface_name2 = 'Come on slaves !';
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 2,
            ram           => 8192*1024*1024,
            ifaces        => [
                {
                    name => $master_iface_name2,
                    pxe  => 0,
                },
                    {
                        name   => 'Alright master',
                        pxe    => 0,
                        master => $master_iface_name2,
                    },
                    {
                        name   => 'Cannot say no cause I am a slave...',
                        pxe    => 0,
                        master => $master_iface_name2,
                    },
            ],
        },
    );
    # Create Host 3
    my $master_iface_name3 = 'King in the north';
    my $host3 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 4,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => $master_iface_name3,
                    pxe  => 0,
                },
                    {
                        name   => 'Winter is coming...',
                        pxe    => 0,
                        master => $master_iface_name3,
                    },
                    {
                        name   => 'But the Nights Watch is there',
                        pxe    => 0,
                        master => $master_iface_name3,
                    },
                {
                    name => '...',
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
            die ("Test 1.d : Wrong host selected");
        }
    } "Test 1.d : Only one host match the bonds number constraint";
}

1;
