require('modalform.js');
var vlans   = [];

function networks_addbutton_action(e, isvlan) {
    var fields  = {
        network_name    : { label : 'Name' },
    };
    var isedit  = !(e instanceof Object);
    if (!isedit || isvlan) {
        fields.vlan_number  = { label : 'Vlan Number', skip : true }
    }
    (new ModalForm({
        title           : 'Create a Network',
        name            : 'network',
        fields          : fields,
        id              : (isedit) ? e : undefined,
        beforeSubmit    : function(fdata, f, opts, mdfrm) {
            var vlannumber  = $(mdfrm.content).find(':input#input_vlan_number').val();
            var action      = $(mdfrm.form).attr('action');
            var newaction   = (isvlan || (vlannumber != null && vlannumber != "")) ? 'vlan' : 'network';
            var appendId    = (isedit) ? '/' + e : '';
            $(mdfrm.form).attr('action', '/api/' + newaction + appendId);
            opts.url        = '/api/' + newaction + appendId;
            if (newaction === 'vlan') {
                fdata.push({
                    name    : 'vlan_number',
                    value   : vlannumber
                });
            }
            return true;
        },
        callback        : function() { $('#networks_list').trigger('reloadGrid'); }
    })).start();
}

function networks_associatepoolipbutton_action(network, associated, cid) {
    // Workaround, caller sometimes give 'null' as associated value.
    if (!associated) {
        associated = new Array();
    }

    $.ajax({
        url     : '/api/poolip',
        success : function(poolips) {
            var dial            = $('<div>').dialog({
                modal       : true,
                resizable   : false,
                close       : function() { $(this).remove(); },
                title       : 'Associate a Pool IP',
                buttons     : {
                    'Ok'        : function() {
                        $.ajax({
                            url         : '/api/network/' + network + '/associatePoolip',
                            type        : 'POST',
                            contentType : 'application/json',
                            data        : JSON.stringify({ poolip : $(select).val() }),
                            success     : function() {
                                $('#' + cid).empty();
                                networks_details_poolips(cid, network);
                                $(this).dialog('close');
                            }
                        });
                        $(this).dialog('close');
                    },
                    'Cancel'    : function() { $(this).dialog('close'); }
                }
            });
            var select          = $('<select>').appendTo(dial);
            for (var i in poolips) if (poolips.hasOwnProperty(i)) {
                for (var j = 0; j <= associated.length; ++j) {
                    if (j == associated.length) {
                        $(select).append($('<option>', { text : poolips[i].poolip_name, value : poolips[i].poolip_id }));
                        break;
                    }
                    if (poolips[i].pk === associated[j].poolip.poolip_id) {
                        break;
                    }
                }
            }
        }
    });
}

function networks_details_poolips(cid, eid) {
    var     isvlan  = false;
    for (var i = 0; i < vlans.length; ++i) {
        if (vlans[i].pk == eid) {
            isvlan  = true;
        }
    }
    var     expand  = (!isvlan) ? 'network_poolips,network_poolips.poolip' : 'parent,parent.network_poolips,parent.network_poolips.poolip';
    $.ajax({
        url     : '/api/network/' + eid + '?expand=' + expand,
        success : function(data) {
            create_grid({
                data                    : data.network_poolips,
                content_container_id    : cid,
                grid_id                 : 'network_associated_poolips',
                colNames                : [ 'Id', 'Name', 'First address', 'Size', 'Netmask', 'Gateway' ],
                colModel                : [
                    { name : 'poolip.poolid_id', index : 'poolip.poolip_id', hidden : true, key : true, sorttype : 'int' },
                    { name : 'poolip.poolip_name', index : 'poolip.poolip_name' },
                    { name : 'poolip.poolip_addr', index : 'poolip.poolip_addr' },
                    { name : 'poolip.poolip_mask', index : 'poolip.poolip_mask' },
                    { name : 'poolip.poolip_netmask', index : 'poolip.poolip_netmask' },
                    { name : 'poolip.poolip_gateway', index : 'poolip.poolip_gateway' }
                ],
                action_delete           : 'no',
            });
            var associatepoolipbutton   = $('<a>', { text : 'Associate a Pool IP' }).appendTo('#' + cid)
                                            .button({ icons : { primary : 'ui-icon-plusthick' } });
            $(associatepoolipbutton).bind('click', function() {
                var pips    = (isvlan) ? data.parent.network_poolips : data.network_poolips;
                networks_associatepoolipbutton_action(eid, pips, cid);
            });

            var editnetworkbutton       = $('<a>', { text : 'Edit network' }).appendTo('#' + cid)
                                            .button({ icons : { primary : 'ui-icon-wrench' } });
            $(editnetworkbutton).bind('click', function() {
                networks_addbutton_action(eid, isvlan);
            });
        }
    });
}

function networks_list(cid) {
    vlans   = [];
    create_grid({
        url                     : '/api/network',
        content_container_id    : cid,
        grid_id                 : 'networks_list',
        colNames                : [ 'Id', 'Name', 'Vlan' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'network_name', index : 'network_name' },
            { name : 'vlan_number', index : 'vlan_number' }
        ],
        details                 : {
            tabs    : [
                { label : 'PoolIPs', onLoad : networks_details_poolips }
            ]
        },
        afterInsertRow          : function(grid, rowid, rowdata, rowelem) {
            if (rowdata.vlan_number != null) {
                vlans.push(rowelem);
            }
        }
    });
    var addButton   = $('<a>', { text : 'Add a Network' }).appendTo('#' + cid)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', networks_addbutton_action);
}
