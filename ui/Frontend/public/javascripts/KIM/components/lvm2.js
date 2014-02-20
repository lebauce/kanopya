require('KIM/component.js');

var Lvm2 = (function(_super) {
    Lvm2.prototype = new _super();

    function Lvm2(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'lvm2_vgs' : [ 'lvm2_vg_name', 'lvm2_vg_size', 'lvm2_vg_freespace' ],
            'lvm2_lvs' : [ 'lvm2_lv_name', 'lvm2_lv_size', 'container_device', 'lvm2_lv_filesystem', 'lvm2_vg' ],
            'lvm2_pvs' : [ 'lvm2_pv_name', 'lvm2_pv_vg' ]
        };
    };

    Lvm2.prototype.submitCallback = function(data, $form, opts, onsuccess, onerror) {
        // Build the value hash as awaited by the component
        var conf = {};
        var lvs_by_vg = {}
        for (var lv in data.lvm2_lvs) {
            // The attr lvm2_vg_id has been renamed to lvm2_vg, to differentiate it
            // from the same attr in lvm2_pv...
            // So rename it as lvm2_vg_id.
            data.lvm2_lvs[lv].lvm2_vg_id = data.lvm2_lvs[lv].lvm2_vg;
            delete data.lvm2_lvs[lv].lvm2_vg;

            var lv_entry = data.lvm2_lvs[lv];
            if (lvs_by_vg[lv_entry.lvm2_vg_id] == undefined) {
                lvs_by_vg[lv_entry.lvm2_vg_id] = [];
            }
            lvs_by_vg[lv_entry.lvm2_vg_id].push(lv_entry);
        }

        var pvs_by_vg = {}
        for (var pv in data.lvm2_pvs) {
            var pv_entry = data.lvm2_pvs[pv];
            pv_entry.lvm2_vg_id = pv_entry.lvm2_pv_vg;
            delete pv_entry.lvm2_pv_vg;
            delete pv_entry.lvm2_id;
            if (pvs_by_vg[pv_entry.lvm2_vg_id] == undefined) {
                pvs_by_vg[pv_entry.lvm2_vg_id] = [];
            }
            pvs_by_vg[pv_entry.lvm2_vg_id].push(pv_entry);
        }

        conf.lvm2_vgs = [];
        for (var i in data.lvm2_vgs) {
            var vg = data.lvm2_vgs[i];
            // For some reason, some pvs are in data but
            // only have one single attribute lvm2_id
            if (!vg.lvm2_vg_name) continue;
            vg.lvm2_lvs = lvs_by_vg[vg.lvm2_vg_id] || [];
            vg.lvm2_pvs = pvs_by_vg[vg.lvm2_vg_id] || [];
            conf.lvm2_vgs.push(vg);
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
        conf.lvm2_pvs = [];
        for (var vg in conf.lvm2_vgs) {
            for (var lv in conf.lvm2_vgs[vg].lvm2_lvs) {
                var lv_entry = conf.lvm2_vgs[vg].lvm2_lvs[lv];
                var vg_id = delete lv_entry.lvm2_vg_id;

                // Rename the attr lvm2_vg_id to lvm2_vg, because we are displaying
                // both list vgs and lvs that have a common attr lvm2_vg_id.
                // We need to build many attrdef hash instead of only one.
                lv_entry.lvm2_vg = vg_id;
                conf.lvm2_lvs.push(lv_entry);
            }

            for (var pv in conf.lvm2_vgs[vg].lvm2_pvs) {
                var pv_entry = conf.lvm2_vgs[vg].lvm2_pvs[pv];
                var vg_id = delete pv_entry.lvm2_vg_id;
                pv_entry.lvm2_vg = vg_id;
                conf.lvm2_pvs.push(pv_entry);
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
            response.attributes['lvm2_pvs'] = {
                label       : 'Physical volumes',
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
            response.relations['lvm2_pvs'] = {
                attrs : {
                    accessor : 'multi'
                },
                cond : {
                    'foreign.lvm2_id' : 'self.lvm2_id'
                },
                resource: 'lvm2pv'
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
                container_device : {
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
        } else if (resource === 'lvm2pv') {
            var vgs = ajax('GET', '/api/lvm2vg');
            var attributes = {
                lvm2_pv_id : {
                    is_primary   : true,
                    is_mandatory : false
                },
                lvm2_id : {
                    type         : 'relation',
                    relation     : 'single',
                    is_mandatory : false
                },
                lvm2_pv_name : {
                    label        : 'Name',
                    type         : 'string',
                    is_mandatory : true,
                    is_editable  : true
                },
                lvm2_pv_vg : {
                    label        : 'Volume group',
                    type         : 'relation',
                    relation     : 'single',
                    is_mandatory : true,
                    is_editable  : true,
                    options      : vgs
                }
            };
        } else if (resource === 'lvm2vg') {
            var response = ajax('GET', '/api/attributes/' + resource);
            response.attributes['lvm2_vg_freespace'].disabled = true;
            return response;

        } else {
            return ajax('GET', '/api/attributes/' + resource);
        }
        return { attributes : attributes, relations : {} };
    };

    return Lvm2;

})(Component);
