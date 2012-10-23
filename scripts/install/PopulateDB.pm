# This script is called during setup to insert some kanopya data in DB
# The other way to insert data during setup is Data.sql.tt (pb: id management)
#
use lib qw(/opt/kanopya/lib/common/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/executor/ /opt/kanopya/lib/monitor/ /opt/kanopya/lib/orchestrator/ /opt/kanopya/lib/external);

use Kanopya::Config;
use Administrator;
use ComponentType;
use Entity::Component;
use WorkflowDef;
use Operationtype;
use NetworkPoolip;
use Entity::Policy;
use Entity::ServiceTemplate;
use Entity::InterfaceRole;
use Entity::Network;
use Entity::Kernel;
use Entity::Host;
use Entity::Poolip;
use Entity::Component::Physicalhoster0;
use EEntity;
use ClassType;
use Profile;
use Entity::Gp;
use Entity::User;
use Entityright;
use UserProfile;
use Entity::Processormodel;
use Entity::Hostmodel;
use POSIX;
use Date::Simple (':all');
use Operationtype;
use ComponentType;
use ComponentTemplate;
use ConnectorType;
use Indicatorset;
use Indicator;
use Entity::Poolip;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Network;
use Entity::Interface;
use NetworkPoolip;
use Entity::Iface;
use Ip;
use Externalnode::Node;
use ServiceProviderManager;
use Lvm2Vg;
use Scope;
use ScopeParameter;
use Entity::Component::Lvm2;
use Entity::Component::Iscsitarget1;
use Entity::Component::Dhcpd3;
use Entity::Component::Atftpd0;
use Entity::Component::Snmpd5;
use Entity::Component::Nfsd3;
use Entity::Component::Syslogng3;
use Entity::Component::Puppetmaster2;
use Entity::Component::Openiscsi2;
use Entity::Component::Physicalhoster0;
use Entity::Component::Fileimagemanager0;
use Entity::Component::Kanopyacollector1;
use Entity::Component::Kanopyaworkflow0;
use Entity::Component::Linux0;
use Entity::Component::Mailnotifier0;

my @classes = (
    'Entity::Gp',
    'Entity::Host',
    'Entity::Hostmodel',
    'Entity::Kernel',
    'Entity::Processormodel',
    'Entity::Systemimage',
    'Entity::User',
    'Entity::ServiceProvider::Inside::Cluster',
    'Entity::ServiceProvider::Inside::Server',
    'Entity::ServiceProvider::Outside::Netapp',
    'Entity::ServiceProvider::Outside::UnifiedComputingSystem',
    'Entity::ContainerAccess::IscsiContainerAccess',
    'Entity::ContainerAccess::NfsContainerAccess',
    'Entity::ContainerAccess::LocalContainerAccess',
    'Entity::Container::LvmContainer',
    'Entity::Container::LocalContainer',
    'Entity::Component::Lvm2',
    'Entity::Component::Iscsitarget1',
    'Entity::Component::Apache2',
    'Entity::Component::Atftpd0',
    'Entity::Component::Dhcpd3',
    'Entity::Component::HAProxy1',
    'Entity::Component::Iptables1',
    'Entity::Component::Keepalived1',
    'Entity::Component::Memcached1',
    'Entity::Component::Linux0',
    'Entity::Component::Mysql5',
    'Entity::Component::Openiscsi2',
    'Entity::Component::Openldap1',
    'Entity::Component::Opennebula3',
    'Entity::Component::Openssh5',
    'Entity::Component::Php5',
    'Entity::Component::Snmpd5',
    'Entity::Component::Syslogng3',
    'Entity::Component::Nfsd3',
    'Entity::Connector::ActiveDirectory',
    'Entity::Connector::Scom',
    'Entity::ServiceProvider::Outside::Externalcluster',
    'Entity::Component::Physicalhoster0',
    'Entity::Poolip',
    'Entity::Network::Vlan',
    'Entity::Masterimage',
    'Entity::Connector::UcsManager',
    'Entity::Component::Fileimagemanager0',
    'Entity::Connector::NetappManager',
    'Entity::Connector::NetappLunManager',
    'Entity::Connector::NetappVolumeManager',
    'Entity::Container::NetappLun',
    'Entity::Container::NetappVolume',
    'Entity::Container::FileContainer',
    'Entity::ContainerAccess::FileContainerAccess',
    'Entity::ManagerParameter',
    'Entity::NfsContainerAccessClient',
    'Entity::Network',
    'Entity::InterfaceRole',
    'Entity::Interface',
    'Entity::Iface',
    'Entity::NetappAggregate',
    'Entity::Component::Puppetagent2',
    'Entity::Component::Puppetmaster2',
    'Entity::Component::Kanopyacollector1',
    'Entity::Connector::Sco',
    'Entity::Connector::MockMonitor',
    'Entity::Component::Kanopyaworkflow0',
    'Entity::Billinglimit',
    'Entity::ServiceProvider',
    'Entity::Host::Hypervisor',
    'Entity::Host::VirtualMachine',
    'Entity::Host::Hypervisor::Opennebula3Hypervisor',
    'Entity::Host::VirtualMachine::Opennebula3Vm',
    'Entity::Host::Hypervisor::Opennebula3Hypervisor::Opennebula3KvmHypervisor',
    'Entity::Host::Hypervisor::Opennebula3Hypervisor::Opennebula3XenHypervisor',
    'Entity::Component::Mailnotifier0',
    'Entity::Host::VirtualMachine::Opennebula3Vm::Opennebula3KvmVm',
    'Entity::ServiceTemplate',
    'Entity::Policy',
    'Entity::Operation',
    'Entity::Workflow',
    'Entity::Host::Hypervisor::Vsphere5Hypervisor',
    'Entity::Host::VirtualMachine::Vsphere5Vm',
    'Entity::Component::Vsphere5'
);

sub registerClassTypes {
    for my $class_type (@classes) {
        ClassType->new(class_type => $class_type);
    }
}

sub registerUsers {
    my %args = @_;
    my $admin_group;

    my $groups = [
        { name    => 'Entity',
          type    => 'Entity',
          desc    => 'Entity master group containing all entities',
          system  => 1 },
        { name    => 'Administrator',
          type    => 'User',
          desc    => 'Administrator group',
          profile => [ 'Administrator', 'administrator profile' ] },
        { name    => 'User',
          type    => 'User',
          desc    => 'User master group containing all users',
          system  => 1 },
        { name    => 'Processormodel',
          type    => 'Processormodel',
          desc    => 'Processormodel master group containing all processor models',
          system  => 1 },
        { name    => 'Hostmodel',
          type    => 'Hostmodel',
          desc    => 'Hostmodel master group containing all host models',
          system  => 1 },
        { name    => 'Host',
          type    => 'Host',
          desc    => 'Host master group containing all hosts',
          system  => 1 },
        { name    => 'ServiceProvider',
          type    => 'ServiceProvider',
          desc    => 'ServiceProvider master group containing all service providers',
          system  => 1,
          methods => [ 'getServiceProfile', 'create' ] },
        { name    => 'Cluster',
          type    => 'Cluster',
          desc    => 'Cluster master group containing all clusters',
          system  => 1 },
        { name    => 'Kernel',
          type    => 'Kernel',
          desc    => 'Kernel master group containing all kernels',
          system  => 1 },
        { name    => 'Systemimage',
          type    => 'Systemimage',
          desc    => 'Systemimage master group containing all system images',
          system  => 1 },
        { name    => 'Operationtype',
          type    => 'Operationtype',
          desc    => 'Operationtype master group containing all operations',
          system  => 1 },
        { name    => 'Masterimage',
          type    => 'Masterimage',
          desc    => 'Masterimage master group containing all master images',
          system  => 1 },
        { name    => 'Component',
          type    => 'Component',
          desc    => 'Component group containing all components',
          system  => 0,
          methods => [ 'getHostType', 'getPolicyParams', 'getDiskType', 'getExportType' ] },
        { name    => 'Connector',
          type    => 'Connector',
          desc    => 'Connector group containing all connectors',
          system  => 0 },
        { name    => 'Gp',
          type    => 'Gp',
          desc    => 'Groups master group containing all groups',
          system  => 1 },
        { name    => 'Admin',
          type    => 'User',
          desc    => 'Privileged users for administration tasks',
          system  => 1,
          profile => [ 'Super Admin', 'God profile : full access to the user interface.' ] },
        { name    => 'ServiceDeveloper',
          type    => 'User',
          desc    => 'Service developer group',
          system  => 0,
          profile => [ 'Services Developer', 'services dev profile' ] },
        { name    => 'Sales',
          type    => 'User',
          desc    => 'Sales group',
          system  => 0,
          profile => [ 'Sale', 'sale profile' ] },
        { name    => 'Customer',
          type    => 'User',
          desc    => 'Customer group',
          system  => 0,
          profile => [ 'Customer', 'customer profile' ] }
    ];

    for my $group (@{$groups}) {
        my $gp = Entity::Gp->new(
            gp_name   => $group->{name},
            gp_desc   => $group->{desc},
            gp_system => $group->{system} || 0,
            gp_type   => $group->{type}
        );

        if ($group->{name} eq 'Administrator') {
            $admin_group = $gp;
        }

        if (defined ($group->{methods})) {
            for my $method (@{$group->{methods}}) {
                Entityright->new(
                    entityright_consumed_id => $gp->id,
                    entityright_consumer_id => $admin_group->id,
                    entityright_method      => $method
                );
            }
        }

        if (defined ($group->{profile})) {
            my $prof = Profile->new(profile_name => $group->{profile}->[0],
                                    profile_desc => $group->{profile}->[1]);

            $prof->{_dbix}->profile_gps->create( {
                profile_id => $prof->id,
                gp_id      => $gp->id
            } );
        }
    }

    my $admin_user = Entity::User->new(
                         user_system       => 1,
                         user_login        => "admin",
                         user_password     => $args{admin_password},
                         user_firstname    => 'Kanopya',
                         user_lastname     => 'Administrator',
                         user_email        => 'dev@hederatech.com',
                         user_creationdate => today(),
                         user_desc         => 'God user for administrative tasks.'
                     );

    my $admin_profile = Profile->find(hash => { profile_name => 'Super Admin' });

    UserProfile->new(
        user_id    => $admin_user->id,
        profile_id => $admin_profile->id
    );

    my $executor_user = Entity::User->new(
        user_system       => 1,
        user_login        => "executor",
        user_password     => $args{admin_password},
        user_firstname    => 'Kanopya',
        user_lastname     => 'Executor',
        user_email        => 'dev@hederatech.com',
        user_creationdate => today(),
        user_desc         => 'User used by executor'
    );

    UserProfile->new(
        user_id    => $executor_user->id,
        profile_id => $admin_profile->id
    );

    $admin_group->appendEntity(entity => $admin_user);
    $admin_group->appendEntity(entity => $executor_user);
}

sub registerKernels {
    my %args = @_;

    my @kernels = (
        [ '2.6.32.33', '2.6.32.33', 'Debian generic kernel' ],
        [ '2.6.32-5-xen-amd64' , '2.6.32-5-xen-amd64', 'Kernel for Xen hypervisors' ],
        [ '3.2.6-xenvm', '3.2.6-xenvm', 'Kernel for xen virtual machines' ],
        [ '2.6.32-279.5.1.el6.x86_64', '2.6.32-279.5.1.el6.x86_64', 'Kernel for KVM hypervisors' ]
    );

    for my $kernel (@kernels) {
        Entity::Kernel->new(
            kernel_name    => $kernel->[0],
            kernel_version => $kernel->[1],
            kernel_desc    => $kernel->[2]
        );
    }
}

sub registerProcessorModels {
    my %args = @_;

    my $models = [
        {
            processor  => [ 'Generic', 'Generic', 1, 1.0, 1, 1,1 , 1 ],
            hostmodels => [
                [ 'Generic', 'Generic', 'Generic', 1, 1, 20, 1, 1 ]
            ]
        },
        {
            processor  => [ 'Intel', 'Atom 330', 2, 1.6, 1, 8, 1, 0 ],
            hostmodels => [
                [ 'Intel', 'DG945GCLF2', '945GC', 1, 42, 1, 1, 2 ],
                [ 'Asus', 'AT3GC-I', '945GC', 1, 42, 1, 1, 2, ],
                [ 'Asus', 'AT3N7A-I', 'NVIDIA ION', 1, 40, 1, 2, 4 ],
                [ 'J&W', 'MINIX ATOM330', '945GC', 1, 46, 1, 1, 2 ],
            ]
        },
        {
            processor  => [ 'Intel', 'Atom D510', 2, 1.66, 1, 13, 1, 0 ],
            hostmodels => [
                [ 'Gigabyte', 'GA-D510UD', 'INTEL NM10', 1, 26, 1, 2, 4 ],
                [ 'Intel', 'D510MO', 'INTEL NM10', 1, 21, 1, 2, 4 ],
            ]
        },
        {
            processor  => [ 'VIA Nano', 'L2200', 2, 1.6, 1, 13, 1, 0 ],
            hostmodels => [
                [ 'Via', 'VB8001', 'VIA CN896', 1, 17, 1, 2, 4 ],
            ]
        },
        {
            processor  => [ 'Intel', 'i3-330', 2, 2.1, 3, 35, 1, 1 ]
        },
        {
            processor  => [ 'Intel', 'i5-430', 2, 2.4, 3, 35, 1, 1 ]
        },
        {
            processor  => [ 'Intel', 'i7-640M', 2, 2.8, 4, 35, 1, 1 ]
        },
        {
            processor  => [ 'Intel', 'i7-720QM', 4, 1.6, 6, 45, 1, 1 ]
        },
        {
            processor  => [ 'AMD', 'Ontario', 2, 1.6, 1, 9, 1, 1 ],
            hostmodels => [
                [ 'Jetway', 'JNF81', 'Hudson E1', 1, 17, 2, 2, 8 ]
            ]
        },
        {
            processor => [ 'AMD', 'G-T56N', 2, 1.6, 1, 18, 1, 1 ]
        },
        {
            hostmodels => [
                [ 'IEI', 'Kino HM551', 'Intel HM55', 1, 32, 2, 2, 8 ]
            ]
        }
    ];

    for $model (@{$models}) {
        my $processor;
        if (defined ($model->{processor})) {
            my @proc = @{$model->{processor}};
            $processor = Entity::Processormodel->new(
                             processormodel_brand       => $proc[0],
                             processormodel_name        => $proc[1],
                             processormodel_core_num    => $proc[2],
                             processormodel_clock_speed => $proc[3],
                             processormodel_l2_cache    => $proc[4],
                             processormodel_max_tdp     => $proc[5],
                             processormodel_64bits      => $proc[6],
                             processormodel_virtsupport => $proc[7]
                         );
        }

        if (defined ($model->{hostmodels})) {
            for my $hostmodel (@{$model->{hostmodels}}) {
                Entity::Hostmodel->new(
                    hostmodel_brand         => $hostmodel->[0],
                    hostmodel_name          => $hostmodel->[1],
                    hostmodel_chipset       => $hostmodel->[2],
                    hostmodel_processor_num => $hostmodel->[3],
                    hostmodel_consumption   => $hostmodel->[4],
                    hostmodel_iface_num     => $hostmodel->[5],
                    hostmodel_ram_slot_num  => $hostmodel->[6],
                    hostmodel_ram_max       => $hostmodel->[7],
                    processormodel_id       => defined ($processor) ? $processor->id : undef
                );
            }
        }
    }
}

sub registerOperations {
    my %args = @_;

    my $operations = [
        [ 'AddHost', 'Activating a host' ],
        [ 'RemoveHost', 'Removing host' ], 
        [ 'ActivateHost', 'Activating a host' ],
        [ 'DeactivateHost', 'Desactivating host' ],
        [ 'AddCluster', 'Instanciating new service' ],
        [ 'RemoveCluster', 'Removing service' ],
        [ 'ActivateCluster', 'Activating a service' ],
        [ 'DeactivateCluster', 'Deactivating service' ],
        [ 'StopCluster', 'Stopping service' ],
        [ 'CloneSystemimage' ],
        [ 'RemoveSystemimage', 'Removing system image' ],
        [ 'StopNode', 'Stopping node' ],
        [ 'PreStartNode', 'Configuring node addition' ],
        [ 'StartNode', 'Starting new node' ],
        [ 'PreStopNode', 'Configuring node removal' ],
        [ 'PostStopNode', 'Finalizing node removal' ],
        [ 'PostStartNode', 'Finalizing node addition' ],
        [ 'InstallComponentOnSystemImage' ],
        [ 'DeployComponent', 'Deploying component' ],
        [ 'CreateDisk', 'Creating new disk' ],
        [ 'CreateExport', 'Exporting disk' ], 
        [ 'ForceStopCluster', 'Force service stopping' ],
        [ 'KanopyaMaintenance' ],
        [ 'MigrateHost', 'Migrating node' ],
        [ 'RemoveDisk' ],
        [ 'RemoveExport' ],
        [ 'DeployMasterimage', 'Deploying master image' ],
        [ 'RemoveMasterimage', 'Removing master image' ], 
        [ 'AddNode', 'Preparing a new node' ],
        [ 'ScaleCpuHost', 'Scaling node cpu' ],
        [ 'ScaleMemoryHost', 'Scaling node memory' ],
        [ 'CancelWorkflow', 'Canceling wokflow' ],  
        [ 'LaunchSCOWorkflow' ],
        [ 'UpdatePuppetCluster' ],
        [ 'UpdateComponent' ],
        [ 'LaunchScaleInWorkflow', 'Configuring scale in node' ],
        [ 'LaunchOptimiaasWorkflow' ],
        [ 'ProcessRule', 'Processing triggered rule' ],
        [ 'ResubmitNode', 'Resubmit a virtual machine to the IAAS' ],
        [ 'RelieveHypervisor', 'Relieve the hypervisor by migrating one VM' ],
        [ 'Synchronize', 'Synchronize a component' ]
    ];

    for my $operation (@{$operations}) {
        Operationtype->new(
            operationtype_name  => $operation->[0],
            operationtype_label => $operation->[1] || ''
        );
    }
}

sub registerComponents {
    my %args = @_;

    my $components = [
        [ 'Lvm', '2', 'Storage' ],
        [ 'Apache', '2', 'Webserver', '/templates/components/apache2' ],  
        [ 'Iscsitarget', '1', 'Export', '/templates/components/ietd' ],
        [ 'Openiscsi', '2', 'Exportclient' ],
        [ 'Dhcpd', '3', 'Dhcpserver', '/templates/components/dhcpd' ],
        [ 'Atftpd', '0', 'Tftpserver' ], 
        [ 'Snmpd', '5', 'Monitoragent', '/templates/components/snmpd' ],
        [ 'Nfsd', '3', 'Export', '/templates/components/nfsd3' ],
        [ 'Linux', '0', 'System', '/templates/components/linux' ],
        [ 'Mysql', '5', 'DBMS' ],
        [ 'Syslogng', '3', 'Logger' ],  
        [ 'Iptables', '1', 'Firewall' ],
        [ 'Openldap', '1', 'Annuary' ],
        [ 'Opennebula', '3', 'Cloudmanager' ],
        [ 'Physicalhoster', '0', 'Cloudmanager' ],
        [ 'Fileimagemanager', '0', 'Storage' ],
        [ 'Puppetagent', '2', 'Configurationagent' ],   
        [ 'Puppetmaster', '2', 'Configurationserver' ], 
        [ 'Kanopyacollector', '1', 'Collectormanager' ],
        [ 'Keepalived', '1', 'LoadBalancer' ],
        [ 'Kanopyaworkflow', '0', 'Workflowmanager' ], 
        [ 'Mailnotifier', '0', 'Notificationmanager' ],
        [ 'Memcached', '1', 'Cache' ],
        [ 'Php', '5', 'Lib' ],
        [ 'Vsphere', '5', 'Cloudmanager' ],
    ];

    for my $component_type (@{$components}) {
        my $type = ComponentType->new(
            component_name     => $component_type->[0],
            component_version  => $component_type->[1],
            component_category => $component_type->[2],
        );
        if (defined $component_type->[3]) {
            my $template_name = lc $component_type->[0];
            ComponentTemplate->new(
                component_template_name      => lc($component_type->[0]),
                component_template_directory => $component_type->[3],
                component_type_id            => $type->id
            );
        }
    }

    my $connectors = [
        [ 'ActiveDirectory', '1', 'DirectoryServiceManager' ],
        [ 'Scom', '1', 'Collectormanager' ],      
        [ 'UcsManager', '1', 'Cloudmanager' ],    
        [ 'NetappLunManager', '1', 'Storage' ],   
        [ 'NetappVolumeManager', '1', 'Storage' ],
        [ 'NetappLunManager', '1', 'Export' ],   
        [ 'NetappVolumeManager', '1', 'Export' ],
        [ 'Sco', 1, 'WorkflowManager' ],
        [ 'MockMonitor', '1', 'Collectormanager' ]
    ];

    for my $connector_type (@{$connectors}) {
        ConnectorType->new(
            connector_name     => $connector_type->[0],
            connector_version  => $connector_type->[1],
            connector_category => $connector_type->[2]
        );
    }
}

sub registerInterfaceRoles {
    my %args = @_;

    my @roles = ( [ 'admin', 'Network used for system administration' ],
                  [ 'public', 'Network used for public access' ],
                  [ 'vms', 'Network used for virtual machines' ],
                  [ 'private', 'Private network' ] );

    for my $role (@roles) {
        Entity::InterfaceRole->new(
            interface_role_name => $role->[0]
        )->setComment(comment => $role->[1]);
    }
}

sub registerIndicators {
    my %args = @_;

    my $indicators = [
        {
            set => {
                name      => 'mem',
                provider  => 'SnmpProvider',
                type      => 'GAUGE',
                component => undef,
                max       => 'Total',
                tableoid  => undef,
                indexoid  => undef
            },
            indicators => [
                [ 'Total', '.1.3.6.1.4.1.2021.4.5.0', undef, undef, 'FFFF0066', 'KBytes', undef ],
                [ 'Avail', '.1.3.6.1.4.1.2021.4.6.0', undef, undef, '00FF0066', 'KBytes', undef ],
                [ 'Buffered', '.1.3.6.1.4.1.2021.4.14.0', undef, undef, '0000FF66', 'KBytes', undef ],
                [ 'Cached', '.1.3.6.1.4.1.2021.4.15.0', undef, undef, 'FF000066', 'KBytes', undef ],  
            ]
        },
        {
            set => {
                name      => 'cpu',
                provider  => 'SnmpProvider',
                type      => 'COUNTER',
                component => undef,
                max       => 'User+Idle+Wait+Nice+Syst+Kernel+Interrupt',
                tableoid  => undef,
                indexoid  => undef
            },
            indicators => [
                [ 'User', '.1.3.6.1.4.1.2021.11.50.0', undef, undef, '0000FF66', '%', undef ],
                [ 'Wait', '.1.3.6.1.4.1.2021.11.54.0', undef, undef, 'FF000066', '%', undef ],  
                [ 'Nice', '.1.3.6.1.4.1.2021.11.51.0', undef, undef, 'FFFF0066', '%', undef ],  
                [ 'Syst', '.1.3.6.1.4.1.2021.11.52.0', undef, undef, '00FFFF66', '%', undef ],  
                [ 'Kernel', '.1.3.6.1.4.1.2021.11.55.0', undef, undef, 'FF00FF66', '%', undef ],
                [ 'Interrupt', '.1.3.6.1.4.1.2021.11.56.0', undef, undef, '66666666', '%', undef ],
                [ 'Idle', '.1.3.6.1.4.1.2021.11.53.0', undef, undef, '00FF0066', '%', undef ],
            ]
        },
        {
            set => {
                name      => 'apache_stats',
                provider  => 'ApacheProvider',
                type      => 'DERIVE',
                component => 'Apache',
            },
            indicators => [
                [ 'ReqPerSec','Total Accesses', 0, undef, '0000FF99', undef, undef ],
            ]
        },
        {
            set => {
                name      => 'apache_workers',
                provider  => 'ApacheProvider',
                type      => 'GAUGE',
                component => 'Apache',
            },
            indicators => [
                [ 'IdleWorkers','IdleWorkers', undef, undef, '00FF0099', undef, undef ],
                [ 'BusyWorkers','BusyWorkers', undef, undef, 'FF000099', undef, undef ],
            ]
        },
        {
            set => {
                name      => 'scom',
                provider  => 'External',
                type      => 'GAUGE',
            },
            indicators => [
                [ 'RAM free', 'Memory/Available MBytes', undef, undef, 'FF000099', 'MBytes', undef ],
                [ 'RAM pool paged', 'Memory/Pool Paged Bytes', undef, undef, 'FF000099', 'Bytes', undef ],
                [ 'RAM used', 'Memory/PercentMemoryUsed', undef, undef, 'FF000099', '%', undef ],
                [ 'CPU used', 'Processor/% Processor Time', undef, undef, 'FF000099', '%', undef ],
                [ 'CPU Queue Length', 'System/Processor Queue Length', undef, undef, 'FF000099', 'process', undef ],
                [ 'Disk idle time', 'LogicalDisk/% Idle Time', undef, undef, 'FF000099', '%', undef ],
                [ 'Disk free space', 'LogicalDisk/% Free Space', undef, undef, 'FF000099', '%', undef ],
                [ 'Network used', 'Network Adapter/PercentBandwidthUsedTotal', undef, undef, 'FF000099', '%', undef ],
                [ 'Active Sessions', 'Terminal Services/Active Sessions', undef, undef, 'FF000099', 'sessions', undef ],
                [ 'RAM I/O', 'Memory/Pages/sec', undef, undef, 'FF000099', 'pages/sec', undef ],
            ]
        },
        {
            set => {
                name      => 'billing',
                provider  => 'KanopyaDatabaseProvider',
                type      => 'GAUGE',
            },
            indicators => [
                [ 'Cores', 'Number of charged cores', undef, undef, 'FF000099', 'Cores', undef ],
                [ 'Memory', 'Charged memory', undef, undef, 'FF000099', 'Bytes', undef ],
            ]
        },
        {
            set => {
                name      => 'diskIOTable',
                provider  => 'SnmpProvider',
                type      => 'COUNTER',
                tableoid  =>  '1.3.6.1.4.1.2021.13.15.1',
                indexoid  => 2
            },
            indicators => [
                [ 'bytesRead', 3, undef, undef, 'FF000099', undef, undef ],
                [ 'bytesWritten', 4, undef, undef, 'FF000099', undef, undef ],
            ]
        },
        {
            set => {
                name      => 'interfaces',
                provider  => 'SnmpProvider',
                type      => 'COUNTER',
                tableoid  =>  '1.3.6.1.2.1.2.2',
                indexoid  => 2
            },
            indicators => [
                [ 'ifInOctets', 10, undef, undef, 'FF000099', 'Octets/sec', undef ],
                [ 'ifOutOctets', 16, undef, undef, 'FF000099', 'Octets/sec', undef ],
                [ 'ifOutErrors', 20, undef, undef, 'FF000099', 'Packets|TU/sec', undef ],
                [ 'ifInErrors', 14, undef, undef, 'FF000099', 'Packets|TU/sec', undef ]
            ]
        },
        {
            set => {
                name     => 'vsphere_vm',
                provider => 'VsphereProvider',
                type     => 'GAUGE',
             },
            indicators => [
                [ 'vm_cpu_total', 'summary.config.numCpu', undef, undef, 'FF000099', 'Cores', undef ],
                [ 'vm_cpu_usage', 'summary.quickStats.overallCpuUsage', undef, undef, 'FF000099', 'MHz', undef ],
                [ 'vm_mem_total', 'summary.config.memorySizeMB', undef, undef, 'FF000099', 'MBytes', undef ],
                [ 'vm_mem_usage', 'summary.quickStats.hostMemoryUsage', undef, undef, 'FF000099', 'MBytes', undef ],
            ]
        },
        {
            set => {
                name     => 'vsphere_host',
                provider => 'VsphereProvider',
                type     => 'GAUGE',
             },
            indicators => [
                [ 'hv_cpu_total', 'summary.hardware.numCpuCores', undef, undef, 'FF000099', 'Cores', undef ],
                [ 'hv_cpu_usage', 'summary.quickStats.overallCpuUsage', undef, undef, 'FF000099', 'MHz', undef ],
                [ 'hv_mem_total', 'summary.hardware.memorySize', undef, undef, 'FF000099', 'Bytes', undef ],
                [ 'hv_mem_usage', 'summary.quickStats.overallMemoryUsage', undef, undef, 'FF000099', 'MBytes', undef ],
            ]
        }
    ];

    for my $set (@{$indicators}) {
        my %values = %{$set->{set}};
        my $indicatorset = Indicatorset->new(
            indicatorset_name      => $values{name},
            indicatorset_provider  => $values{provider},
            indicatorset_type      => $values{type},
            indicatorset_component => $values{component},
            indicatorset_max       => $values{max},
            indicatorset_tableoid  => $values{tableoid},
            indicatorset_indexoid  => $values{indexoid}
        );

        for my $indicator (@{$set->{indicators}}) {
            Indicator->new(
                indicator_name  => $indicator->[0],
                indicator_oid   => $indicator->[1],
                indicator_min   => $indicator->[2],
                indicator_max   => $indicator->[3],
                indicator_color => $indicator->[4],
                indicator_unit  => $indicator->[5],
                indicatorset_id => $indicatorset->id
            );
        }
    }
}

sub registerKanopyaMaster {
    my %args = @_;

    my $admin = Entity::User->find(hash => { user_login => "admin" });

    my $master_kernel = Entity::Kernel->find(hash => { });

    my $admin_cluster = Entity::ServiceProvider::Inside::Cluster->new(
                            cluster_name          => 'Kanopya',
                            cluster_desc          => 'Main Cluster hosting Administrator, Executor, Boot server and NAS',
                            cluster_type          => 0,
                            cluster_min_node      => 1,
                            cluster_max_node      => 1,
                            cluster_priority      => 500,
                            cluster_boot_policy   => '',
                            cluster_si_shared     => 0,
                            cluster_si_persistent => 0,
                            cluster_domainname    => $args{admin_domainname},
                            cluster_nameserver1   => '127.0.0.1',
                            cluster_nameserver2   => '127.0.0.1',
                            cluster_state         => 'up:' . time(),
                            cluster_basehostname  => 'kanopya_',
                            active                => 1,
                            user_id               => $admin->id,
                            kernel_id             => $master_kernel->id
                        );

    my $config = Kanopya::Config::get('executor');
    
    my $kanopya = Entity::ServiceProvider::Inside::Cluster->find(hash => {
                      cluster_name => "Kanopya"
                  } );

    $config->{cluster}->{bootserver} = $kanopya->id;
    $config->{cluster}->{executor} = $kanopya->id;
    $config->{cluster}->{monitor} = $kanopya->id;
    $config->{cluster}->{nas} = $kanopya->id;

    Kanopya::Config::set(subsystem => 'executor',
                         config    => $config);

    my $comp_group = Entity::Gp->find(hash => { gp_name => "Component" });

    my $components = [
        {
            name => 'Lvm2'
        },
        {
            name => 'Iscsitarget1'
        },
        {
            name => 'Fileimagemanager0'
        },
        {
            name => "Dhcpd3",
            conf => {
                dhcpd3_domain_name =>  "hedera-technology.com",
                dhcpd3_servername  => "node001"
            }
        },
        {
            name => "Atftpd0",
            conf => {
                atftpd0_options    => '--daemon --tftpd-timeout 300 --retry-timeout 5 --no-multicast --maxthread 100 --verbose=5',
                atftpd0_use_inetd  => 'FALSE',
                atftpd0_logfile    => '/var/log/atftpd.log',
                atftpd0_repository => '/tftp'
            }
        },
        {
            name => "Snmpd5",
            conf => {
                monitor_server_ip => $args{poolip_addr},
                snmpd_options     => '-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid'
            }
        },
        {
            name => "Nfsd3",
            conf => {
                nfsd3_need_gssd => 'no',
                nfsd3_rpcnfsdcount => 8,
                nfsd3_rpcnfsdpriority => 0,
                nfsd3_need_svcgssd => 'no'
            }
        },
        {
            name => "Syslogng3",
        },
        {
            name => "Puppetmaster2",
            conf => {
                puppetmaster2_options => ""
            }
        },
        {
            name => "Openiscsi2"
        },
        {
            name => "Physicalhoster0",
            manager => "host_manager"
        },
        {
            name => "Kanopyacollector1",
            conf => {
                kanopyacollector1_collect_frequency => 3600,
                kanopyacollector1_storage_time      => 86400
            }
        },
        {
            name => "Kanopyaworkflow0"
        },
        {
            name => "Linux0"
        },
        {
            name => "Mailnotifier0",
            manager => "notification_manager",
            conf => {
                smtp_server => "localhost"
            }
        }
    ];

    my $installed = { };
    for my $component (@{$components}) {
        my $class = "Entity::Component::" . $component->{name};
        my $version = chop($component->{name});
        my $name = $component->{name};
        my $component_type = ComponentType->search(hash => {
                                 component_name    => $name,
                                 component_version => $version
                             } );
        my $component_template;
        eval {
            $component_template = ComponentTemplate->find(hash => { component_template_name => lc $name })->id;
        };
        my $comp = $class->new(
            service_provider_id   => $admin_cluster->id,
            component_template_id => $component_template,
            defined ($component->{conf}) ? %{$component->{conf}} : ()
        );

        if (defined $component->{manager}) {
            ServiceProviderManager->new(
                service_provider_id => $admin_cluster->id,
                manager_type        => $component->{manager},
                manager_id          => $comp->id
            );
        }

        $installed->{$component->{name}} = $comp;
    }

    my $vg = Lvm2Vg->new(
        lvm2_id           => $installed->{"Lvm"}->id,
        lvm2_vg_name      => $args{kanopya_vg_name},
        lvm2_vg_freespace => $args{kanopya_vg_free_space},
        lvm2_vg_size      => $args{kanopya_vg_size}
    );

    $args{db}->resultset('Lvm2Pv')->create( {
        lvm2_vg_id   => $vg->id,
        lvm2_pv_name => $args{kanopya_pvs}->[0]
    } );

    $args{db}->resultset('Dhcpd3Subnet')->create( {
        dhcpd3_id             => $installed->{"Dhcpd"}->id,
        dhcpd3_subnet_net     => $args{ipv4_internal_network_ip},
        dhcpd3_subnet_mask    => $args{poolip_netmask},
        dhcpd3_subnet_gateway => $args{poolip_gateway}
    } );

    # Create the host for the Kanopya master
    my ( $sysname, $nodename, $release, $version, $machine ) = POSIX::uname();
    my $domain = $args{admin_domainname};
 
    my $date = today();
    my $year = $date->year;
    my $month = $date->month;

    if (length ($month) == 1) {
        $month = '0' . $month;
    }
   
    my $hostname = `hostname`;
    chomp($hostname);

    my $kanopya_initiator = "iqn.$year-$month."
        . join('.', reverse split(/\./, $domain)) . ':' . time();

    my $poolip = Entity::Poolip->new(
                     poolip_name    => "kanopya_admin",
                     poolip_addr    => $args{poolip_addr},
                     poolip_mask    => $args{poolip_mask},
                     poolip_netmask => $args{poolip_netmask},
                     poolip_gateway => $args{poolip_gateway}
                 );

    my $admin_network = Entity::Network->new(
                            network_name => "admin"
                        );

    my $admin_role = Entity::InterfaceRole->find(hash => { interface_role_name => "admin" });

    my $admin_interface = Entity::Interface->new(
                              interface_role_id   => $admin_role->id,
                              service_provider_id => $admin_cluster->id,
                              default_gateway  => 1
                          );

    $admin_interface->associateNetwork(network => $admin_network);

    NetworkPoolip->new(
        network_id => $admin_network->id,
        poolip_id  => $poolip->id
    );

    my $physical_hoster = Entity::Component::Physicalhoster0->find(hash => { });

    my $admin_host = Entity::Host->new(
                         host_manager_id    => $physical_hoster->id,
                         kernel_id          => $master_kernel->id,
                         host_serial_number => "",
                         host_desc          => "Admin host",
                         active             => 1,
                         host_initiatorname => $kanopya_initiator,
                         host_ram           => 0,
                         host_core          => 1,
                         host_hostname      => $hostname,
                         host_state         => "up:" . time(),
                         host_prev_state    => ""
                     );

    my $admin_iface = Entity::Iface->new(
                          iface_name     => $args{admin_interface},
                          iface_mac_addr => $args{mb_hw_address},
                          iface_pxe      => 0,
                          host_id        => $admin_host->id,
                          interface_id   => $admin_interface->id
                      );

    Ip->new(
        ip_addr   => $args{poolip_addr},
        poolip_id => $poolip->id,
        iface_id  => $admin_iface->id
    );

    Externalnode::Node->new(
        externalnode_hostname => $hostname,
        service_provider_id   => $admin_cluster->id,
        externalnode_state    => "disabled",
        inside_id             => $admin_cluster->id,
        host_id               => $admin_host->id,
        master_node           => 1,
        node_state            => "in." . time(),
        node_number           => 1
    );

    my $ehost = EEntity->new(entity => $admin_host);

    $admin_host->setAttr(name  => "host_core",
                         value => $ehost->getTotalCpu);

    $admin_host->setAttr(name  => "host_ram",
                         value => $ehost->getTotalMemory);

    $admin_host->save();
}

sub registerScopes {
    my %args = @_;

    my $scopes = [
        {
            name => "node",
            parameters => [
                ('ou_from', 'node_hostname')
            ]
        },
        {
            name => "service_provider",
            parameters => [
                ("service_provider_name", )
            ]
        },
    ];
    for my $scope (@{$scopes}) {
        my $sc = Scope->new(
            scope_name => $scope->{name}
        );
        for my $parameter (@{$scope->{parameters}}) {
            ScopeParameter->new(
                scope_parameter_name => $parameter,
                scope_id             => $sc->id
            );
        }
    }
}

sub populate_workflow_def {
    my $wf_manager_component_type_id = ComponentType->find( hash => {
                                           component_category => 'Workflowmanager'
                                       } )->id;

    my $kanopya_wf_manager           = Entity::Component->find( hash => {
                                           component_type_id => $wf_manager_component_type_id,
                                           service_provider_id => Kanopya::Config::get('executor')->{cluster}->{executor}
                                       } );

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

    # RelieveHypervisor workflow def
    my $relieve_hypervisor_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'RelieveHypervisor',
        params => {
            internal => {
                scope_id => 1,
            },
            automatic => {
                context => { host => undef },
            },
        }
    );
    my $relieve_hypervisor_op_id  = Operationtype->find( hash => { operationtype_name => 'RelieveHypervisor' })->id;
    $relieve_hypervisor_wf->addStep( operationtype_id => $resubmit_node_op_id );
    $relieve_hypervisor_wf->addStep( operationtype_id => $migrate_op_id );
}

sub populate_policies {
    my %policies = ();
    my $executor = Kanopya::Config::get("executor")->{cluster}->{executor};

    # hosting
    my $type_id = ComponentType->find(hash => { component_name => 'Physicalhoster' })->id;

    my $physicalhoster = Entity::Component->find( hash => {
                             component_type_id   => $type_id,
                             service_provider_id => $executor
                         } );

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
    my $lvm = Entity::Component->find( hash => { component_type_id => $lvm_type_id, service_provider_id => $executor } );
    my $iscsit_type_id = ComponentType->find(hash => { component_name => 'Iscsitarget' })->id;
    my $iscsitarget = Entity::Component->find( hash => { component_type_id => $iscsit_type_id, service_provider_id => $executor } );

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

sub login {
    my $config = Kanopya::Config::get("libkanopya");
    my $god_mode = $config->{dbconf}->{god_mode};

    # Activate god mode before the administrator loads it config
    $config->{dbconf}->{god_mode} = "1";
    Kanopya::Config::set(subsystem => "libkanopya", config => $config);

    Administrator::_connectdb();

    # Restore the config to its original state, the administrator keeps its old one
    if (defined $god_mode) {
        $config->{dbconf}->{god_mode} = $god_mode;
    } else {
        delete $config->{dbconf}->{god_mode};
    }
    Kanopya::Config::set(subsystem => "libkanopya", config => $config);

    $ENV{EID} = 0;
}

sub populateDB {
    my %args = @_;

    login();

    my $adm = Administrator->new();
    $args{db} = $adm->{db};

    registerClassTypes(%args);
    registerUsers(%args);

    registerKernels(%args);
    registerProcessorModels(%args);
    registerOperations(%args);
    registerComponents(%args);
    registerInterfaceRoles(%args);
    registerIndicators(%args);
    registerKanopyaMaster(%args);
    registerScopes(%args);

    populate_workflow_def();

    my $policies = populate_policies();
    populate_servicetemplates($policies);
}

1;
