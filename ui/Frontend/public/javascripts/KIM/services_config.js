require('common/general.js');
require('modalform.js');

var ComponentsFields = {
    'puppetagent2' : ['puppetagent2_mode','puppetagent2_masterip',
                      'puppetagent2_masterfqdn', 'puppetagent2_options'],
    'snmpd5'       : ['monitor_server_ip','snmpd_options'],
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
    'opennebula3'   : ['host_monitoring_interval', 'vm_polling_interval',
                       'port', 'hypervisor', 'debug_level',
                       'overcommitment_cpu_factor',
                       'overcommitment_memory_factor' ]
};

function getComponentTypes() {
    return {
        'Linux'        : 'linux0',
        'Mailnotifier' : 'mailnotifier0',
        'Puppetagent'  : 'puppetagent2',
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
            colNames: [ 'ID', 'Component Type', ],
            colModel: [
                { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'component_type_id', index: 'component_type_id', width: 200, formatter:fromIdToComponentType},
            ],
            caption: 'Components',
            details : {
                onSelectRow : function(eid, e) {
                    var componentType   = (getComponentTypes())[e.component_type_id];
                    if (componentType != undefined) {
                        (new FormWizardBuilder({
                            title      : componentType + ' configuration',
                            type       : componentType,
                            id         : e.pk,
                            displayed  : ComponentsFields[componentType],
                        })).start();
                    }
                }
            }
        });
}
