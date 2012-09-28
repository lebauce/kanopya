# This script is called during setup to insert some kanopya data in DB
# The other way to insert data during setup is Data.sql.tt (pb: id management)
#
use lib qw(/opt/kanopya/lib/common/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/executor/ /opt/kanopya/lib/monitor/ /opt/kanopya/lib/orchestrator/ /opt/kanopya/lib/external);

use Administrator;
use ComponentType;
use Entity::Component;
use WorkflowDef;
use Operationtype;
use Entity::Policy;
use Entity::ServiceTemplate;
use Entity::InterfaceRole;
use Entity::Network;
use Entity::Kernel;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'ERROR', file=>'STDOUT', layout=>'%F %L %p %m%n'});

my ($login, $pwd) = @ARGV;

if (!defined $login || !defined $pwd) {
    print "Usage: perl populate_db.pl <login> <password>\n";
    exit;
}

Administrator::authenticate(login => $login, password => $pwd);

populate_workflow_def();
my $policies = populate_policies();
populate_servicetemplates($policies);



sub populate_workflow_def {
    my $wf_manager_component_type_id = ComponentType->find( hash => { component_category => 'Workflowmanager' } )->id;
    my $kanopya_wf_manager           = Entity::Component->find( hash => { component_type_id => $wf_manager_component_type_id, service_provider_id => 1 } );
    my $scale_op_id                  = Operationtype->find( hash => { operationtype_name => 'LaunchScaleInWorkflow' })->id;
    my $scale_amount_desc            = "Format:\n - '+value' to increase\n - '-value' to decrease\n - 'value' to set";

    # ScaleIn cpu workflow def
    my $scale_cpu_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'ScaleInCPU',
        params => {
            specific => {
                scalein_value => { label => 'Nb core', description => $scale_amount_desc},
            },
            internal => {
                scope_id => 1,
            },
            automatic => {
                context => { cloudmanager_comp => undef, host => undef },
                scalein_type => 'cpu',
            },
        }
    );
    $scale_cpu_wf->addStep( operationtype_id => $scale_op_id );

    # ScaleIn memory workflow def
    my $scale_mem_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'ScaleInMemory',
        params => {
            specific => {
                scalein_value => { label => 'Amount', unit => 'byte', description => $scale_amount_desc},
            },
            internal => {
                scope_id => 1,
            },
            automatic => {
                context => { cloudmanager_comp => undef, host => undef },
                scalein_type => 'memory',
            },
        }
    );
    $scale_mem_wf->addStep( operationtype_id => $scale_op_id );

    # AddNode workflow def
    my $addnode_op_id = Operationtype->find( hash => { operationtype_name => 'AddNode' })->id;
    my $prestart_op_id = Operationtype->find( hash => { operationtype_name => 'PreStartNode' })->id;
    my $start_op_id = Operationtype->find( hash => { operationtype_name => 'StartNode' })->id;
    my $poststart_op_id = Operationtype->find( hash => { operationtype_name => 'PostStartNode' })->id;
    my $addnode_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'AddNode',
        params => {
            automatic => {
                context => {
                    cluster => undef
                }
            },
            internal => { scope_id => 2 }
        }
    );
    $addnode_wf->addStep(operationtype_id => $addnode_op_id);
    $addnode_wf->addStep(operationtype_id => $prestart_op_id);
    $addnode_wf->addStep(operationtype_id => $start_op_id);
    $addnode_wf->addStep(operationtype_id => $poststart_op_id);

    # StopNode workflow def
    my $prestop_op_id = Operationtype->find( hash => { operationtype_name => 'PreStopNode' })->id;
    my $stop_op_id = Operationtype->find( hash => { operationtype_name => 'StopNode' })->id;
    my $poststop_op_id = Operationtype->find( hash => { operationtype_name => 'PostStopNode' })->id;
    my $stopnode_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'StopNode',
        params => {
            automatic => {
                context => {
                    cluster => undef
                }
            },
            internal => { scope_id => 2 }
        }
    );
    $stopnode_wf->addStep(operationtype_id => $prestop_op_id);
    $stopnode_wf->addStep(operationtype_id => $stop_op_id);
    $stopnode_wf->addStep(operationtype_id => $poststop_op_id);

    # Optimiaas Workflow def
    my $optimiaas_wf = $kanopya_wf_manager->createWorkflow(workflow_name => 'OptimiaasWorkflow');
    my $optimiaas_op_id = Operationtype->find( hash => { operationtype_name => 'LaunchOptimiaasWorkflow' })->id;
    $optimiaas_wf->addStep(operationtype_id => $optimiaas_op_id);

    # Migrate Workflow def
    my $migrate_wf = $kanopya_wf_manager->createWorkflow(workflow_name => 'MigrateWorkflow');
    my $migrate_op_id = Operationtype->find( hash => { operationtype_name => 'MigrateHost' })->id;
    $migrate_wf->addStep(operationtype_id => $migrate_op_id);

    # ResubmitNode  workflow def
    my $resubmit_node_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'ResubmitNode',
        params => {
            internal => {
                scope_id => 1,
            },
            automatic => {
                context => { host => undef },
            },
        }
    );
    my $resubmit_node_op_id  = Operationtype->find( hash => { operationtype_name => 'ResubmitNode' })->id;
    my $scale_cpu_op_id  = Operationtype->find( hash => { operationtype_name => 'ScaleCpuHost' })->id;
    my $scale_mem_op_id  = Operationtype->find( hash => { operationtype_name => 'ScaleMemoryHost' })->id;
    $resubmit_node_wf->addStep( operationtype_id => $resubmit_node_op_id );
    $resubmit_node_wf->addStep( operationtype_id => $scale_cpu_op_id );
    $resubmit_node_wf->addStep( operationtype_id => $scale_mem_op_id );

}

sub populate_policies {
    my %policies = ();

    # hosting
    my $type_id = ComponentType->find(hash => { component_name => 'Physicalhoster' })->id;
    my $physicalhoster = Entity::Component->find( hash => { component_type_id => $type_id, service_provider_id => 1 } );

    $policies{hosting} = Entity::Policy->new(
        policy_name => 'Default physical host',
        policy_desc => 'Hosting policy for default physical hosts',
        policy_type => 'hosting',
        host_manager_id     => $physicalhoster->id,
        ram      => 1024,
        ram_unit => 'M',
        cpu      => 1,
    );

    # storage
    my $lvm_type_id = ComponentType->find(hash => { component_name => 'Lvm' })->id;
    my $lvm = Entity::Component->find( hash => { component_type_id => $lvm_type_id, service_provider_id => 1 } );
    my $iscsit_type_id = ComponentType->find(hash => { component_name => 'Iscsitarget' })->id;
    my $iscsitarget = Entity::Component->find( hash => { component_type_id => $iscsit_type_id, service_provider_id => 1 } );

    $policies{storage} = Entity::Policy->new(
        policy_name => 'Kanopya LVM disk exported via ISCSI',
        policy_desc => 'Datastore on Kanopya cluster for PXE boot via ISCSI',
        policy_type => 'storage',
        disk_manager_id => $lvm->id,
        export_manager_id => $iscsitarget->id,
    );

    # network
    my $interfacerole = Entity::InterfaceRole->find(hash => {interface_role_name => 'admin'});
    my $network = Entity::Network->find(hash => {network_name => 'admin'});
    $policies{network} = Entity::Policy->new(
        policy_name => 'Default network configuration',
        policy_desc => 'Default network configuration, with admin and public interfaces',
        policy_type => 'network',
        cluster_nameserver1 => '127.0.0.1',
        cluster_nameserver2 => '127.0.0.1',
        cluster_domainname  => 'hedera-technology.com',
        interface_role_0    => $interfacerole->id,
        interface_networks_0 => $network->id,
        default_gateway_0    => 1
    );

    # scalability
    $policies{scalability} = Entity::Policy->new(
        policy_name => 'Cluster manual scalability',
        policy_desc => 'Manual scalability',
        policy_type => 'scalability',
        cluster_min_node => 1,
        cluster_max_node => 10,
        cluster_priority => 1
    );

    # system
    my $puppettypeid = ComponentType->find(hash => { component_name => 'Puppetagent' })->id;
    my $keepalivedtypeid = ComponentType->find(hash => { component_name => 'Keepalived' })->id;
    my $kernel = Entity::Kernel->find(hash => {kernel_name => '2.6.32-5-xen-amd64'});
    $policies{system} = Entity::Policy->new(
        policy_name => 'Debian squeeze',
        policy_desc => 'System policy for standard physical hosts',
        policy_type => 'system',
        cluster_si_shared     => 0,
        cluster_si_persistent => 0,
        kernel_id => $kernel->id,
        systemimage_size      => 5 * (1024**3), # 5GB
        component_type_0 => $puppettypeid,
        component_type_1 => $keepalivedtypeid,
    );

    # billing
    $policies{billing} = Entity::Policy->new(
        policy_name => 'Empty billing configuration',
        policy_desc => 'Empty billing configuration',
        policy_type => 'billing',
    );

    # orchestration
    $policies{orchestration} = Entity::Policy->new(
        policy_name => 'Empty orchestration configuration',
        policy_desc => 'Empty orchestration configuration',
        policy_type => 'orchestration',
    );

    return \%policies;
}

sub populate_servicetemplates {
    my ($policies) = @_;
    # Standard physical cluster
    my $template = Entity::ServiceTemplate->new(
        service_name => 'Standard physical cluster',
        service_desc => 'Service template for standard physical cluster declaration',
        hosting_policy_id => $policies->{hosting}->id,
        storage_policy_id => $policies->{storage}->id,
        network_policy_id => $policies->{network}->id,
        scalability_policy_id => $policies->{scalability}->id,
        system_policy_id => $policies->{system}->id,
        billing_policy_id => $policies->{billing}->id,
        orchestration_policy_id => $policies->{orchestration}->id
    );
}
