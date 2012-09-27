require('common/general.js');
require('kanopyaformwizard.js');

var ComponentsFields = {
    'linux0' : { 
        'displayed': [],
        'relations': { 'linux0s_mount': ['linux0_mount_device',
                                         'linux0_mount_point',
                                         'linux0_mount_filesystem',
                                         'linux0_mount_options',
                                         'linux0_mount_dumpfreq',
                                         'linux0_mount_passnum' ]}
    },
    'snmpd5' : { 
        'displayed': ['monitor_server_ip',
                      'snmpd_options'],
        'relations': {}
    },
    'puppetagent2': { 
        'displayed': ['puppetagent2_mode',
                      'puppetagent2_masterip',
                      'puppetagent2_masterfqdn', 
                      'puppetagent2_options'],
        'relations': {}
    },
    'opennebula3': {
        'displayed': ['host_monitoring_interval',
                      'vm_polling_interval',
                      'port',
                      'hypervisor',
                      'debug_level',
                      'overcommitment_cpu_factor',
                      'overcommitment_memory_factor'],
        'relations': { 'opennebula3_repositories': ['repository_name',
                                                    'container_access_id']}
    },
    'mailnotifier0': {
        'displayed': ['smtp_server',
                      'smtp_login',
                      'smtp_passwd',
                      'use_ssl'],
        'relations': {},
    },
    'lvm2' : { 
        'displayed': [],
        'relations': { 'lvm2_vgs': ['lvm2_vg_name',
                                    'lvm2_vg_freespace',
                                    'lvm2_vg_size']}
    },
    'puppetmaster2': {
        'displayed': ['puppetmaster2_options'],
        'relations': {},
    },
    
    
    /*

    'memcached1'   : ['memcached1_port'],
    'apache2'      : ['apache2_serverroot','apache2_loglevel',
                      'apache2_ports','apache2_sslports'],
    'syslogng3'    : [],
    'php5'         : ['php5_session_handler','php5_session_path'],
    'mailnotifier0' : ['smtp_server','smtp_login','smtp_passwd','use_ssl'],
    'keepalived1'   : ['notification_email','notification_email_from',
                        'smtp_server','smtp_connect_timeout',
                        'daemon_method','lvs_id'],      
    'mysql5'        : ['mysql5_bindaddress','mysql5_port','mysql5_datadir'] ,
    
    */
};

function getComponentTypes() {
    return {
        'Linux'        : 'linux0',
        'Mailnotifier' : 'mailnotifier0',
        'Puppetagent'  : 'puppetagent2',
        'Puppetmaster' : 'puppetmaster2',
        'Snmpd'        : 'snmpd5',
        'Apache'       : 'apache2',
        'Syslogng'     : 'syslogng3',
        'Memcached'    : 'memcached1',
        'Php'          : 'php5',
        'Mailnotifier' : 'mailnotifier0',
        'Keepalived'   : 'keepalived1',
        'Opennebula'   : 'opennebula3',
        'Mysql'        : 'mysql5',         
        '' : '',
    };
}

function loadServicesConfig(cid, eid) {
        create_grid({
            url: '/api/component?service_provider_id=' + eid,
            content_container_id: cid,
            grid_id: 'services_components',
            rowNum : 20,
            colNames: [ 'ID', 'Component Type', ],
            colModel: [
                { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'component_type_id', index: 'component_type_id', width: 200, formatter:fromIdToComponentType },
            ],
            caption: 'Components',
            details : {
                onSelectRow : function(eid, e) {
                    var componentType   = (getComponentTypes())[e.component_type_id];
                    if (componentType != undefined) {
                        (new KanopyaFormWizard({
                            title          : componentType + ' configuration',
                            type           : componentType,
                            id             : e.pk,
                            valuesCallback : function (type, id) {
                                return ajax('POST', '/api/' + componentType + '/' + e.pk + '/getConf');
                            },
                            submitCallback : function (data, $form, opts, onsuccess, onerror) {
                                var attrdef = ajax('GET', '/api/attributes/' + componentType).attributes;
                                var primary_attr;
                                for(var attr in attrdef) {
                                    if(attrdef[attr].is_primary == true) {
                                        primary_attr = attr;
                                        break;
                                    }
                                }
                                data[primary_attr] = e.pk;
                                return ajax('POST', '/api/' + componentType + '/' + e.pk + '/setConf', { conf : data }, onsuccess, onerror);
                            },
                            displayed      : ComponentsFields[componentType].displayed,
                            relations      : ComponentsFields[componentType].relations,
                        })).start();
                    }
                }
            }
        });
}
