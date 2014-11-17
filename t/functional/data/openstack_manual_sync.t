#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Entity::Component::KanopyaExecutor;
use Entity::Component::Virtualization::OpenStack;
use Kanopya::Database;
use Clone qw(clone);

Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

use TryCatch;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => 'openstack_manual_sync.t.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

my $openstack;
my $num_hv_start;
my $num_vm_start;
my $num_image_start;

my $testing = 1;
main();

sub main {
    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    my @hosts = Entity::Host::Hypervisor->search();
    $num_hv_start = scalar (@hosts);

    @hosts = Entity::Host::VirtualMachine->search();
    $num_vm_start = scalar (@hosts);

    my @images = Entity::Masterimage->search();
    $num_image_start = scalar (@images);

    $openstack = Entity::Component::Virtualization::OpenStack->new(
        executor_component_id => Entity::Component::KanopyaExecutor->find->id,
        api_username => 'test',
        api_password => 'pass',
        keystone_url => '0.0.0.0',
        tenant_name => 'test',
    );

    lives_ok {
        $openstack->_load(infra => infra1());
    } 'Load infra 1';

    lives_ok {
        verify(infra1());
    } 'Verify infra 1';

    lives_ok {
        $openstack->_load(infra => infra2());
    } 'Load infra 2';

    lives_ok {
        verify(infra2());
    } 'Verify infra 2';

    lives_ok {
        $openstack->_load(infra => infra1());
    } 'Reload infra 1';

    lives_ok {
        verify(infra1());
    } 'Reverify infra 1';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub verify {
    my $infra = shift;

    # Verify hypervisors
    my %hypervisors = map {$_->host_serial_number, $_} $openstack->hypervisors;
    if (scalar keys %hypervisors ne scalar @{$infra->{hypervisors}}) {
        die 'Wrong number of hypervisors got ' . (scalar keys %hypervisors)
            . ' expected ' . scalar @{$infra->{hypervisors}};
    }

    for my $hypervisor (@{$infra->{hypervisors}}) {
        my $hv = $hypervisors{$hypervisor->{hypervisor_hostname}};
        if (! defined $hv) {
            die 'Hypervisor ' . ($hypervisor->{hypervisor_hostname})
                . ' not found in Kanopya DB';
        }

        if ($hv->host_core ne $hypervisor->{vcpus}) {
            die 'Wrong core number';
        }
        if ($hv->host_ram ne $hypervisor->{memory_mb} * 1024 * 1024) {
            die 'Wrong ram amount';
        }

        if (! defined $hv->node) {
            die 'Node is missing';
        }
        if ($hv->node->node_hostname ne $hypervisor->{hypervisor_hostname}) {
            die 'Wrong node_hostname';
        }
    }

    # Verify virtual machines

    my %db_vms = map {$_->openstack_vm_uuid, $_} $openstack->hosts;
    my @infra_vms = map {@{$_->{servers}}} @{$infra->{hypervisors}};

    if (scalar @infra_vms ne scalar keys %db_vms) {
        die 'Wrong number of virtual machines. Expected '
            . (scalar keys %db_vms) . ' got '
            . (scalar @infra_vms);
    }

    for my $infra_vm (@infra_vms) {
        if (! defined $db_vms{$infra_vm->{id}}) {
            die 'Virtual machine ' . $infra_vm->{id}
                . 'not found in Kanopya DB';
        }
        my $vm = $db_vms{$infra_vm->{id}};
        if ($vm->host_core ne $infra_vm->{flavor}->{vcpus}) {
            die 'Wrong core number';
        }
        if ($vm->host_ram ne $infra_vm->{flavor}->{ram} * 1024 * 1024) {
            die 'Wrong ram amount';
        }
        if ($vm->hypervisor->host_serial_number
            ne $infra_vm->{'OS-EXT-SRV-ATTR:host'}) {

            die 'Wrong hypervisor'
        }

        if (! defined $vm->node) {
            die 'Node is missing';
        }
        if ($vm->node->node_hostname ne $infra_vm->{name}) {
            die 'Wrong node_hostname';
        }

        # Verify ifaces / mac / ip
        my @ifaces = $vm->ifaces;
        if (scalar @ifaces ne scalar keys %{$infra_vm->{addresses}}) {
                die 'Wrong num of ifaces for vm ' . $vm->label . ' got '
                    . (scalar @ifaces) . ' expected '
                    . (scalar keys %{$infra_vm->{addresses}});
        }

        my $net = {};
        for my $subnet (values %{$infra_vm->{addresses}}) {
            for my $values (@{$subnet}) {
                $net->{$values->{'OS-EXT-IPS-MAC:mac_addr'}} = 1;
                $net->{$values->{addr}} = 1;
            }
        }

        for my $iface ($vm->ifaces) {
            if (! defined $net->{$iface->iface_mac_addr}){
                die 'Mac addr ' . $iface->iface_mac_addr . ' not found in vm info';
            }
        }
    }

    # Verify extra hosts presence
    my @hosts = Entity::Host::Hypervisor->search();
    my $num_hv = scalar (@hosts);

    @hosts = Entity::Host::VirtualMachine->search();
    my $num_vm = scalar (@hosts);

    my $num_expected_hv = $num_hv_start + scalar @{$infra->{hypervisors}};
    my $num_expected_vm = $num_vm_start +  scalar (map {@{$_->{servers}}} @{$infra->{hypervisors}});

    if ($num_hv ne $num_expected_hv) {
        die 'Wrong number of total hypervisor. Expected '
            . $num_expected_hv . ' got ' . $num_hv;
    }

    if ($num_vm ne $num_expected_vm) {
        die 'Wrong number of total vm. Expected '
            . $num_expected_vm . ' got ' . $num_vm;
    }

    # Verify master images
    for my $image_info (@{$infra->{images}}) {
        Entity::Masterimage::GlanceMasterimage->find(hash => {
            masterimage_name => $image_info->{name},
            masterimage_size => $image_info->{size},
            masterimage_file => $image_info->{file},
        });
    }

    # Verify extra master image presence
    my @images = Entity::Masterimage->search();
    $num_image = scalar (@images);
    my $num_expected_images = $num_image_start + scalar (@{$infra->{images}});
    if ($num_expected_images ne $num_image) {
        die 'Wrong number of total images. Expected '
            . $num_expected_images . ' got ' . $num_image;
    }
}

sub infra2 {

    # Add new hypervisor with a new vm
    my $infra = clone(infra1());
    my $hypervisor2 = {
        'vcpus' => 8,
        'servers' => [{
            'name' => 'vm_test_4',
            'OS-EXT-SRV-ATTR:hypervisor_hostname' => 'hv_test_2',
            'OS-EXT-SRV-ATTR:host' => 'hv_test_2',
            'OS-EXT-STS:power_state' => 1,
            'id' => '455a1f76-5814-4d7b-9b65-1a3d9efcc611',
            'status' => 'ACTIVE',
            'flavor' => { 'ram' => 64, 'vcpus' => 1, 'id' => '42', 'name' => 'm1.nano' },
            'OS-EXT-STS:vm_state' => 'active',
            'addresses' => { 'network1' => [{ 'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:d8:44',
                                            'OS-EXT-IPS:type' => 'fixed',
                                            'addr' => '192.168.0.4',
                                            'version' => 4 }]},
            },
        ],
        'id' => 1,
        'status' => 'enabled',
        'state' => 'up',
        'hypervisor_hostname' => 'hv_test_2',
        'host_ip' => '192.168.122.2',
        'memory_mb' => 5872,
    };

    $infra->{hypervisors}->[1] = $hypervisor2;

    # Delete an old vm on hypervisor 1
    delete $infra->{hypervisors}->[0]->{servers}->[1];

    # Move a vm from hypervisor 1 to hypervisor 2 and change ram/cpu/ip/mac_addr
    $vm = pop @{$infra->{hypervisors}->[0]->{servers}};

    $vm->{flavor}->{ram} = 32;
    $vm->{flavor}->{vcpus} = 2;
    $vm->{'OS-EXT-SRV-ATTR:hypervisor_hostname'} = 'hv_test_2';
    $vm->{'OS-EXT-SRV-ATTR:host'} = 'hv_test_2';
    $vm->{'addresses'}->{network1}->[0]->{'OS-EXT-IPS-MAC:mac_addr'} = '12:34:56:78:90:ab';
    $vm->{'addresses'}->{network1}->[0]->{'addr'} = '192.168.66.66';

    $infra->{hypervisors}->[1]->{servers}->[1] = $vm;

    # Add new vm on hypervisor 1
    $infra->{hypervisors}->[0]->{servers}->[1] = {
        'name' => 'vm_test_5',
        'OS-EXT-SRV-ATTR:hypervisor_hostname' => 'hv_test_1',
        'OS-EXT-SRV-ATTR:host' => 'hv_test_1',
        'OS-EXT-STS:power_state' => 1,
        'id' => '555a1f76-5814-4d7b-9b65-1a3d9efcc611',
        'status' => 'ACTIVE',
        'flavor' => { 'ram' => 64, 'vcpus' => 1, 'id' => '42', 'name' => 'm1.nano' },
        'OS-EXT-STS:vm_state' => 'active',
        'addresses' => { 'network1' => [{ 'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:d8:55',
                                        'OS-EXT-IPS:type' => 'fixed',
                                        'addr' => '192.168.0.5',
                                        'version' => 4 }]},
    },

    # Add a new network to the first vm
    $infra->{hypervisors}->[0]->{servers}->[0]->{addresses}->{network3} = [{
        'OS-EXT-IPS:type' => 'fixed',
        'addr' => '192.168.2.1',
        'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:d8:13',
        'version' => 4
    }];

    # modify an image
    $infra->{images}->[0]->{size} = 12345678;

    # replace an image
    $infra->{images}->[1]= {
        'name' => 'image_test_3',
        'file' => '/v2/images/331578fe-8bc0-4968-977c-2c1645d1ccb3/file',
        'size' => 111111111,
    };
    return $infra;
}

sub infra1 {
    my $infra = {'volume_types' => [], 'flavors' => [], 'networks' => [],
                 'availability_zones' => [], 'subnets' => [], 'tenants' => [],
                 'volumes' => [],
                 'hypervisors' => [{
                     'vcpus' => 8,
                     'servers' => [{
                          'name' => 'vm_test_1',
                          'OS-EXT-SRV-ATTR:hypervisor_hostname' => 'hv_test_1',
                          'OS-EXT-SRV-ATTR:host' => 'hv_test_1',
                          'OS-EXT-STS:power_state' => 1,
                          'id' => '155a1f76-5814-4d7b-9b65-1a3d9efcc611',
                          'status' => 'ACTIVE',
                          'flavor' => { 'ram' => 64, 'vcpus' => 1, 'id' => '42', 'name' => 'm1.nano' },
                          'OS-EXT-STS:vm_state' => 'active',
                          'addresses' => { 'network1' => [{ 'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:d8:11',
                                                            'OS-EXT-IPS:type' => 'fixed',
                                                            'addr' => '192.168.0.1',
                                                            'version' => 4 }],
                                           'network2' => [{ 'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:d8:12',
                                                            'OS-EXT-IPS:type' => 'fixed',
                                                            'addr' => '192.168.1.1',
                                                            'version' => 4 }]
                                         },
                          },
                          {
                          'name' => 'vm_test_2',
                          'OS-EXT-SRV-ATTR:hypervisor_hostname' => 'hv_test_1',
                          'OS-EXT-SRV-ATTR:host' => 'hv_test_1',
                          'OS-EXT-STS:power_state' => 1,
                          'id' => '255a1f76-5814-4d7b-9b65-1a3d9efcc611',
                          'status' => 'ACTIVE',
                          'flavor' => { 'ram' => 128, 'vcpus' => 2, 'id' => '42', 'name' => 'm1.nano' },
                          'OS-EXT-STS:vm_state' => 'active',
                          'addresses' => { 'network1' => [{ 'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:d8:22',
                                                          'OS-EXT-IPS:type' => 'fixed',
                                                          'addr' => '192.168.0.2',
                                                          'version' => 4 }]},
                          },
                          {
                          'name' => 'vm_test_3',
                          'OS-EXT-SRV-ATTR:hypervisor_hostname' => 'hv_test_1',
                          'OS-EXT-SRV-ATTR:host' => 'hv_test_1',
                          'OS-EXT-STS:power_state' => 1,
                          'id' => '355a1f76-5814-4d7b-9b65-1a3d9efcc611',
                          'status' => 'ACTIVE',
                          'flavor' => { 'ram' => 128, 'vcpus' => 2, 'id' => '42', 'name' => 'm1.nano' },
                          'OS-EXT-STS:vm_state' => 'active',
                          'addresses' => { 'network1' => [{ 'OS-EXT-IPS-MAC:mac_addr' => 'fa:16:3e:6e:d8:33',
                                                          'OS-EXT-IPS:type' => 'fixed',
                                                          'addr' => '192.168.0.3',
                                                          'version' => 4 }]},
                          }
                     ],
                     'id' => 1,
                     'status' => 'enabled',
                     'state' => 'up',
                     'hypervisor_hostname' => 'hv_test_1',
                     'host_ip' => '192.168.122.1',
                     'memory_mb' => 5872,
                }],
                'images' => [{
                    'name' => 'image_test_1',
                    'file' => '/v2/images/111578fe-8bc0-4968-977c-2c1645d1ccb3/file',
                    'size' => 209649664,
                },
                {
                    'name' => 'image_test_2',
                    'file' => '/v2/images/221578fe-8bc0-4968-977c-2c1645d1ccb3/file',
                    'size' => 209649664,
                }],
        };
    return $infra;
}
