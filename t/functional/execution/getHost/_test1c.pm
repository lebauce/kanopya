#   TEST 1.C :
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
#       |         iface 2 :             |                               |         iface 2 :             |
#       |             Bonds number = 0  |                               |             Bonds number = 0  |
#       |             NetIps       = [] |                               |             NetIps       = [] |
#       |         iface 3 :             |                               |                               |
#       |             Bonds number = 0  |                               |                               |
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
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /       interface 3 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /                                 \
#       /---------------------------------\
#
sub test1c {
    ########################
    #### Create Cluster ####
    ########################
    
    # Create NetConf
    my $netConf =  Entity::Netconf->create(
        netconf_name => 'Such a netconf',
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
                bonds_number   => 0,
                interface_name => interface2,
            },
            interface3 => {
                netconfs       => {$netConf->netconf_name => $netConf },
                bonds_number   => 0,
                interface_name => interface3,
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
                    name => 'I dont wanna be an iface',
                    pxe  => 0,
                },
                {
                    name => 'it sucks to be an iface',
                    pxe  => 0,
                },
                {
                    name => 'please hit me in the iface',
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
                    name => 'Power to the ifaces !',
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
                    name => 'Are you being sarcatIfacetic ?',
                    pxe  => 0,
                },
                {
                    name => 'Just when I see your ugly iface...',
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

        # The selected host must be the 1st.
        if ($selected_host->id != $host1->id) {
            die ("Test 1.c : Wrong host selected");
        }
    } "Test 1.c : Only one host match the Iface number constraint";
}

1;
