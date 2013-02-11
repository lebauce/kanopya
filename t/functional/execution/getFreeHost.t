#!/usr/bin/perl

# The following cases should be tested:
#
# I. iface number constraint:
# Cluster configurations:
#__________________________________________
#SIMPLE IFACES| BONDED IFACES | BOND NUMBER|
#_____________|_______________|____________|
#     1       |       0       |     0      |
#_____________|_______________|____________|
#     1       |       1       |     1      |
#_____________|_______________|____________|
#     1       |       1       |     2      |
#_____________|_______________|____________|
#     1       |       2       |     1      |
#_____________|_______________|____________|
#     1       |       2       |     2      |
#_____________|_______________|____________|
#     2       |       1       |     1      |
#_____________|_______________|____________|
#     2       |       0       |     0      |
#_____________|_______________|____________|
#     2       |       1       |     2      |
#_____________|_______________|____________|
#     2       |       2       |     2      |
#_____________|_______________|____________|
#     2       |       2       |     1      |
#_____________|_______________|____________|
#
# All those combinations should be tested with the following host configuration
#
# Host configuration:
# -> Good number of simple and bonbs number
# -> without any ifaces
# -> without simple ifaces
# -> without bonded ifaces
# -> with an insufficiant number of simple ifaces
# -> with an insufficiant number of bonded ifaces
# -> with an insufficiant number of bonds slaves
#
# II. Netconf constraints:
#
# "If an iface of the host is configured, we consider that the whole host is configured,
# and thus that all the configured cluster interfaces must have a sibling among the host
# ifaces"
#
#
#


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
    file   => 'getFreeHost.t.log',
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
    use_ok ('NetconfIface');
    use_ok ('EEntity');
    use_ok ('Executor');
    use_ok ('Entity::ServiceProvider::Cluster');

#    lives_ok {
#        BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );
#    } 'Connect to database';

    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

     if ($testing) {
           BaseDB->beginTransaction;
     }

    lives_ok {
        $kanopya_cluster = Entity::ServiceProvider::Cluster->find(
                               hash => { cluster_name => 'Kanopya' });
        $physical_hoster = $kanopya_cluster->getHostManager();
    } 'Retrieve Kanopya cluster';

    lives_ok {
        $kernel = Entity::Kernel->find(hash => {});
    } 'Get first kernel found';

    my ($sp,$c_host,$d_host,@interfaces,@ifaces,$host_manager,$host_manager_params,$host,@c_interfaces,@if,$netconf,@c_netconfs);

    diag('-= Create cluster with 2 common interface =-');
    @interfaces = ({name => 'c_one', bond_nb => 0}, {name =>'c_two', bond_nb => 0});
    $sp = _createCluster(interfaces => \@interfaces, executor => $executor, name => 'bonding00', hn =>'t');

    diag('-= Create host with 2 common ifaces =-');
    @ifaces = ({bond_nb => 0, name => 'eth0'}, {bond_nb => 0, name => 'eth1'});
    $c_host = _createHost(ifaces => \@ifaces, executor => $executor);

    diag('-= Create host with 1 common ifaces =-');
    @ifaces = ({bond_nb => 0, name => 'eth0'});
    $d_host = _createHost(ifaces => \@ifaces, executor => $executor);

    $host_manager = _getHostManagerParams(sp => $sp);

    lives_ok {
        $host = $host_manager->{ehost_manager}->getFreeHost(%{ $host_manager->{params} });
    } 'Successfully get free host';

    $c_host->delete();
    $d_host->delete();
    $sp->delete();

    diag('-= Create cluster with 2 common interface =-');
    @interfaces = ({name => 'c_oone', bond_nb => 0}, {name =>'c_twoo', bond_nb => 0});
    $sp = _createCluster(interfaces => \@interfaces, executor => $executor, name => 'bonding0', hn =>'a');

    diag('-= Create host with 2 common ifaces =-');
    @ifaces = ({bond_nb => 0, name => 'eth0'}, {bond_nb => 0, name => 'eth1'});
    $c_host = _createHost(ifaces => \@ifaces, executor => $executor);

    $host_manager = _getHostManagerParams(sp => $sp);

    lives_ok {
        $host = $host_manager->{ehost_manager}->getFreeHost(%{ $host_manager->{params} });
    } 'Successfully get free host';

    $c_host->delete();
    $sp->delete();

    diag('-= Create cluster with 1 common interface and one bonded interface (1) =-');
    @interfaces = ({name => 'c_onee', bond_nb => 0}, {name =>'b_one', bond_nb => 1});
    $sp = _createCluster(interfaces => \@interfaces, executor => $executor, name => 'bonding1', hn =>'a');

    diag('-= Create host with 1 common interface and one bonded interface (1) =-');
    @ifaces = ({bond_nb => 0, name => 'eth0'}, {bond_nb => 1, name => 'bond0', slaves => 1});
    $c_host = _createHost(ifaces => \@ifaces, executor => $executor);

    $host_manager = _getHostManagerParams(sp => $sp);

    lives_ok {
        $host = $host_manager->{ehost_manager}->getFreeHost(%{ $host_manager->{params} });
    } 'Successfully get free host';

    $c_host->delete();
    $sp->delete();

    diag('-= Create cluster with 1 common interface and one bonded interface (1) =-');
    @interfaces = ({name => 'c_twwwo', bond_nb => 0}, {name =>'b_two', bond_nb => 1});
    $sp = _createCluster(interfaces => \@interfaces, executor => $executor, name => 'bonding2', hn => 'b');

    diag('-= Create host without any iface =-');
    @ifaces = ();
    $c_host = _createHost(ifaces => \@ifaces, executor => $executor);

    $host_manager = _getHostManagerParams(sp => $sp);

    dies_ok {
        $host = $host_manager->{ehost_manager}->getFreeHost(%{ $host_manager->{params} });
    } 'Successfully dies on get free host!';

    $c_host->delete();
    $sp->delete();

    ################################NETCONF TESTING####################################
    diag('-= Create cluster with 1 common interface (1 netconf) =-');
    @interfaces = ({name => 'n_one', bond_nb => 0});
    $sp = _createCluster(interfaces => \@interfaces, executor => $executor, name => 'netconf0', hn => 'c');

    diag('-= Create host with 2 common iface and associate only 1 to the same netconf =-');
    @ifaces = ({bond_nb => 0, name => 'eth0'}, {bond_nb => 0, name => 'eth1'});
    $c_host = _createHost(ifaces => \@ifaces, executor => $executor);

    #set the first iface with the netconfs of the first interface
    @c_interfaces  = $sp->interfaces;
    @c_netconfs = $c_interfaces[0]->netconfs;
    @if = $c_host->ifaces;
    my @tmp;
    push @tmp, $if[0];
    _associateNetconfIface(ifaces => \@tmp, netconfs => \@c_netconfs);
    $netconf = _createDummyNetconf(name => 'dummy00', role => 'admin');
    my (@tmp, @ntmp);
    push @tmp, $if[1];
    push @ntmp, $netconf;
    _associateNetconfIface(ifaces => \@tmp, netconfs => \@ntmp);

    $host_manager = _getHostManagerParams(sp => $sp);

    lives_ok {
        $host = $host_manager->{ehost_manager}->getFreeHost(%{ $host_manager->{params} });
    } 'Successfully get free host';

    $c_host->delete();
    $sp->delete();

    diag('-= Create cluster with 1 common interface =-');
    @interfaces = ({name => 'n_two', bond_nb => 0});
    $sp = _createCluster(interfaces => \@interfaces, executor => $executor, name => 'netconf1', hn => 'd');

    diag('-= Create host with one common iface associated to a different netconf =-');
    @ifaces = ({bond_nb => 0, name => 'eth0'});
    $c_host = _createHost(ifaces => \@ifaces, executor => $executor);

    #set the iface with a dummy netconf
    $netconf = _createDummyNetconf(name => 'dummy0', role => 'admin');
    @if = $c_host->ifaces;
    my @tmp;
    push @tmp, $if[0];
    my @confs;
    push @confs, $netconf;
    _associateNetconfIface(ifaces => \@tmp, netconfs => \@confs);

    $host_manager = _getHostManagerParams(sp => $sp);

    dies_ok {
        $host = $host_manager->{ehost_manager}->getFreeHost(%{ $host_manager->{params} });
    } 'Successfully dies on get free host';

    $c_host->delete();
    $sp->delete();
};
if($@) {
    my $error = $@;
    print $error."\n";
};

sub _associateNetconfIface {
    my %args = @_;

    General::checkParams(args => \%args, required => ['ifaces', 'netconfs']);

    my $ifaces   = $args{ifaces};
    my $netconfs = $args{netconfs};

    foreach my $iface (@$ifaces) {
        $iface->populateRelations(relations => { netconf_ifaces => $netconfs });
    }
}

sub _associateNetconfInterface {
    my %args = @_;

    General::checkParams(args => \%args, required => ['interfaces', 'netconfs']);

    my $interfaces = $args{interfaces};
    my $netconfs   = $args{netconfs};

    foreach my $interface (@$interfaces) {
        foreach my $netconf (@$netconfs) {
            NetconfInterface->new(netconf_id   => $netconf->id,
                                  interface_id => $interface->id,);
        }
    }
}

sub _getHostManagerParams {
    my %args = @_;

    General::checkParams(args => \%args, required => ['sp']);

    my $sp = $args{sp};

    my $host_manager  = $sp->getHostManager();
    my @c_interfaces  = $sp->interfaces;
    my $ehost_manager = EEntity->new(entity => $host_manager);
    my $host_manager_params = $sp->getManagerParameters(manager_type => 'HostManager');
    $host_manager_params->{interfaces} = \@c_interfaces;

    return { params => $host_manager_params, ehost_manager => $ehost_manager };
}

sub _createDummyNetconf {
    my %args = @_;

    General::checkParams(args => \%args, required => ['name', 'role']);

    my $name = $args{name};
    my $role = $args{role};

    my $role_id = Entity::NetconfRole->find(hash => {netconf_role_name => $role})->id;
    my $netconf = Entity::Netconf->create(netconf_name => $name, netconf_role_id => $role_id);

    return $netconf;
}

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

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Get admin user';

    my $cluster_name = $args{name};
    my $cluster;
    lives_ok {
        $cluster = Entity::ServiceProvider::Cluster->new(
                       active                 => 1,
                       cluster_name           => $cluster_name,
                       cluster_min_node       => "1",
                       cluster_max_node       => "30",
                       cluster_priority       => "100",
                       cluster_si_shared      => 0,
                       cluster_si_persistent  => 1,
                       cluster_domainname     => 'my.domain',
                       cluster_basehostname   => $args{hn},
                       cluster_nameserver1    => '192.168.0.31',
                       cluster_nameserver2    => '127.0.0.1',
                       user_id                => $admin_user->id,
                   );
    } 'AddCluster operation enqueue';

    lives_ok {
        $cluster->addManager(manager_type   => 'HostManager',
                             manager_id     => $physical_hoster->id,
                             manager_params => {
                                 cpu => 1,
                                 ram => 536870912, 
                             });
    } 'Attach host manager to cluster ';

    foreach my $interface (@{ $args{interfaces} }) {
        #we create a netconf for the interface
        my $name = 'netconf' . $interface->{name};
        my $netconf = Entity::Netconf->create(netconf_name => $name , netconf_role_id => $admin_role);

        my %interface;

        $interface{interface_netconf} = $netconf;
        $interface{bonds_number}      = $interface->{bond_nb};

        #we attach the interface to the cluster
        $cluster->addNetworkInterface(netconfs     => [ $interface{interface_netconf} ],
                                      bonds_number => $interface{bonds_number});
    }

    return $cluster;
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
                   host_ram           => 4 * 1024 * 1024 * 1024,
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
    
    return $host;
}

1;
