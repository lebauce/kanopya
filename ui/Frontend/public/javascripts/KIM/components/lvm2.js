require('KIM/component.js');

var Lvm2 = (function(_super) {
    Lvm2.prototype = new _super();

    function Lvm2(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'lvm2_vgs' : [ 'lvm2_vg_name', 'lvm2_vg_size', 'lvm2_vg_freespace' ],
            'lvm2_lvs' : [ 'lvm2_lv_name', 'lvm2_lv_size', 'constainer_access_device', 'lvm2_lv_filesystem', 'lvm2_vg' ],
        };
    };

    Lvm2.prototype.submitCallback = function(data, $form, opts, onsuccess, onerror) {
        // Build the value hash as awaited by the component
        var conf = {};
        var lvs_by_vg = {}
        for (var lv in data.lvm2_lvs) {
            var lv_entry = data.lvm2_lvs[lv];
            if (lvs_by_vg[lv_entry.lvm2_vg] == undefined) {
                lvs_by_vg[lv_entry.lvm2_vg] = [];
            }
            lvs_by_vg[lv_entry.lvm2_vg].push(lv_entry);
        }

        conf.vgs = [];
        for (var vg in lvs_by_vg) {
            // Use any lv in the list to get the vg_id.
            conf.vgs.push({ vg_id: lvs_by_vg[vg][0].lvm2_vg, lvs: lvs_by_vg[vg] } )
        }

        return _super.prototype.submitCallback.call(this, conf, $form, opts, onsuccess, onerror);
    };

    Lvm2.prototype.valuesCallback = function(type, id) {
        var conf = ajax('POST', '/api/' + type + '/' + id + '/getConf');

        // Set the primary key.
        // TODO: Check if we must set it for all components.
        conf['lvm2_id'] = id;

        // Get the values from getConf, add build a new values hash
        // according to the attrdef builded in the attrsCallback.
        conf.lvm2_lvs = [];
        for (var vg in conf.lvm2_vgs) {
            for (var lv in conf.lvm2_vgs[vg].lvm2_lvs) {
                lv_entry = conf.lvm2_vgs[vg].lvm2_lvs[lv];

                // Rename the attr lvm2_vg_id to lvm2_vg, because we are displaying
                // both list vgs and lvs that have a common attr lvm2_vg_id.
                // We need to build many attrdef hash instead of only one.
                lv_entry.lvm2_vg = delete lv_entry.lvm2_vg_id;
                conf.lvm2_lvs.push(lv_entry);
            }
        }
        return conf;
    };

    Lvm2.prototype.attrsCallback = function(resource) {
        if (resource === 'lvm2') {
            // If ressource is the component, add the fake relation
            var response = ajax('GET', '/api/attributes/' + resource);
            response.attributes['lvm2_lvs'] = {
                label       : 'Logical volumes',
                type        : 'relation',
                relation    : 'single_multi',
                is_editable : true
            };
            response.relations['lvm2_lvs'] = {
                attrs : {
                    accessor : 'multi'
                },
                cond : {
                    'foreign.lvm2_id' : 'self.lvm2_id'
                },
                resource: 'lvm2lv'
            };
            return response;
    
        } else if (resource === 'lvm2lv') {
            var vgs = ajax('GET', '/api/lvm2vg');
            var attributes = {
                lvm2_lv_id : {
                    is_primary   : true,
                    is_mandatory : false
                },
                lvm2_id : {
                    type         : 'relation',
                    relation     : 'single',
                    is_mandatory : false
                },
                lvm2_lv_name : {
                    label        : 'Name',
                    type         : 'string',
                    is_mandatory : true,
                    is_editable  : true
                },
                lvm2_lv_size : {
                    label        : 'Size',
                    type         : 'string',
                    unit         : 'byte',
                    is_mandatory : true,
                    is_editable  : true
                },
                constainer_access_device : {
                    label        : 'Device',
                    type         : 'string',
                    is_mandatory : true,
                    is_editable  : false
                },
                lvm2_lv_filesystem : {
                    label        : 'File system',
                    type         : 'string',
                    is_mandatory : true,
                    is_editable  : true
                },
                lvm2_vg : {
                    label        : 'Volume group',
                    type         : 'relation',
                    relation     : 'single',
                    is_mandatory : true,
                    is_editable  : true,
                    options      : vgs
                }
            };
        } else {
            return ajax('GET', '/api/attributes/' + resource);
        }
        return { attributes : attributes, relations : {} };
    };

    return Lvm2;

})(Component);
