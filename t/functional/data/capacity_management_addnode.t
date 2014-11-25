#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use JSON;
use File::Temp;

use Log::Log4perl qw(:easy);
use File::Basename;
Log::Log4perl->easy_init({level=>'DEBUG', file=>basename(__FILE__) . '.log', layout=>'%d [ %H - %P ] %p -> %M - %m%n'});
my $log = get_logger("");

my $testing = 1;

use Kanopya::Database;
use Entity::Component;
use Entity::Component::Virtualization::OpenStack;
use Entity::Component::KanopyaExecutor;
use ClassType::ComponentType;
use Kanopya::Test::Register;
use Kanopya::Test::Create;

use String::Random;
my $random = String::Random->new;
my $postfix = $random->randregex("[a-f]\d\d[a-f]");

Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );
my @vms;
my %vm_index;
my $service_provider;

my $iaas;
my $cluster;
my ($h1, $h2, $h3);

main();

sub main {
    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    infra();
    single_start();
    no_space();
    test_strategies();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub infra {
    lives_ok {
        $iaas = Entity::Component::Virtualization::OpenStack->new(
                    executor_component_id => Entity::Component::KanopyaExecutor->find()->id,
                    api_username => 'user',
                    api_password => 'password',
                    tenant_name => 'tenant',
                    keystone_url => 'localhost',
                );

        $iaas->param_preset->update(params => {
            tenants_name_id => { flavor => '1' },
            flavors => { 1 => { vcpus => 2, ram => 2048, name => 'flavor' } },
        });

        $cluster = Kanopya::Test::Create->createCluster(
                       cluster_conf => {
                           cluster_name => 'os_test' . $postfix,
                           managers => {
                               host_manager => {
                                   manager_id     => $iaas->id,
                                   manager_type   => "HostManager",
                                   manager_params => {
                                       flavor => "flavor",
                                       availability_zone => "nova",
                                       hosting_tenant => "tenant",
                                   },
                               },
                           },
                       },
                   );

        $h1 = $iaas->_createHypervisor(ram => 8 * 1024 ** 3,
                                       core => 4,
                                       hostname => 'hypervisor ' . $postfix);

        Entity::Node->new(
            node_hostname => 'hypervisor' . $postfix,
            host_id => $h1->id,
            node_state => 'in:' . time(),
            node_number   => 1,
        );
    } 'Infrastructure construction';
}


sub single_start {
    lives_ok {
        my $w = $cluster->addNode;

        my $executor = Kanopya::Test::Execution->_executor;
        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if ((! defined $pp->{context}->{hypervisor})
            || $pp->{context}->{hypervisor} ne $h1->id) {
            $DB::single = 1;
            die 'Hypervisor <' . $h1->id . '> should have been selected';
        }
        $executor->oneRun(cbname => 'handle_result', duration => 1);
    } 'Single add node with 1 hypervisor, no placement policy';
}

sub no_space {
    lives_ok {
        $h1->host_core(1);
        my $w = $cluster->addNode;

        my $executor = Kanopya::Test::Execution->_executor;

        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if (defined $pp->{context}->{hypervisor}) {
            die 'No hypervisor should have been selected';
        }

        $executor->oneRun(cbname => 'handle_result', duration => 1);
    } 'Add node when there is no space';
}

sub test_strategies {
    $h1->host_core(8);

    # Put a vm on hypervisor 1 chich belongs to $cluster
    my $vm = $iaas->_createVm(
              ram => 2 * 1024 ** 3,
              core => 2,
              vm_uuid => '1' . $postfix,
              hostname => 'vm1' . $postfix,
              num_ifaces => 0,
              hypervisor_name => $h1->node->node_hostname,
          );

    Entity::Node->new(
        node_hostname => 'vm1' . $postfix,
        host_id => $vm->id,
        node_state => 'in:' . time(),
        node_number   => 1,
        service_provider_id => $cluster->id,
    );

    # Add a bigger vm on a new hypervisor 2
    $h2 = $iaas->_createHypervisor(ram => 8 * 1024 ** 3,
                                   core => 8,
                                   hostname => 'hypervisor2 ' . $postfix);

    Entity::Node->new(
        node_hostname => 'hypervisor2' . $postfix,
        host_id => $h2->id,
        node_state => 'in:' . time(),
        node_number   => 1,
    );

    my $vm2 = $iaas->_createVm(
              ram => 3 * 1024 ** 3,
              core => 3,
              vm_uuid => '2' . $postfix,
              hostname => 'vm2' . $postfix,
              num_ifaces => 0,
              hypervisor_name => $h2->node->node_hostname,
          );

    # Add a smaller vm on a new hypervisor 3

    $h3 = $iaas->_createHypervisor(ram => 8 * 1024 ** 3,
                                   core => 8,
                                   hostname => 'hypervisor3 ' . $postfix);

    Entity::Node->new(
        node_hostname => 'hypervisor3' . $postfix,
        host_id => $h3->id,
        node_state => 'in:' . time(),
        node_number   => 1,
    );

    # put a vm on hypervisor 1
    my $vm3 = $iaas->_createVm(
                  ram => 1 * 1024 ** 3,
                  core => 1,
                  vm_uuid => '1' . $postfix,
                  hostname => 'vm3' . $postfix,
                  num_ifaces => 0,
                  hypervisor_name => $h3->node->node_hostname,
              );


    my $executor = Kanopya::Test::Execution->_executor;

    lives_ok {
        my $params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $params->{affinity_policy} = 'least_loaded';
        $params = $cluster->addManagerParameters(manager_type => 'HostManager',
                                                 params => $params);
        my $w = $cluster->addNode;
        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if ((! defined $pp->{context}->{hypervisor})
            || $pp->{context}->{hypervisor} ne $h3->id) {
            die 'The least loaded hypervisor <' . $h3->id . '> should have been selected';
        }
        $executor->oneRun(cbname => 'handle_result', duration => 1);

    } 'Select least loaded hypervisor';

    lives_ok {
        my $params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $params->{affinity_policy} = 'most_loaded';
        $params = $cluster->addManagerParameters(manager_type => 'HostManager',
                                                 params => $params);
        my $w = $cluster->addNode;
        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if ((! defined $pp->{context}->{hypervisor})
            || $pp->{context}->{hypervisor} ne $h2->id) {
            $DB::single = 1;
            die 'The most loaded hypervisor <' . $h2->id . '> should have been selected';
        }
        $executor->oneRun(cbname => 'handle_result', duration => 1);

    } 'Select most loaded hypervisor';

    lives_ok {
        my $params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $params->{affinity_policy} = 'affinity';
        $params = $cluster->addManagerParameters(manager_type => 'HostManager',
                                                 params => $params);
        my $w = $cluster->addNode;
        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if ((! defined $pp->{context}->{hypervisor})
            || $pp->{context}->{hypervisor} ne $h1->id) {
            die 'The most loaded hypervisor <' . $h1->id . '> should have been selected';
        }

        $executor->oneRun(cbname => 'handle_result', duration => 1);
    } 'Select affinity hypervisor';

    my $hv_sel;

    lives_ok {
        my $params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $params->{affinity_policy} = 'anti_affinity';
        $params = $cluster->addManagerParameters(manager_type => 'HostManager',
                                                 params => $params);
        my $w = $cluster->addNode;
        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if ((! defined $pp->{context}->{hypervisor})
            || $pp->{context}->{hypervisor} eq $h1->id) {
            $DB::single = 1;
            die 'The hypervisor <' . $h1->id . '> should not have been selected';
        }
        $executor->oneRun(cbname => 'handle_result', duration => 1);
        $hv_sel = $pp->{context}->{hypervisor};
    } 'Select first anti affinity hypervisor part 1';

    # put the vm the selected hypervisor
    my $vm4 = $iaas->_createVm(
                  ram => 2 * 1024 ** 3,
                  core => 2,
                  vm_uuid => '1' . $postfix,
                  hostname => 'vm4' . $postfix,
                  num_ifaces => 0,
                  hypervisor_name => Entity::Host::Hypervisor->get(id => $hv_sel)->node->node_hostname,
              );

    Entity::Node->new(
        node_hostname => 'vm4' . $postfix,
        host_id => $vm4->id,
        node_state => 'in:' . time(),
        node_number   => 1,
        service_provider_id => $cluster->id,
    );

    lives_ok {
        my $params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $params->{affinity_policy} = 'anti_affinity';
        $params = $cluster->addManagerParameters(manager_type => 'HostManager',
                                                 params => $params);
        my $w = $cluster->addNode;
        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if ((! defined $pp->{context}->{hypervisor})
            || $pp->{context}->{hypervisor} eq $h1->id
            || $pp->{context}->{hypervisor} eq $hv_sel) {

            die 'Second anti affinity vm is wrongly placed';
        }

        $executor->oneRun(cbname => 'handle_result', duration => 1);
        $hv_sel = $pp->{context}->{hypervisor};

    } 'Select anti affinity hypervisor part 2';

    # put the vm the selected hypervisor
    my $vm5 = $iaas->_createVm(
                  ram => 2 * 1024 ** 3,
                  core => 2,
                  vm_uuid => '1' . $postfix,
                  hostname => 'vm5' . $postfix,
                  num_ifaces => 0,
                  hypervisor_name => Entity::Host::Hypervisor->get(id => $hv_sel)->node->node_hostname,
              );

    Entity::Node->new(
        node_hostname => 'vm5' . $postfix,
        host_id => $vm5->id,
        node_state => 'in:' . time(),
        node_number   => 1,
        service_provider_id => $cluster->id,
    );

    # Then put 2 vm 2 hypervisor and see that anti affinity choose hv1
    my $vm6 = $iaas->_createVm(
                  ram => 2 * 1024 ** 3,
                  core => 2,
                  vm_uuid => '1' . $postfix,
                  hostname => 'vm6' . $postfix,
                  num_ifaces => 0,
                  hypervisor_name => $h2->node->node_hostname,
              );

    Entity::Node->new(
        node_hostname => 'vm6' . $postfix,
        host_id => $vm6->id,
        node_state => 'in:' . time(),
        node_number   => 1,
        service_provider_id => $cluster->id,
    );

    my $vm7 = $iaas->_createVm(
                  ram => 2 * 1024 ** 3,
                  core => 2,
                  vm_uuid => '1' . $postfix,
                  hostname => 'vm7' . $postfix,
                  num_ifaces => 0,
                  hypervisor_name => $h3->node->node_hostname,
              );

    Entity::Node->new(
        node_hostname => 'vm7' . $postfix,
        host_id => $vm7->id,
        node_state => 'in:' . time(),
        node_number   => 1,
        service_provider_id => $cluster->id,
    );

    lives_ok {
        my $params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $params->{affinity_policy} = 'anti_affinity';
        $params = $cluster->addManagerParameters(manager_type => 'HostManager',
                                                 params => $params);
        my $w = $cluster->addNode;
        $executor->oneRun(cbname => 'run_workflow', duration => 1);
        $executor->oneRun(cbname => 'execute_operation', duration => 1);

        my $op = $w->find(related => 'operations', hash => {'me.state' => 'processing'});
        my $pp = $op->param_preset->load;

        if ((! defined $pp->{context}->{hypervisor})
            || $pp->{context}->{hypervisor} ne $h1->id) {

            die 'Ultimate vm wrongly placed. Should be on $h1';
        }

        $executor->oneRun(cbname => 'handle_result', duration => 1);

    } 'Select anti affinity hypervisor part 3';

}




