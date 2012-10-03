require('KIM/component.js');

var Nfsd3 = (function(_super) {
    Nfsd3.prototype = new _super();

    function Nfsd3(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'exports': [ 'nfsd3_export_path', 'container_access_export', 'nfsd3_exportclient_name', 'nfsd3_exportclient_options' ],
        };
    };

    Nfsd3.prototype.submitCallback = function (data, $form, opts, onsuccess, onerror) {
        var conf = {
            nfsd3_statdopts       : data.nfsd3_statdopts,
            nfsd3_rpcmountopts    : data.nfsd3_rpcmountopts,
            nfsd3_rpcsvcgssdopts  : data.nfsd3_rpcsvcgssdopts,
            nfsd3_rpcnfsdcount    : data.nfsd3_rpcnfsdcount,
            nfsd3_need_svcgssd    : data.nfsd3_need_svcgssd,
            nfsd3_rpcnfsdpriority : data.nfsd3_rpcnfsdpriority
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
            };
            conf.exports.push(e);    
        }
        return _super.prototype.submitCallback.call(this, conf, $form, opts, onsuccess, onerror);
    };

    Nfsd3.prototype.valuesCallback = function (type, id) {
        var response = ajax('POST', '/api/' + type + '/' + id + '/getConf');

        for(index in response.exports) {
            response.exports[index]['nfsd3_exportclient_name'] = response.exports[index].clients[0].nfsd3_exportclient_name;
            response.exports[index]['nfsd3_exportclient_options'] = response.exports[index].clients[0].nfsd3_exportclient_options;
            delete response.exports[index].clients;
        }

        return response;
    };

    Nfsd3.prototype.attrsCallback =  function (resource) {
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
    };

    return Nfsd3;

})(Component);
