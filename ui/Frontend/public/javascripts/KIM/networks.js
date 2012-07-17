
function networks_addbutton_action(e) {
    (new ModalForm({
        title           : 'Create a Network',
        name            : 'network',
        fields          : {
            network_name    : { label : 'Name' },
            vlan_number     : { label : 'Vlan Number', skip : true }
        },
        beforeSubmit    : function(fdata, f, opts, mdfrm) {
            var vlannumber  = $(mdfrm.content).find(':input#input_vlan_number').val();
            var action      = $(mdfrm.form).attr('action');
            var newaction   = (vlannumber != null && vlannumber != "") ? 'vlan' : 'network';
            $(mdfrm.form).attr('action', '/api/vlan');
            opts.url        = '/api/vlan';
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
    $.ajax({
        url     : '/api/poolip',
        success : function(poolips) {
            var dial            = $('<div>').dialog({
                modal       : true,
                resizable   : false,
                draggable   : false,
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
    $.ajax({
        url     : '/api/network/' + eid + '?expand=network_poolips,network_poolips.poolip',
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
                ]
            });
            var associatepoolipbutton   = $('<a>', { text : 'Associate a Pool IP' }).appendTo('#' + cid)
                                            .button({ icons : { primary : 'ui-icon-plusthick' } });
            $(associatepoolipbutton).bind('click', function() {
                networks_associatepoolipbutton_action(eid, data.network_poolips, cid);
            });
        }
    });
}

function networks_list(cid) {
    create_grid({
        url                     : '/api/network',
        content_container_id    : cid,
        grid_id                 : 'networks_list',
        colNames                : [ 'Id', 'Name' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'network_name', index : 'network_name' }
        ],
        details                 : {
            tabs    : [
                { label : 'PoolIPs', onLoad : networks_details_poolips }
            ]
        }
    });
    var addButton   = $('<a>', { text : 'Add a Network' }).appendTo('#' + cid)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', networks_addbutton_action);
}
