function serializeDateTime(datetime) {
    datetime    = datetime.split(' ');
    var date    = (datetime[0]).split('/');
    var time    = (datetime[1]).split(':');
    var d       = new Date(date[2], date[0] - 1, date[1], time[0], time[1]);
    return d.getTime();
}

var policies = {
    hosting: {
        policy_name : {
            label        : 'Policy name',
            type         : 'text',
            is_mandatory : 1,
        },
        policy_desc : {
            label        : 'Policy description',
            type         : 'textarea',
            is_mandatory : 0,
        },
        policy_type : {
            label        : 'Policy type',
            type         : 'hidden',
            value        : 'hosting',
            is_mandatory : 1,
        },
        host_provider_id : {
            label        : 'Host provider',
            type         : 'select',
            is_mandatory : 1,
            pattern      : '^[1-9][0-9]*$',
            entity       : 'serviceprovider',
            depends      : [ 'host_manager_id' ],
        },
        host_manager_id : {
            label        : "Host type",
            type         : 'select',
            is_mandatory : 1,
            pattern      : '^[1-9][0-9]*$',
            entity       : 'component',
            category     : 'Cloudmanager',
            parent       : 'host_provider_id',
            display_func : 'getHostType',
            params       : {
                func : 'getPolicyParams',
                args : { policy_type: 'hosting' },
            },
        },
    },
    storage: {
        policy_name : {
            label        : 'Policy name',
            type         : 'text',
            is_mandatory : 1,
        },
        policy_desc : {
            label        : 'Policy description',
            type         : 'textarea',
            is_mandatory : 0,
        },
        policy_type : {
            label        : 'Policy type',
            type         : 'hidden',
            value        : 'storage',
            is_mandatory : 1,
        },
        storage_provider_id : {
            label        : 'Data store',
            type         : 'select',
            is_mandatory : 1,
            pattern      : '^[1-9][0-9]*$',
            entity       : 'serviceprovider',
            depends      : [ 'disk_manager_id', 'export_manager_id' ],
        },
        disk_manager_id : {
            label        : "Storage format",
            type         : 'select',
            is_mandatory : 1,
            pattern      : '^[1-9][0-9]*$',
            entity       : 'component',
            category     : 'Storage',
            parent       : 'storage_provider_id',
            display_func : 'getDiskType',
            params       : {
                func : 'getPolicyParams',
                args : { policy_type: 'storage' },
            },
        },
        export_manager_id : {
            label        : "Export protocol",
            type         : 'select',
            is_mandatory : 1,
            pattern      : '^[1-9][0-9]*$',
            entity       : 'component',
            category     : 'Export',
            parent       : 'storage_provider_id',
            display_func : 'getExportType',
        },
    },
    network: {
        policy_name : {
            step         : 'Policy',
            label        : 'Policy name',
            type         : 'text',
            is_mandatory : 1,
        },
        policy_desc : {
            step         : 'Policy',
            label        : 'Policy description',
            type         : 'textarea',
            is_mandatory : 0,
        },
        policy_type : {
            step         : 'Policy',
            label        : 'Policy type',
            type         : 'hidden',
            value        : 'network',
            is_mandatory : 1,
        },
        cluster_domainname : {
            step         : 'Policy',
            label        : 'Domain name',
            type         : 'text',
        },
        cluster_nameserver1 : {
            step         : 'Policy',
            label        : 'Name server 1',
            type         : 'text',
        },
        cluster_nameserver2 : {
            step         : 'Policy',
            label        : 'Name server 2',
            type         : 'text',
        },
        network_interface : {
            step         : 'Interfaces',
            type         : 'composite',
            set          : 'interfaces',
            add_label    : 'Add a network interface',
        },
        interface_role : {
            label        : 'Interface role',
            type         : 'select',
            entity       : 'interfacerole',
            display      : 'interface_role_name',
            composite    : 'network_interface',
        },
        interface_networks : {
            label        : 'Network',
            type         : 'select',
            entity       : 'network',
            display      : 'network_name',
            composite    : 'network_interface',
        },
    },
    system: {
        policy_name : {
            step         : 'Policy',
            label        : 'Policy name',
            type         : 'text',
            is_mandatory : 1,
        },
        policy_desc : {
            step         : 'Policy',
            label        : 'Policy description',
            type         : 'textarea',
            is_mandatory : 0,
        },
        policy_type : {
            step         : 'Policy',
            label        : 'Policy type',
            type         : 'hidden',
            value        : 'system',
            is_mandatory : 1,
        },
        masterimage_id : {
            step         : 'Policy',
            label        : 'Master image',
            type         : 'select',
            entity       : 'masterimage',
            display      : 'masterimage_name',
        },
        kernel_id : {
            step         : 'Policy',
            label        : 'Kernel',
            type         : 'select',
            entity       : 'kernel',
            display      : 'kernel_name',
        },
        systemimage_size : {
            step         : 'Policy',
            label        : 'System image size',
            type         : 'text',
        },
        cluster_si_shared : {
            step         : 'Policy',
            label        : 'System image shared',
            type         : 'checkbox',
        },
        cluster_si_persistent : {
            step         : 'Policy',
            label        : 'Persistent system images',
            type         : 'checkbox',
        },
        component_type : {
            step         : 'Components',
            label        : 'Component type',
            type         : 'select',
            entity       : 'componenttype',
            display      : 'component_name',
            set          : 'components',
            add_label    : 'Add a component',
        },
    },
    scalability: {
        policy_name : {
            label        : 'Policy name',
            type         : 'text',
            is_mandatory : 1,
        },
        policy_desc : {
            label        : 'Policy description',
            type         : 'textarea',
            is_mandatory : 0,
        },
        policy_type : {
            label        : 'Policy type',
            type         : 'hidden',
            value        : 'scalability',
            is_mandatory : 1,
        },
        cluster_min_node : {
            label        : 'Minimum node number',
            type         : 'text',
        },
        cluster_max_node : {
            label        : 'Maximum node number',
            type         : 'text',
        },
        cluster_priority : {
            label        : 'Cluster priority',
            type         : 'text',
        },
    },
//    billing: {
//        policy_name     : {
//            step        : 'Policy',
//            label       : 'Policy name',
//            type        : 'text',
//            is_mandatory: 1
//        },
//        policy_desc     : {
//            step        : 'Policy',
//            label       : 'Policy description',
//            type        : 'textarea',
//            is_mandatory: 0
//        },
//        policy_type     : {
//            step        : 'Policy',
//            label       : 'Policy type',
//            type        : 'hidden',
//            value       : 'billing',
//            is_mandatory: 1
//        },
//        billing_limits  : {
//            step        : 'Limits',
//            type        : 'composite',
//            set         : 'limits',
//            add_label   : 'Add a limit',
//            is_mandatory: 1
//        },
//        limit_start     : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'datetime',
//            label       : 'Start',
//            is_mandatory: 1,
//            serialize   : serializeDateTime
//        },
//        limit_end       : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'datetime',
//            label       : 'End',
//            is_mandatory: 1,
//            serialize   : serializeDateTime
//        },
//        limit_type      : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'select',
//            label       : 'Type',
//            options     : {
//                'cpu' : 'cpu',
//                'ram' : 'ram'
//            },
//            is_mandatory: 1
//        },
//        limit_soft      : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'checkbox',
//            label       : 'Soft limit ?',
//            is_mandatory: 1
//        },
//        limit_value     : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'text',
//            label       : 'Value',
//            is_mandatory: 1
//        },
//        limit_repeat    : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'select',
//            label       : 'Repeat',
//            options     : ['Daily'],
//            is_mandatory: 0
//        },
//        limit_repeat_start  : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'time',
//            label       : 'Repeat Start',
//            is_mandatory: 0
//        },
//        limit_repeat_end    : {
//            step        : 'Limits',
//            composite   : 'billing_limits',
//            type        : 'time',
//            label       : 'Repeat End',
//            is_mandatory: 0
//        }
//    }
}
