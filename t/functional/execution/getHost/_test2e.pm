#   TEST 2.E :
#
#     HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 2       |     CPU Core number = 4       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 8192    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |           Bonds number = 0    |             Bonds number = 0  |
#       |             NetIps = [1]      |           NetIps = [1,2,3]    |             NetIps = [1,2]    |
#       |         iface 2 :             |                               |         iface 2 :             |
#       |             Bonds number = 0  |                               |             Bonds number = 0  |
#       |             NetIps = [2]      |                               |             NetIps = [3,1]    |
#       |         iface 3 :             |                               |                               |
#       |             Bonds number = 0  |                               |                               |
#       |             NetIps = [3]      |                               |                               |
#       |_______________________________|_______________________________|_______________________________|
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 4 -                      | Host 5 -                      | Host 6 -                      |
#       |     CPU Core number = 1       |     CPU Core number = 2       |     CPU Core number = 4       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 8192    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps = [1,3]    |             NetIps = [1,2,3]  |             NetIps = [1]      |
#       |         iface 2 :             |         iface 2 :             |         iface 2 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps = [3,2]    |             NetIps = [2,3]    |             NetIps = [1]      |
#       |         iface 3 :             |         iface 3 :             |         iface 2 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps = [2,3]    |             NetIps = [1,2]    |             NetIps = [2]      |
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
#       /           Min NetIps = [1,2]    \
#       /       interface 2 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps = [2,1,3]  \
#       /       interface 3 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps = [3,1]    \
#       /                                 \
#       /---------------------------------\
#
sub test2e {
    #####################################
    #### Create Networks and Poolips ####
    #####################################

    # Create Networks
    my $network1 = Entity::Network->new(
        network_name    => '0.0.0.0',
        network_addr    => '0.0.0.0',
        network_netmask => '0.0.0.0',
        network_gateway => '0.0.0.0',
    );
    my $network2 = Entity::Network->new(
        network_name    => '1.1.1.1',
        network_addr    => '1.1.1.1',
        network_netmask => '1.1.1.1',
        network_gateway => '1.1.1.1',
    );
    my $network3 = Entity::Network->new(
        network_name    => '2.2.2.2',
        network_addr    => '2.2.2.2',
        network_netmask => '2.2.2.2',
        network_gateway => '2.2.2.2',
    );

    # Create Poolips
    my $poolip1 = Entity::Poolip->new(
        poolip_name       => "poolip1",
        poolip_size       => 1,
        poolip_first_addr => '1.1.1.1',
        network_id        => $network1->id,
    );
    my $poolip2 = Entity::Poolip->new(
        poolip_name       => "poolip2",
        poolip_size       => 1,
        poolip_first_addr => '2.2.2.2',
        network_id        => $network2->id,
    );
    my $poolip3 = Entity::Poolip->new(
        poolip_name       => "poolip3",
        poolip_size       => 1,
        poolip_first_addr => '3.3.3.3',
        network_id        => $network3->id,
    );

    ########################
    #### Create Cluster ####
    ########################

    # Create NetConfs
    my $netConf1 =  Entity::Netconf->create(
        netconf_name    => 'n1',
        netconf_poolips => [$poolip1, $poolip2],
    );
    my $netConf2 =  Entity::Netconf->create(
        netconf_name    => 'n2',
        netconf_poolips => [$poolip2, $poolip1, $poolip3],
    );
    my $netConf3 =  Entity::Netconf->create(
        netconf_name    => 'n3',
        netconf_poolips => [$poolip3, $poolip1],
    );
    # Host Manager config
    my $host_manager_conf = {
        managers              => {
            host_manager => {
                manager_params => {
                    core => 1,
                    ram  => 4096*1024*1024,
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
                interface_netconfs => {$netConf1->netconf_name => $netConf1 },
                bonds_number        => 0,
            },
            interface2 => {
                interface_netconfs => {$netConf2->netconf_name => $netConf2 },
                bonds_number        => 0,
            },
            interface3 => {
                interface_netconfs => {$netConf3->netconf_name => $netConf3 },
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
            ram           => 4096*1024*1024,
        },
    );
    # Create ifaces of host 1
    my $iface11 = $host1->addIface(
        iface_name => "iface11",
        iface_pxe  => 0,
    );
    my $iface12 = $host1->addIface(
        iface_name => "iface12",
        iface_pxe  => 0,
    );
    my $iface13 = $host1->addIface(
        iface_name => "iface13",
        iface_pxe  => 0,
    );
    # Attach corresponding ips to ifaces
    $iface11->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf11',
                    netconf_poolips => [$poolip1],
                )
            ]
        }
    );
    $iface12->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf12',
                    netconf_poolips => [$poolip2],
                )
            ]
        }
    );
    $iface13->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf13',
                    netconf_poolips => [$poolip3],
                )
            ]
        }
    );

    # Create Host 2
    my $host2 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 2,
            ram           => 8192*1024*1024,
        },
    );
    # Create ifaces of host 2
    my $iface21 = $host2->addIface(
        iface_name => "iface21",
        iface_pxe  => 0,
    );
    # Attach corresponding ips to ifaces
    $iface21->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf21',
                    netconf_poolips => [$poolip1, $poolip2, $poolip3],
                )
            ]
        }
    );

    # Create Host 3
    my $host3 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 4,
            ram           => 4096*1024*1024,
        },
    );
    # Create ifaces of host 3
    my $iface31 = $host3->addIface(
        iface_name => "iface31",
        iface_pxe  => 0,
    );
    my $iface32 = $host3->addIface(
        iface_name => "iface32",
        iface_pxe  => 0,
    );
    # Attach corresponding ips to ifaces
    $iface31->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf31',
                    netconf_poolips => [$poolip1, $poolip2],
                )
            ]
        }
    );
    $iface32->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf32',
                    netconf_poolips => [$poolip3, $poolip1],
                )
            ]
        }
    );

    # Create Host 4
    my $host4 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 4,
            core          => 1,
            ram           => 4096*1024*1024,
        },
    );
    # Create ifaces of host 4
    my $iface41 = $host4->addIface(
        iface_name => "iface41",
        iface_pxe  => 0,
    );
    my $iface42 = $host4->addIface(
        iface_name => "iface42",
        iface_pxe  => 0,
    );
    my $iface43 = $host4->addIface(
        iface_name => "iface43",
        iface_pxe  => 0,
    );
    # Attach corresponding ips to ifaces
    $iface41->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf41',
                    netconf_poolips => [$poolip1, $poolip3],
                )
            ]
        }
    );
    $iface42->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf42',
                    netconf_poolips => [$poolip3, $poolip2],
                )
            ]
        }
    );
    $iface43->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf43',
                    netconf_poolips => [$poolip2, $poolip3],
                )
            ]
        }
    );

    # Create Host 5
    my $host5 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 5,
            core          => 2,
            ram           => 8192*1024*1024,
        },
    );
    # Create ifaces of host 5
    my $iface51 = $host5->addIface(
        iface_name => "iface51",
        iface_pxe  => 0,
    );
    my $iface52 = $host5->addIface(
        iface_name => "iface52",
        iface_pxe  => 0,
    );
    my $iface53 = $host5->addIface(
        iface_name => "iface53",
        iface_pxe  => 0,
    );
    # Attach corresponding ips to ifaces
    $iface51->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf51',
                    netconf_poolips => [$poolip1, $poolip2, $poolip3],
                )
            ]
        }
    );
    $iface52->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf52',
                    netconf_poolips => [$poolip2, $poolip3],
                )
            ]
        }
    );
    $iface53->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf53',
                    netconf_poolips => [$poolip1, $poolip2],
                )
            ]
        }
    );

    # Create Host 6
    my $host6 = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 6,
            core          => 4,
            ram           => 4096*1024*1024,
        },
    );
    # Create ifaces of host 6
    my $iface61 = $host6->addIface(
        iface_name => "iface61",
        iface_pxe  => 0,
    );
    my $iface62 = $host6->addIface(
        iface_name => "iface62",
        iface_pxe  => 0,
    );
    my $iface63 = $host6->addIface(
        iface_name => "iface63",
        iface_pxe  => 0,
    );
    # Attach corresponding ips to ifaces
    $iface61->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf61',
                    netconf_poolips => [$poolip1],
                )
            ]
        }
    );
    $iface62->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf62',
                    netconf_poolips => [$poolip1],
                )
            ]
        }
    );
    $iface63->populateRelations(
        relations => {
            netconf_ifaces => [
                Entity::Netconf->create(
                    netconf_name    => 'netConf63',
                    netconf_poolips => [$poolip2],
                )
            ]
        }
    );

    ##########################
    #### Perform the test ####
    ##########################

    throws_ok {
        my $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);
    } 'Kanopya::Exception',
      'Test 2.e : None of the hosts match the minimum network configuration constraint';
}

1;