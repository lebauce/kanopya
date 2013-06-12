#   TEST 1.A :
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
#       |_______________________________|_______________________________|_______________________________|
#
#       CONSTRAINTS (Cluster) :
#
#       /---------------------------------\
#       /                                 \
#       /   Min CPU Core number = 1       \
#       /   Min RAM quantity    = 8192    \
#       /   Interfaces :                  \
#       /       interface 1 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /                                 \
#       /---------------------------------\
#
sub test1a {
    ########################
    #### Create Cluster ####
    ########################

    # Create NetConf
    my $netConf =  Entity::Netconf->create(
        netconf_name => 'just another lonely netconf',
    );
    # Host Manager config
    my $host_manager_conf = {
        managers              => {
            host_manager => {
                manager_params => {
                    core => 1,
                    ram  => 8192*1024*1024,
                    tags => [],
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
                    name => 'such a lonely iface',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 2
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 4,
            ram           => 8192*1024*1024,
            ifaces        => [
                {
                    name => 'Une iface qui a du SWAG',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 3
    my $host3 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface yourself !',
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

        # The selected host must be the 2nd.
        if ($selected_host->id != $host2->id) {
            die ("Test 1.a : Wrong host selected");
        }
    } "Test 1.a : Only one host match the RAM constraint";
}

1;
