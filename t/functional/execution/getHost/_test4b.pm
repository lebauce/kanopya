#   TEST 4.a :
#
#       HOSTS :
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 1 -                      | Host 2 -                      | Host 3 -                      |
#       |     CPU Core number = 2       |     CPU Core number = 2       |     CPU Core number = 2       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 4096    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |     Tags : [1,2,3]            |     Tags : [1,2,4]            |     Tags : [1,5]              |
#       |_______________________________|_______________________________|_______________________________|
#        _______________________________________________________________________________________________
#       |                               |                               |                               |
#       | Host 4 -                      | Host 5 -                      | Host 6 -                      |
#       |     CPU Core number = 2       |     CPU Core number = 2       |     CPU Core number = 2       |
#       |     RAM quantity    = 4096    |     RAM quantity    = 4096    |     RAM quantity    = 4096    |
#       |     Ifaces :                  |     Ifaces :                  |     Ifaces :                  |
#       |         iface 1 :             |         iface 1 :             |         iface 1 :             |
#       |             Bonds number = 0  |             Bonds number = 0  |             Bonds number = 0  |
#       |             NetIps       = [] |             NetIps       = [] |             NetIps       = [] |
#       |     Tags : [1,6]              |     Tags : [1]                |     Tags : [1,2,7]            |
#       |_______________________________|_______________________________|_______________________________|
#
#       CONSTRAINTS (Cluster) :
#
#       /---------------------------------\
#       /                                 \
#       /   Min CPU Core number = 1       \
#       /   Min RAM quantity    = 512     \
#       /   Interfaces :                  \
#       /       interface 1 :             \
#       /           Min Bonds number = 0  \
#       /           Min NetIps       = [] \
#       /   Min Tags : [1,2]              \
#       /   No  Tags : [3,4]              \
#       /---------------------------------\
#

use Entity::Tag;
use Kanopya::Tools::TestUtils 'expectedException';
#use strict;
#use warnings;

sub test4b {
    ########################
    #### Create Tags    ####
    ########################

    my @tags= ();
    for my $i (0..6) {
        push @tags, Entity::Tag->findOrCreate(tag => "test_4b_".$i);
    }

    ########################
    #### Create Cluster ####
    ########################

    # Create NetConf
    my $netConf =  Entity::Netconf->findOrCreate(netconf_name => 'netconf');

    # Host Manager config
    my $host_manager_conf = {
        managers => {
            host_manager => {
                manager_params => {
                    core => 1,
                    ram  => 512*1024*1024,
                    tags => [$tags[0]->id, $tags[1]->id],
                    no_tags => [$tags[2]->id, $tags[3]->id],
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
                interface_name => interface1,
            },
        }
    );

    ######################
    #### Create Hosts ####
    ######################

    my @hosts = ();
    my $host;
    # Create Host 1
    $host = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 1,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host->_populateRelations(
        relations => {
            entity_tags => [$tags[0], $tags[1], $tags[2]],
        }
    );
    push @hosts, $host;

    # Create Host 2
    $host = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 2,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host->_populateRelations(
        relations => {
            entity_tags => [$tags[0], $tags[1], $tags[3]],
        }
    );
    push @hosts, $host;

    # Create Host 3
    $host = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 3,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host->_populateRelations(
        relations => {
            entity_tags => [$tags[0], $tags[4]],
        }
    );
    push @hosts, $host;

    # Create Host 4
    $host = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 6,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host->_populateRelations(
        relations => {
            entity_tags => [$tags[0], $tags[5]],
        }
    );
    push @hosts, $host;

    # Create Host 5
    $host = Kanopya::Tools::Register->registerHost(
        board => {
            serial_number => 5,
            core          => 2,
            ram           => 4096*1024*1024,
            ifaces        => [
                {
                    name => 'iface',
                    pxe  => 0,
                },
            ],
        },
    );
    $host->_populateRelations(
        relations => {
            entity_tags => [$tags[0]],
        }
    );
    push @hosts, $host;


    #########################################
    #### Perform the test without host 6 ####
    #########################################

    lives_ok {

        expectedException {
            my $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);
        } 'Kanopya::Exception', 'Test 4.b : Wrong host selected expected no host';

        # Create Host 6
        $host = Kanopya::Tools::Register->registerHost(
            board => {
                serial_number => 4,
                core          => 2,
                ram           => 4096*1024*1024,
                ifaces        => [
                    {
                        name => 'iface',
                        pxe  => 0,
                    },
                ],
            },
        );
        $host->_populateRelations(
            relations => {
                entity_tags => [$tags[0], $tags[1], $tags[6]],
            }
        );
        push @hosts, $host;


        $selected_host = DecisionMaker::HostSelector->getHost(cluster => $cluster);
        # The selected host must be the last one.
        if ($selected_host->id != $hosts[-1]->id) {
            die ('Test 4.b : Wrong host <'.($selected_host->id).'> selected, expected <'.($hosts[3]->id).'>');
        }

    } "Test 4.b : Choosing the host with no tags";

    for my $host (@hosts) {
        $host->delete();
    }

    $cluster->delete();

    for my $tag (@tags) {
        $tag->delete();
    }

}

1;
