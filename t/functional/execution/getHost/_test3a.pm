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
                    core => 1,
                    ram  => 1024*1024*1024,
                    tags => [],
                },
            },
        }
    };
    # Create Cluster and add network interface to it
    my $cluster = Kanopya::Test::Create->createCluster(
        cluster_conf => $host_manager_conf,
    );

    Kanopya::Test::Execution->executeAll();

    for my $interface ($cluster->interfaces) {
        $interface->delete();
    }

    my $network_manager_params = {
        interfaces => {
            interface1 => {
                netconfs       => {$netConf->netconf_name => $netConf },
                bonds_number   => 0,
                interface_name => "eth0",
            },
        }
    };
    $cluster->configureInterfaces(%{ $network_manager_params });

    ######################
    #### Create Hosts ####
    ######################

    # Create Host 1
    my $host1 = Kanopya::Test::Register->registerHost(
        board => {
            serial_number => 1,
            core          => 1,
            ram           => 2048*1024*1024,
            ifaces        => [
                {
                    name => 'eth0',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 2
    my $host2 = Kanopya::Test::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 1,
            ram           => 8192*1024*1024,
            ifaces        => [
                {
                    name => 'eth0',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 3
    my $host3 = Kanopya::Test::Register->registerHost(
        board => {
            serial_number => 3,
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
    # Create Host 4
    my $host4 = Kanopya::Test::Register->registerHost(
        board => {
            serial_number => 4,
            core          => 1,
            ram           => 1536*1024*1024,
            ifaces        => [
                {
                    name => 'eth0',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 5
    my $host5 = Kanopya::Test::Register->registerHost(
        board => {
            serial_number => 5,
            core          => 1,
            ram           => 1024*1024*1024,
            ifaces        => [
                {
                    name => 'eth0',
                    pxe  => 0,
                },
            ],
        },
    );
    # Create Host 6
    my $host6 = Kanopya::Test::Register->registerHost(
        board => {
            serial_number => 6,
            core          => 1,
            ram           => 3072*1024*1024,
            ifaces        => [
                {
                    name => 'eth0',
                    pxe  => 0,
                },
            ],
        },
    );

    ##########################
    #### Perform the test ####
    ##########################

    lives_ok {
        my $selected_host = DecisionMaker::HostSelector->getHost(
                                host_manager => Entity::Component::Physicalhoster0->find(),
                                %{ $network_manager_params },
                                %{ $host_manager_conf->{managers}->{host_manager}->{manager_params} },
                            );

        # The selected host must be the 5th.
        if ($selected_host->id != $host5->id) {
            die ("Test 3.a : Wrong host selected");
        }
    } "Test 3.a : Choosing the host with the best RAM cost";
}

1;
