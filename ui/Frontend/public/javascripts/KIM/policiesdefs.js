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
            label        : 'Service provider',
            type         : 'select',
            is_mandatory : 1,
            entity       : 'serviceprovider',
            depends      : [ 'host_manager_id' ],
        },
        host_manager_id : {
            label        : "Host manager",
            type         : 'select',
            is_mandatory : 1,
            entity       : 'component',
            category     : 'Cloudmanager',
            parent       : 'host_provider_id',
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
            label        : 'Service provider',
            type         : 'select',
            is_mandatory : 1,
            entity       : 'serviceprovider',
            depends      : [ 'disk_manager_id', 'export_manager_id' ],
        },
        disk_manager_id : {
            label        : "Disk manager",
            type         : 'select',
            is_mandatory : 1,
            entity       : 'component',
            category     : 'Storage',
            parent       : 'storage_provider_id',
            params       : {
                func : 'getPolicyParams',
                args : { policy_type: 'storage' },
            },
        },
        export_manager_id : {
            label        : "Export manager",
            type         : 'select',
            is_mandatory : 1,
            entity       : 'component',
            category     : 'Export',
            parent       : 'storage_provider_id',
        },
    },
    network: {
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
            value        : 'network',
            is_mandatory : 1,
        },
        cluster_domainname : {
            label        : 'Domain name',
            type         : 'text',
            is_mandatory : 1,
        },
        cluster_nameserver1 : {
            label        : 'Name server 1',
            type         : 'text',
            is_mandatory : 1,
        },
        cluster_nameserver2 : {
            label        : 'Name server 2',
            type         : 'text',
            is_mandatory : 1,
        },
    },
    system: {
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
            value        : 'system',
            is_mandatory : 1,
        },
        masterimage_id : {
            label        : 'Master image',
            type         : 'select',
            entity       : 'masterimage',
            display      : 'masterimage_name',
            is_mandatory : 1,
        },
        kernel_id : {
            label        : 'Kernel',
            type         : 'select',
            entity       : 'kernel',
            display      : 'kernel_name',
            is_mandatory : 1,
        },
        systemimage_size : {
            label        : 'System image size',
            type         : 'text',
            is_mandatory : 1,
        },
        cluster_si_shared : {
            label        : 'System image shared',
            type         : 'checkbox',
            is_mandatory : 1,
        },
        cluster_si_persistent : {
            label        : 'Persistent system images',
            type         : 'checkbox',
            is_mandatory : 1,
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
            is_mandatory : 1,
        },
        cluster_max_node : {
            label        : 'Maximum node number',
            type         : 'text',
            is_mandatory : 1,
        },
        cluster_priority : {
            label        : 'Cluster priority',
            type         : 'text',
            is_mandatory : 1,
        },
    },
}
