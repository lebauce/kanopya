#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'openstack_sync.log',
    layout => '%F %L %p %m%n'
});
my $log = get_logger("");

use Kanopya::Database;
use BaseDB;
use General;
use Entity;
use ParamPreset;
use Kanopya::Tools::TestUtils 'expectedException';

use Entity::Component::Virtualization::NovaController;
use OpenstackSync;
use Kanopya::Tools::Register;
use Kanopya::Tools::Create;
use Node;
Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

my $nova_controller;
my $hypervisor1 = 'hypervisor_1';
my $hypervisor2 = 'hypervisor_2';

main();

sub main {
    Kanopya::Database::beginTransaction;

    register_infrastructure();
    $nova_controller = Entity::Component::Virtualization::NovaController->find();

    create_vm();
    test_create_and_delete_vm();
    test_create_and_rebuild_vm();

     Kanopya::Database::rollbackTransaction;
     # Kanopya::Database::commitTransaction;
}

sub register_infrastructure {

    my $nova_cluster = Kanopya::Tools::Create->createCluster(
                           cluster_conf => {
                               cluster_name => 'nova_cluster',
                               cluster_basehostname => 'nova',
                           },
                       );

    Kanopya::Tools::Execution->executeAll();

    $nova_controller = Entity::Component::Virtualization::NovaController->new(
                           service_provider_id => $nova_cluster->id
                       );

    # Add a fake hypervisor
    my $hv_host_1 = Kanopya::Tools::Register->registerHost(
                         board => {
                             serial_number => 1,
                             core          => 10,
                             ram           => 10*1024**3,
                             ifaces        => [ { name => 'eth0',pxe  => 0 } ]
                         },
                     );

    my $hv_host_2 = Kanopya::Tools::Register->registerHost(
                         board => {
                             serial_number => 1,
                             core          => 10,
                             ram           => 10*1024**3,
                             ifaces        => [ { name => 'eth0',pxe  => 0 } ]
                         },
                     );


    $hv_host_1 = $nova_controller->addHypervisor(host => $hv_host_1);
    $hv_host_2 = $nova_controller->addHypervisor(host => $hv_host_2);

    my $cluster = Kanopya::Tools::Create->createCluster(
                      cluster_conf => {
                          cluster_name         => 'compute_clustera',
                          cluster_basehostname => 'computea',
                      },
                  );

    Kanopya::Tools::Execution->executeAll();

    $hv_host_1 = $hv_host_1->reload;
    $hv_host_2 = $hv_host_2->reload;

    $cluster->registerNode(hostname => $hypervisor1,
                           host     => $hv_host_1,
                           number   => 1);

    $cluster->registerNode(hostname => $hypervisor2,
                           host     => $hv_host_2,
                           number   => 2);

}

sub test_create_and_delete_vm {
    my $message;

    my $hostname    = 'vm_test';
    my $ip1         = '10.0.0.0';
    my $ip2         = '10.0.0.1';
    my $memory_mb   = 512;
    my $vcpus       = 1;
    my $instance_id = "123456";

    my $node = create_vm(
                   hostname    => $hostname,
                   ips         => [$ip1, $ip2],
                   memory_mb   => $memory_mb,
                   vcpus       => $vcpus,
                   instance_id => $instance_id,
                   hypervisor  => $hypervisor1,
               );


    lives_ok {
        my $host   = $node->host;
        my @ifaces = $host->ifaces;
        my @ips    = ();

        for my $iface (@ifaces) {
            push @ips, $iface->ips;
        }

        $message = _get_delete_json(hostname => $hostname, instance_id => $instance_id);
        OpenstackSync->novaNotificationAnalyser(%$message, host_manager => $nova_controller);

        expectedException {
            Node->get(id => $node->id);
        } 'Kanopya::Exception::Internal::NotFound', 'Node <' .$node->id. '> not deleted';

        expectedException {
            Entity::Host->get(id => $host->id);
        } 'Kanopya::Exception::Internal::NotFound', 'Host <' .$host->id. '> not deleted';

        for my $ip (@ips) {
            expectedException {
                Ip->get(id => $ip->id);
            } 'Kanopya::Exception::Internal::NotFound', 'Ip <'.$ip->id.'> not deleted';
        }
    } 'Vm deletion'
};

sub test_create_and_rebuild_vm {

    my $message;

    my $hostname    = 'vm_test_2';
    my $ip          = '10.0.0.1';
    my $memory_mb   = 1024;
    my $vcpus       = 2;
    my $instance_id = "1983";

    $message = _get_create_json(
                   hostname    => $hostname,
                   ips         => [ $ip ],
                   memory_mb   => $memory_mb,
                   vcpus       => $vcpus,
                   instance_id => $instance_id,
                   hypervisor  => $hypervisor1,
               );

    my $node;

    lives_ok {
        OpenstackSync->novaNotificationAnalyser(%$message, host_manager => $nova_controller);

        $node = check_node_existance(
                    hostname    => $hostname,
                    ips         => [ $ip ],
                    memory_mb   => $memory_mb,
                    vcpus       => $vcpus,
                    instance_id => $instance_id,
                    hypervisor  => $hypervisor1,
                );

    } 'Vm creation';

    $message = _get_rebuild_json(
                   hypervisor  => $hypervisor2,
                   instance_id => $instance_id
               );

    lives_ok {
        OpenstackSync->novaNotificationAnalyser(%$message, host_manager => $nova_controller);
                $node = check_node_existance(
                    hostname    => $hostname,
                    ips         => [ $ip ],
                    memory_mb   => $memory_mb,
                    vcpus       => $vcpus,
                    instance_id => $instance_id,
                    hypervisor  => $hypervisor2,
                );
    }

}

sub create_vm {
    my %args = @_;
    my $message = _get_create_json(
                      hostname    => $args{hostname} || "test_vm",
                      memory_mb   => $args{memory_mb} || 512,
                      vcpus       => $args{vcpus} || 2,
                      ips         => $args{ips} || ["10.0.0.1"],
                      instance_id => $args{instance_id} || "12345",
                      hypervisor  => $args{hypervisor} || $hypervisor1,
                  );

    OpenstackSync->novaNotificationAnalyser(%$message, host_manager => $nova_controller);

    my $node;

    lives_ok {
        OpenstackSync->novaNotificationAnalyser(%$message, host_manager => $nova_controller);

        $node = check_node_existance(
                    hostname    => $args{hostname} || "test_vm",
                    ips         => $args{ips} || ["10.0.0.1"],
                    memory_mb   => $args{memory_mb} || 512,
                    vcpus       => $args{vcpus} || 2,
                    instance_id => $args{instance_id} || "12345",
                    hypervisor  => $args{hypervisor} || $hypervisor1,
                );

    } 'Vm creation';
    return $node;
}

sub check_node_existance {
    my %args = @_;

    my $hostname    = $args{hostname};
    my $memory_mb   = $args{memory_mb};
    my $vcpus       = $args{vcpus};
    my $ips         = $args{ips};
    my $instance_id = $args{instance_id};
    my $hypervisor  = $args{hypervisor};

    my $host = Entity::Host::VirtualMachine::OpenstackVm->find(
                   hash => {openstack_vm_uuid => $instance_id},
               );

    my $node = $host->node;

    if ($node->node_hostname ne $hostname.'-'.$instance_id) {
        die 'Wrong hostname, got <' . $node->node_hostname
            . '> expected <' . $hostname.'-'.$instance_id . '>';
    }

    if (! defined $host) {
        die 'Host not created';
    }

    if ($host->hypervisor->node->node_hostname ne $hypervisor) {
        die 'Wrong hypervisor got <' . $host->hypervisor->node->node_hostname
            . '> expected <' . $hypervisor . '>';
    }

    if ($host->host_ram != $memory_mb * 1024 ** 2) {
        die 'Wrong memory, got <' . $host->host_ram
            . '> expected <' . ($memory_mb * 1024 ** 2) . '>';
    }

    if ($host->host_core != $vcpus) {
        die 'Wrong core number, got <' . $host->host_core . '> expected <' . $vcpus . '>';
    }

    my @ifaces = $host->ifaces;

    if ((scalar @$ips) != (scalar @ifaces)) {
        die 'Expect one iface per ip';
    }

    # create a hash with ip in order to check existance
    my %ips_hash = map {$_ => 1} @$ips;

    for my $iface (@ifaces) {
        my @iface_ips = $iface->ips;
        if (scalar @iface_ips != 1) {
            die 'Expect to have only 1 ip for each iface';
        }

        my $ip = $iface_ips[0]->ip_addr;

        if (! exists $ips_hash{$ip}) {
            die "IP <$ip> not found in expected list <@$ips>";
        }
    }

    return $node;
}

sub _get_delete_json {
    my %args = @_;
    my $hostname = $args{hostname};
    my $instance_id = $args{instance_id};

        my $message = {
          'priority' => 'INFO',
          'message_id' => 'f3d92b5c-9b80-48bd-bb36-7c9b0375f601',
          '_context_roles' => [ 'admin' ],
          '_context_quota_class' => undef,
          '_context_user_name' => 'admin',
          '_context_is_admin' => bless( do{\(my $o = 1)}, 'JSON::XS::Boolean' ),
          'timestamp' => '2013-12-03 11:43:55.733514',
          '_context_service_catalog' =>
              [ { 'name' => 'cinder',
                  'endpoints_links' => [],
                  'type' => 'volume',
                  'endpoints' =>
                      [ { 'publicURL' => 'http://10.0.23.4:8776/v1/5d0bdac',
                          'internalURL' => 'http://cloud1.my.domain:8776/v1/5d0bdac',
                          'adminURL' => 'http://cloud1.my.domain:8776/v1/5d0bdac',
                          'region' => 'RegionOne',
                          'id' => '2c2d8a41c3404f038eb0484dd9dbdb18' } ]
              } ],
          '_context_request_id' => 'req-7eba6658-5eb9-4126-a5eb-30468cb8c01f',
          '_context_tenant' => '5d0bdac',
          'payload' => { 'memory_mb' => 512,
                         'access_ip_v4' => undef,
                         'disk_gb' => 0,
                         'hostname' => $hostname,
                         'kernel_id' => '',
                         'launched_at' => '2013-11-28 16:58:48',
                         'state' => 'deleted',
                         'reservation_id' => 'r-3wfp73nm',
                         'architecture' => undef,
                         'created_at' => '2013-11-28 16:58:41',
                         'tenant_id' => '5d0bdac',
                         'vcpus' => 1,
                         'metadata' => [],
                         'os_type' => undef,
                         'instance_type_id' => 2,
                         'image_ref_url' => 'http://10.0.23.4:9292/images/33164ed5',
                         'state_description' => '',
                         'instance_id' => $instance_id,
                         'ephemeral_gb' => 0,
                         'access_ip_v6' => undef,
                         'display_name' => 'doc_vm',
                         'availability_zone' => undef,
                         'host' => 'unused information',
                         'deleted_at' => '2013-12-03 11:43:55.603415',
                         'root_gb' => 0,
                         'user_id' => '39c6d149d67e4e588b44a5446c3d1590',
                         'ramdisk_id' => '',
                         'image_meta' => { 'base_image_ref' => '33164ed5' },
                         'instance_type' => 'm1.tiny' },
          '_context_timestamp' => '2013-12-03T11:43:45.008512',
          '_context_user' => '39c6d149d67e4e588b44a5446c3d1590',
          'publisher_id' => 'compute.cloud1',
          'ack_cb' => sub { "DUMMY" },
          '_unique_id' => '9af66644eb204fd3859bfc956822d5f4',
          'event_type' => 'compute.instance.delete.end',
          '_context_auth_token' => 'b3983572bdf82bdd9b49cae9634cfe96',
          '_context_project_name' => 'openstack',
          '_context_project_id' => '5d0bdac',
          '_context_user_id' => '39c6d149d67e4e588b44a5446c3d1590',
          '_context_remote_address' => '10.0.23.4',
          '_context_instance_lock_checked' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
          '_context_read_deleted' => 'no'
        };

        return $message;
}

sub _get_create_json {
    my %args = @_;

    my $hostname    = $args{hostname};
    my $ips         = $args{ips};
    my $memory_mb   = $args{memory_mb};
    my $vcpus       = $args{vcpus};
    my $instance_id = $args{instance_id};
    my $hypervisor  = $args{hypervisor};

    my @fixed_ips = ();

    for my $ip (@$ips) {
        my $ip_hash = { 'version' => 4,
                        'floating_ips' => [],
                        'type' => 'fixed',
                        'address' => $ip,
                        'label' => 'network',
                        'meta' => {} };

        push @fixed_ips, $ip_hash;
    }

    my $message = {
          'priority' => 'INFO',
          'message_id' => '699ed8b4-5708-4002-805d-2506c6ca21c4',
          '_context_roles' => [
                                'admin'
                              ],
          '_context_quota_class' => undef,
          '_context_user_name' => 'admin',
          '_context_is_admin' => bless( do{\(my $o = 1)}, 'JSON::XS::Boolean' ),
          'timestamp' => '2013-12-03 11:55:26.799518',
          '_context_service_catalog' =>
              [ { 'name' => 'cinder',
                  'endpoints_links' => [],
                  'type' => 'volume',
                  'endpoints' => [ { 'internalURL' => 'http://cloud1.my.domain:8776/v1/5d0bdac',
                                     'publicURL' => 'http://10.0.23.4:8776/v1/5d0bdac',
                                     'adminURL' => 'http://cloud1.my.domain:8776/v1/5d0bdac',
                                     'region' => 'RegionOne',
                                     'id' => '2c2d8a41c3404f038eb0484dd9dbdb18' } ]
              } ],
          '_context_request_id' => 'req-11779f5b-9ccc-4c32-a45b-4961bcdb5cbe',
          '_context_tenant' => '5d0bdac',
          'payload' => {
                         'image_name' => 'doc_image',
                         'memory_mb' => $memory_mb,
                         'access_ip_v4' => undef,
                         'disk_gb' => 0,
                         'hostname' => $hostname,
                         'kernel_id' => '',
                         'launched_at' => '2013-12-03T11:55:26.438317',
                         'state' => 'active',
                         'reservation_id' => 'r-0lga0up2',
                         'architecture' => undef,
                         'created_at' => '2013-12-03T11:55:19.000000',
                         'tenant_id' => '5d0bdac',
                         'vcpus' => $vcpus,
                         'metadata' => [],
                         'os_type' => undef,
                         'instance_type_id' => 2,
                         'image_ref_url' => 'http://10.0.23.5:9292/images/33164ed5',
                         'state_description' => '',
                         'instance_id' => $instance_id,
                         'ephemeral_gb' => 0,
                         'access_ip_v6' => undef,
                         'display_name' => 'doc_vm_2',
                         'availability_zone' => undef,
                         'host' => $hypervisor,
                         'deleted_at' => '',
                         'root_gb' => 0,
                         'user_id' => '39c6d149d67e4e588b44a5446c3d1590',
                         'ramdisk_id' => '',
                         'image_meta' => {
                                           'base_image_ref' => '33164ed5'
                                         },
                         'instance_type' => 'm1.tiny',
                         'fixed_ips' => \@fixed_ips,
                       },
          '_context_timestamp' => '2013-12-03T11:55:19.304844',
          '_context_user' => '39c6d149d67e4e588b44a5446c3d1590',
          'publisher_id' => 'compute.compute1',
          'ack_cb' => sub { "DUMMY" },
          '_unique_id' => 'f407d419a7504045a4b79fa6cb7e1d3b',
          'event_type' => 'compute.instance.create.end',
          '_context_auth_token' => 'b3983572bdf82bdd9b49cae9634cfe96',
          '_context_project_name' => 'openstack',
          '_context_project_id' => '5d0bdac',
          '_context_user_id' => '39c6d149d67e4e588b44a5446c3d1590',
          '_context_remote_address' => '10.0.23.4',
          '_context_instance_lock_checked' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
          '_context_read_deleted' => 'no'
        };
    return $message;
}


sub _get_rebuild_json {
    my %args = @_;
    my $instance_id = $args{instance_id};
    my $hypervisor  = $args{hypervisor};

    my $message = {
          'priority' => 'INFO',
          'message_id' => '67c095c4-77ae-485f-89ca-6dca8650414b',
          '_context_roles' => [
                                'admin'
                              ],
          '_context_quota_class' => undef,
          'timestamp' => '2013-12-09 15:12:02.115890',
          '_context_is_admin' => bless( do{\(my $o = 1)}, 'JSON::XS::Boolean' ),
          '_context_user_name' => 'admin',
          '_context_tenant' => '5f26097',
          '_context_request_id' => 'req-b062a930-f411-4430-9403-2c578c0c6317',
          '_context_service_catalog' =>
              [ { 'name' => 'cinder',
                  'endpoints_links' => [],
                  'type' => 'volume',
                  'endpoints' => [ { 'internalURL' => 'http://cloud1.my.domain:8776/v1/5f26097',
                                     'publicURL' => 'http://10.0.23.4:8776/v1/5f26097',
                                     'adminURL' => 'http://cloud1.my.domain:8776/v1/5f26097',
                                     'region' => 'RegionOne',
                                     'id' => '02f036d6b1b64646bf84f6fbe5882778' } ]
              } ],
          'payload' => {
                         'image_name' => 'doc_image',
                         'memory_mb' => 512,
                         'access_ip_v4' => undef,
                         'disk_gb' => 0,
                         'hostname' => 'doc-vm',
                         'kernel_id' => '',
                         'launched_at' => '2013-12-09T15:12:01.629868',
                         'state' => 'active',
                         'reservation_id' => 'r-q0mpxhtc',
                         'architecture' => undef,
                         'created_at' => '2013-12-09T14:28:17.000000',
                         'tenant_id' => '5f26097',
                         'vcpus' => 1,
                         'metadata' => [],
                         'os_type' => undef,
                         'instance_type_id' => 2,
                         'image_ref_url' => 'http://10.0.23.5:9292/images/768cdecb',
                         'state_description' => '',
                         'instance_id' => $instance_id,
                         'ephemeral_gb' => 0,
                         'access_ip_v6' => undef,
                         'display_name' => 'doc_vm',
                         'availability_zone' => undef,
                         'host' => $hypervisor,
                         'deleted_at' => '',
                         'root_gb' => 0,
                         'user_id' => '4e9f491c89124f6b800f9b3592b2d271',
                         'ramdisk_id' => '',
                         'image_meta' => {},
                         'instance_type' => 'm1.tiny',
                         'fixed_ips' => [
                                          {
                                            'version' => 4,
                                            'floating_ips' => [],
                                            'type' => 'fixed',
                                            'address' => '10.0.23.66',
                                            'label' => 'doc_network',
                                            'meta' => {}
                                          }
                                        ]
                       },
          '_context_timestamp' => '2013-12-09T15:11:56.007131',
          'publisher_id' => 'compute.compute1',
          '_context_user' => '4e9f491c89124f6b800f9b3592b2d271',
          '_unique_id' => 'a9d93692c63a41349f011fcebb6eafd8',
          'ack_cb' => sub { "DUMMY" },
          'event_type' => 'compute.instance.rebuild.end',
          '_context_auth_token' => 'MIIJYgY',
          '_context_project_name' => 'openstack',
          '_context_project_id' => '5f26097',
          '_context_user_id' => '4e9f491c89124f6b800f9b3592b2d271',
          '_context_remote_address' => '10.0.23.4',
          '_context_instance_lock_checked' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
          '_context_read_deleted' => 'no'
        };

   return $message;
}

1;
