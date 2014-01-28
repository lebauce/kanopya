#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'openstack_lb.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;
use NetconfVlan;
use Entity::Vlan;
use Lvm2Vg;
use Lvm2Pv;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;
use Kanopya::Tools::TestUtils 'expectedException';

my $testing = 0;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Tools::Register::registerMasterImage('ubuntu-precise-amd64.tar.bz2');
    } 'Register master image';

    diag('Create and configure MySQL and RabbitMQ cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster(
                        cluster_conf => {
                            cluster_name         => 'openstack_lb',
                            cluster_basehostname => 'cloud',
                            masterimage_id       => $masterimage->id
                        },
                        components => {
                            'keepalived'     => {},
                            'haproxy'        => {},
                            'mysql'          => {},
                            'amqp'           => {},
                            'keystone'       => {},
                            'glance'         => {},
                            'neutron'        => {},
                            'novacompute'    => {},
                            'novacontroller' => {
                                overcommitment_cpu_factor    => 1,
                                overcommitment_memory_factor => 1
                            },
                        }
                    );
    } 'Create Openstack_lb cluster';

    my $keepalived = $cluster->getComponent(name => 'Keepalived');
    my $haproxy = $cluster->getComponent(name => 'Haproxy');
    my $mysql = $cluster->getComponent(name => 'Mysql');
    my $amqp = $cluster->getComponent(name => 'Amqp');
    my $keystone = $cluster->getComponent(name => 'Keystone');
    my $nova_controller = $cluster->getComponent(name => "NovaController");
    my $glance = $cluster->getComponent(name => "Glance");
    my $neutron = $cluster->getComponent(name => "Neutron");
    my $nova_compute = $cluster->getComponent(name => "NovaCompute");
    
    lives_ok {
        my @interfaces = $cluster->interfaces;
        my $interface = $interfaces[0];
        
        $keepalived->setConf(conf => {
            notification_email => 'toto@toto.fr',
            smtp_server        => '127.0.0.1',
            keepalived1_vrrpinstances => [
                { vrrpinstance_name      => 'myvirtualip', 
                  vrrpinstance_password  => 'pass',
                  interface_id           => $interface->id,
                  virtualip_interface_id => $interface->id
                },
            ]
        });
    } 'Configure keepalived';
    
    my @vrrp_instances = $keepalived->keepalived1_vrrpinstances;
    my $vip = $vrrp_instances[0]->virtualip;
    diag("keepalived virtual ip is ".$vip->ip_addr);
    
    lives_ok {
        $haproxy->setConf(conf => {
            haproxy1s_listen => [ 
                                  { listen_name    => 'mysql',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 3306,
                                    listen_mode    => 'tcp',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $mysql->id,
                                    listen_component_port => 3306
                                  },
                                  { listen_name    => 'keystone-1',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 5000,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $keystone->id,
                                    listen_component_port => 5000
                                  },
                                  { listen_name    => 'keystone-2',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 35357,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $keystone->id,
                                    listen_component_port => 35357 
                                  },
                                  { listen_name    => 'nova-api-1',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 8773,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $nova_controller->id,
                                    listen_component_port => 8773 
                                  },
                                  { listen_name    => 'nova-api-2',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 8774,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $nova_controller->id,
                                    listen_component_port => 8774 
                                  },
                                  { listen_name    => 'nova-api-3',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 8775,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $nova_controller->id,
                                    listen_component_port => 8775 
                                  },
                                  { listen_name    => 'nova-api-4',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 8776,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $nova_controller->id,
                                    listen_component_port => 8776 
                                  },
                                  { listen_name    => 'glance-api',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 9292,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $glance->id,
                                    listen_component_port => 9292 
                                  },
                                  { listen_name    => 'neutron-api',
                                    listen_ip      => $vip->ip_addr,
                                    listen_port    => 9696,
                                    listen_mode    => 'http',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $neutron->id,
                                    listen_component_port => 9696 
                                  },
                                ]
        });
    } 'Configure haproxy';
    

    $keystone->setConf(conf => {
        mysql5_id   => $mysql->id,
    });

    $nova_controller->setConf(conf => {
        mysql5_id   => $mysql->id,
        keystone_id => $keystone->id,
        amqp_id     => $amqp->id
    });

    $glance->setConf(conf => {
        mysql5_id          => $mysql->id,
        nova_controller_id => $nova_controller->id
    });

    $neutron->setConf(conf => {
        mysql5_id          => $mysql->id,
        nova_controller_id => $nova_controller->id
    });

    $nova_compute->setConf(conf => {
        nova_controller_id => $nova_controller->id,
        iaas_id            => $nova_controller->id,
        mysql5_id          => $mysql->id
    });
}
