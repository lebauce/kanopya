#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;

use Kanopya::Exceptions;
use EContext::Local;
use ERollback;

use Data::Dumper;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => '/tmp/getFreeHost.t.log',
    layout => '%F %L %p %m%n'
});

my $testing = 0;
my $kanopya_cluster;
my $physical_hoster;
my $kernel;

eval {

    use_ok ('Entity::Interface');
    use_ok ('Entity::User');
    use_ok ('Entity::Netconf');
    use_ok ('Entity::NetconfRole');
    use_ok ('Entity::Host');
    use_ok ('Entity::Masterimage');
    use_ok ('Entity::ServiceTemplate');
    use_ok ('Entity::Iface');
    use_ok ('NetconfInterface');
    use_ok ('EEntity');
    use_ok ('Executor');
    use_ok ('Administrator');
    use_ok ('Entity::ServiceProvider::Inside::Cluster');

    lives_ok {
        Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    } 'Connect to database';

    my $adm = Administrator->new;

    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

     if ($testing) {
           $adm->beginTransaction;
     }

    lives_ok {
        $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                               hash => { cluster_name => 'kanopya' });
        $physical_hoster = $kanopya_cluster->getHostManager();
    } 'Retrieve Kanopya cluster';

    lives_ok {
        $kernel = Entity::Kernel->find(hash => {});
    } 'Get first kernel found';

    my ($sp,@interfaces,@ifaces,$host_manager,$ehost_manager,$host_manager_params,$host);


    @interfaces = ({name => 'c_one', bond_nb => 0}, {name =>'b_one', bond_nb => 1});
    @ifaces     = ({bond_nb => 0, name => 'eth0'}, {bond_nb => 1, name => 'bond0', slaves => 1});
    diag('-= Create cluster with 1 common interface and one bonded interface (1) =-');
    $sp = _createCluster(interfaces => \@interfaces, executor => $executor, name => 'bonding1');
    diag('-= Create host with 1 common interface and one bonded interface (1) =-');
    _createHost(ifaces => \@ifaces, executor => $executor);

    $host_manager  = $sp->getHostManager();
    $ehost_manager = EEntity->new(entity => $host_manager);
    $host_manager_params = $sp->getManagerParameters(manager_type => 'host_manager');
    $host_manager_params->{interfaces} = $sp->interfaces;

    lives_ok { 
        $host = $ehost_manager->getFreeHost(%$host_manager_params);
    } 'Successfully get free host';

    


};
if($@) {
    my $error = $@; 
    print $error."\n";
};


sub _createCluster {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'interfaces', 'executor' ]);

    my $executor = $args{executor};

    my $admin_role = Entity::NetconfRole->find(hash => { netconf_role_name => 'admin'})->id;

    my $disk_manager;
    lives_ok {
        $disk_manager =  EEntity->new(entity => $kanopya_cluster->getComponent(name    => 'Lvm',
                                                                               version => 2));
    } 'Get kanopya cluster\'s disk manager';

    my $masterimage;
    eval {
        $masterimage = Entity::Masterimage->find(hash => {
                           masterimage_name => { like => "%squeeze%" }
                       });
    };
    if ($@) {
    	lives_ok {
          Entity::Masterimage->new(
                masterimage_name => 'squeeze',
                masterimage_file => '/vagrant/squeeze-amd64-xenvm.tar.bz2',
                masterimage_desc => '',
                masterimage_os   => 'tortue',
                masterimage_size => '666',
        	);
    	} 'Deploy master image';

        lives_ok { $executor->oneRun; } 'Deploy masterimage operation execution succeed';
        lives_ok { $executor->oneRun; } 'Deploy masterimage operation execution succeed';

        $masterimage = Entity::Masterimage->find(hash => {
                           masterimage_name => { like => "%squeeze%" }
                       });
	}

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Get admin user';

    my $cluster_name = $args{name};
    lives_ok {
        Entity::ServiceProvider::Inside::Cluster->create(
            active                 => 1,
            cluster_name           => $cluster_name,
            cluster_min_node       => "1",
            cluster_max_node       => "30",
            cluster_priority       => "100",
            cluster_si_shared      => 0,
            cluster_si_persistent  => 1,
            cluster_domainname     => 'my.domain',
            cluster_basehostname   => 'vm',
            cluster_nameserver1    => '192.168.0.31',
            cluster_nameserver2    => '127.0.0.1',
            cluster_boot_policy    => 'PXE Boot via ISCSI',
            kernel_id              => $kernel->id,
            masterimage_id         => $masterimage->id,
            user_id                => $admin_user->id,
            managers               => {
                host_manager => {
                    manager_id     => $physical_hoster->id,
                    manager_type   => "host_manager",
                    manager_params => {
                        cpu      => 1,
                        ram      => 512,
                        ram_unit => 'M',
                    }
                },
                disk_manager => {
                    manager_id     => $disk_manager->id,
                    manager_type   => 'disk_manager',
                    manager_params => {
                        vg_id => 1,
                        systemimage_size => 4 * 1024 * 1024 * 1024,
                    },
                }
            },
        );
    } 'AddCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';
    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';

    my $b_cluster;
    lives_ok {
        $b_cluster = Entity::ServiceProvider::Inside::Cluster->find(hash => {
                         cluster_name => $cluster_name});
    } 'Get bonding cluster';

    lives_ok {
        my $adm_netconf = Entity::Netconf->find(hash => {netconf_name => 'Kanopya admin'}); 
        $adm_netconf->delete();

        my $interface = Entity::Interface->find(hash => {service_provider_id => $b_cluster->id});
        $interface->delete();
    } 'delete admin netconf, related netconf_interface, and automatically generated cluster interface';

    foreach my $interface (@{ $args{interfaces} }) {
        #we create a netconf for the interface
        my $name = 'netconf' . $interface->{name};  
        my $netconf = Entity::Netconf->create(netconf_name => $name , netconf_role_id => $admin_role);

        my %interface;

        $interface{interface_netconf} = $netconf;
        $interface{bonds_number}      = $interface->{bond_nb};

        #we attach the interface to the cluster
        $b_cluster->addNetworkInterface(netconfs     => [ $interface{interface_netconf} ],
                                        bonds_number => $interface{bonds_number});
    }

    return $b_cluster;
}

sub _createHost {
    my %args = @_;
   
    General::checkParams(args => \%args, required => [ 'ifaces', 'executor' ]);

    my $executor = $args{executor};

    my $host; 
    lives_ok {
        $host = Entity::Host->new(
                   active             => 1,
                   host_manager_id    => $physical_hoster->id,
                   kernel_id          => $kernel->id,
                   host_serial_number => "123",
                   host_ram           => 4 * 1024 * 1024,
                   host_core          => 2
                );
    } 'create new host';

    for my $iface (@{ $args{ifaces} }) {
        if ($iface->{bond_nb} == 0) {
            lives_ok {
                Entity::Iface->create(iface_name     => $iface->{name},
                                   iface_mac_addr => Entity::Iface->generateMacAddress(),
                                   iface_pxe      => 0,
                                   host_id        => $host->id,);
            } 'attach common iface to host';
        }
        elsif (defined $iface->{slaves} && $iface->{slaves} > 0) {
            my $Iface;
            lives_ok{
                $Iface = Entity::Iface->create(iface_name     => $iface->{name},
                                            iface_mac_addr => Entity::Iface->generateMacAddress(),
                                            iface_pxe      => 0,
                                            host_id        => $host->id,
                         );
            } 'attach bonding master iface';

            foreach my $slave (0..$args{slaves}) {
                lives_ok{
                    Entity::Iface->create(iface_name     => $iface->{name} . '_' . $slave,
                                       iface_mac_addr => Entity::Iface->generateMacAddress(),
                                       iface_pxe      => 0,
                                       host_id        => $host->id,
                                       master         => $Iface->id,);
                } 'attach bonding slave iface';
            }
        }
    }
}

1;
