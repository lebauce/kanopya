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
        'relations': { 'opennebula3_repositories': ['repository_name', 'container_access_id'], },
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
    'keepalived1': { 
        'displayed': ['notification_email',
                     'notification_email_from',
                     'smtp_server',
                     'smtp_connect_timeout',
                     'daemon_method'],
        'relations': {},
    },
    'memcached1': {
        'displayed': ['memcached1_port'],
        'relations': {},
    },
    'php5': {
        'displayed': ['php5_session_handler','php5_session_path'],                 
        'relations': {},
    },
    'iscsitarget1': {
        'displayed': [],
        'relations': { 'iscsitarget1_luns' : [ 'iscsitarget1_lun_device', 'iscsitarget1_lun_number', 'iscsitarget1_target_name', 'iscsitarget1_lun_typeio', 'iscsitarget1_lun_iomode' ] },
        'valuesCallback' : function (type, id) {
            var conf = ajax('POST', '/api/' + type + '/' + id + '/getConf');

            // Get the values from getConf, add build a new values hash
            // according to the attrdef builded in the attrsCallback.
            conf.iscsitarget1_luns = [];
            for (var target in conf.targets) {
                for (var lun in conf.targets[target].luns) {
                    conf.targets[target].luns[lun].iscsitarget1_target_name = conf.targets[target].iscsitarget1_target_name;
                    conf.iscsitarget1_luns.push(conf.targets[target].luns[lun]);
                }
            }
            return conf;
        },
        'submitCallback' : function (data, $form, opts, onsuccess, onerror) {
            // Parse the infos from options
            var infos = opts.url.split('/');
            var type = infos[2];
            var id = infos[3];

            // Add the primary key value to data
            data[getPrimarykey(type)] = id;

            var conf = {};
            conf.targets = [];
            for (var lun in data.iscsitarget1_luns) {
                var target = {};
                target.luns = [ data.iscsitarget1_luns[lun] ];
                conf.targets.push(target);
            }

            console.log(conf);

            // Call setConf on the component
            return ajax('POST', opts.url + '/setConf', { conf : conf }, onsuccess, onerror);
        },
        'attrsCallback' : function (resource) {
            if (resource === 'iscsitarget1') {
                // If ressource is the component, add the fake relation
                var response = ajax('GET', '/api/attributes/' + resource);
                response.attributes['iscsitarget1_luns'] = {
                    label       : 'Iscsi luns',
                    type        : 'relation',
                    relation    : 'single_multi',
                    is_editable : true,
                };
                response.relations['iscsitarget1_luns'] = {
                    attrs : {
                        accessor : 'multi',
                    },
                    cond : {
                        'foreign.iscsitarget1_id' : 'self.iscsitarget1_id',
                    },
                    resource: 'iscsitarget1lun',
                };
                return response;

            } else if (resource === 'iscsitarget1lun') {
                // If ressource is the relation, build the fake attrdef
                var containers = ajax('GET', '/api/container');
                var devices = [];
                for (var container in containers) {
                    devices.push(containers[container].container_device);
                }
                var attributes = {
                    iscsitarget1_lun_id : {
                        is_primary   : true,
                        is_mandatory : false,
                    },
                    iscsitarget1_id : {
                        type         : 'relation',
                        relation     : 'single',
                        is_mandatory : true,
                    },
                    iscsitarget1_lun_device : {
                        label        : 'Device',
                        type         : 'relation',
                        relation     : 'single',
                        is_mandatory : true,
                        is_editable  : true,
                        options      : devices,
                    },
                    iscsitarget1_lun_number : {
                        label        : 'Lun number',
                        type         : 'string',
                        is_mandatory : true,
                        is_editable  : false,
                    },
                    iscsitarget1_lun_typeio : {
                        label        : 'I/O type',
                        type         : 'enum',
                        options      : [ 'fileio', 'blockio', 'nullio' ],
                        is_mandatory : true,
                        is_editable  : true,
                    },
                    iscsitarget1_lun_iomode : {
                        label        : 'I/O mode',
                        type         : 'enum',
                        options      : [ 'wb', 'ro', 'wt' ],
                        is_mandatory : true,
                        is_editable  : true,
                    },
                    iscsitarget1_target_name : {
                        label        : 'Target',
                        type         : 'string',
                        is_editable  : false,
                    },
                };
                return { attributes : attributes, relations : {} };
            }
        }
    },
    'apache2': {
        'displayed': ['apache2_serverroot',
                      'apache2_loglevel',
                      'apache2_ports',
                      'apache2_sslports'],
        'relations': { 'apache2_virtualhosts': ['apache2_virtualhost_servername',
                                               'apache2_virtualhost_sslenable',
                                               'apache2_virtualhost_serveradmin',
                                               'apache2_virtualhost_documentroot',
                                               'apache2_virtualhost_log',
                                               'apache2_virtualhost_errorlog'] },
    },
    'nfsd3': {
        'displayed': [],
        'relations': { 'exports': ['nfsd3_export_path','container_access_export','nfsd3_exportclient_name','nfsd3_exportclient_options']},
        'valuesCallback': function (type, id) {
            var response = ajax('POST', '/api/' + type + '/' + id + '/getConf');
            var exports = [];
            //console.log(response);
            for(index in response.exports) {
                response.exports[index]['nfsd3_exportclient_name'] = response.exports[index].clients[0].nfsd3_exportclient_name;
                response.exports[index]['nfsd3_exportclient_options'] = response.exports[index].clients[0].nfsd3_exportclient_options;
                delete response.exports[index].clients;
            }
            console.log(response);
            return response;
        },        
        'submitCallback' : function (data, $form, opts, onsuccess, onerror) {
            //console.log(data);

            // Parse the infos from options
            var infos = opts.url.split('/');
            var type = infos[2];
            var id = infos[3];

            // Add the primary key value to data
            data[getPrimarykey(type)] = id;

            var conf = {
                    nfsd3_statdopts : data.nfsd3_statdopts,
                    nfsd3_rpcmountopts: data.nfsd3_rpcmountopts,
                    nfsd3_rpcsvcgssdopts: data.nfsd3_rpcsvcgssdopts,
                    nfsd3_rpcnfsdcount: data.nfsd3_rpcnfsdcount,
                    nfsd3_need_svcgssd: data.nfsd3_need_svcgssd,
                    nfsd3_rpcnfsdpriority: data.nfsd3_rpcnfsdpriority
            };
            conf.exports = [];
            for (var index in data.exports) {
                var e = {
                    nfsd3_export_path: data.exports[index].nfsd3_export_path,
                    nfsd3_export_id: data.exports[index].nfsd3_export_id,
                    clients: [{
                        nfsd3_exportclient_name: data.exports[index].nfsd3_exportclient_name,
                        nfsd3_exportclient_options: data.exports[index].nfsd3_exportclient_options,
                    }],
                }
                
                conf.exports.push(e);  
                
            }
            console.log(conf);
            // Call setConf on the component
            return ajax('POST', opts.url + '/setConf', { conf : conf }, onsuccess, onerror);
        },
        'attrsCallback': function (resource) {
            if(resource == 'nfsd3') {
                var response = ajax('GET', '/api/attributes/nfsd3');
                response.attributes['exports'] = {
                    'label'      : 'Exports',
                    'type'       : 'relation',
                    'relation'   : 'single_multi',
                    'is_editable': 1
                };
                response.relations['exports'] = {
                    'attrs' : { 'accessor' : 'multi' },
                    'cond'  : { 'foreign.nfsd3_id': 'self.nfsd3_id' },
                    'resource' : 'containeraccess',
                };
                
                return response;
            } else if(resource == 'containeraccess') {
                // If ressource is the relation, build the fake attrdef
                var containers = ajax('GET', '/api/container');
                var devices = [];
                for (var container in containers) {
                    devices.push(containers[container].container_device);
                }
                
                var attributes = {                
                    nfsd3_id: {},
                    nfsd3_export_id: {
                        is_primary   : true,
                        is_mandatory : false,
                    },
                    nfsd3_export_path: {
                        label        : 'Device',
                        type         : 'enum',
                        is_mandatory : true,
                        is_editable  : true,
                        options      : devices
                    },
                    container_access_export: {
                        label        : 'Export',
                        type         : 'string',
                        is_mandatory : true,
                        is_editable  : false,
                    },
                    nfsd3_exportclient_name: {
                        label        : 'Client name',
                        type         : 'string',
                        is_mandatory : true,
                        is_editable  : true,
                    },
                    nfsd3_exportclient_options: {
                        label        : 'Client options',
                        type         : 'string',
                        is_mandatory : true,
                        is_editable  : true,
                    },
                };
                
                return { attributes : attributes, relations : {} };
            } else {
                return ajax('GET', '/api/attributes/' + resource);
            }
        },
    },

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
        'Iscsitarget'  : 'iscsitarget1', 
        'Mysql'        : 'mysql5',
        'Mysql'        : 'mysql5',         
        'Nfsd'         : 'nfsd3',
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
                            valuesCallback : ComponentsFields[componentType].valuesCallback ? ComponentsFields[componentType].valuesCallback :
                                function (type, id) {
                                    return ajax('POST', '/api/' + componentType + '/' + e.pk + '/getConf');
                                },
                            submitCallback : ComponentsFields[componentType].submitCallback ? ComponentsFields[componentType].submitCallback :
                                function (data, $form, opts, onsuccess, onerror) {
                                    // Add the primary key value to data
                                    data[getPrimarykey(componentType)] = e.pk;
                                    // Call setConf on the component
                                    return ajax('POST', '/api/' + componentType + '/' + e.pk + '/setConf', { conf : data }, onsuccess, onerror);
                                },
                            displayed      : ComponentsFields[componentType].displayed,
                            relations      : ComponentsFields[componentType].relations,
                            attrsCallback  : ComponentsFields[componentType].attrsCallback,
                        })).start();
                    }
                }
            }
        });
}

function getPrimarykey (componentType) {
    var attrdef = ajax('GET', '/api/attributes/' + componentType).attributes;
    var primary_attr;
    for(var attr in attrdef) {
        if(attrdef[attr].is_primary == true) {
            return attr;
        }
    }
}
