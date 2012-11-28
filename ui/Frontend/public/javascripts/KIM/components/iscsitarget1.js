require('KIM/component.js');

var Iscsitarget1 = (function(_super) {
    Iscsitarget1.prototype = new _super();

    function Iscsitarget1(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'iscsitarget1_luns' : [ 'iscsitarget1_lun_device', 'iscsitarget1_lun_number',
                                    'iscsitarget1_target_name', 'iscsitarget1_lun_typeio', 'iscsitarget1_lun_iomode' ]
        };
    };

    Iscsitarget1.prototype.submitCallback = function (data, $form, opts, onsuccess, onerror) {
        var conf = {};
        conf.targets = [];
        for (var lun in data.iscsitarget1_luns) {
            var target = {};
            target.luns = [ data.iscsitarget1_luns[lun] ];
            conf.targets.push(target);
        }

        return _super.prototype.submitCallback.call(this, conf, $form, opts, onsuccess, onerror);
    },

    Iscsitarget1.prototype.valuesCallback = function (type, id) {
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

    Iscsitarget1.prototype.attrsCallback =  function (resource) {
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
    };

    return Iscsitarget1;

})(Component);
