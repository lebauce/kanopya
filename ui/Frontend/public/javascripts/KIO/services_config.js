require('common/formatters.js');

//Check if there is a configured connector
function isThereAConnector(elem_id, connector_category) {
    var is  = false;
    // Get all configured connectors on the service
    $.ajax({
        async   : false,
        url     : '/api/connector?service_provider_id=' + elem_id,
        success : function(connectors) {
            for (i in connectors) if (connectors.hasOwnProperty(i)) {
                // Get the connector type for each
                $.ajax({
                    async   : false,
                    url     : '/api/connectortype?connector_type_id=' + connectors[i].connector_type_id,
                    success : function(data) {
                        if (data[0].connector_category === connector_category) {
                            is  = true;
                        }
                    }
                });
                if (is) {
                    break;
                }
            }
        }
    });
    return is;
}

function isThereAManager(elem_id, category) {
    var is  = null;

    $.ajax({
        url         : '/api/serviceprovider/' + elem_id + '/getManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'manager_type' : category }),
        async       : false,
        success     : function(data) {
            is  = data;
        }
    });
    return is;
}

function deleteManager(pk, container_id, elem_id) {
    $.ajax({
        url     : '/api/serviceprovidermanager/' + pk,
        type    : 'DELETE',
        success : function() {
            $('#' + container_id).empty();
            loadServicesConfig(container_id, elem_id);
        }
    });
}

function loadServicesConfig (container_id, elem_id) {
    var container = $('#' + container_id);
    var externalclustername = '';
    
    var connectorsTypeHash = {};
    var connectorsTypeArray = new Array;
    
    var that = this;

    $.ajax({
        url     : '/api/serviceprovider/' + elem_id,
        type    : 'GET',
        success : function(data) {
            var external    = "";
            if (data.externalcluster_id != null) external = 'external';
            var table   = $("<table>").css("width", "100%").appendTo(container);
            $(table).append($("<tr>").append($("<td>", { colspan : 2, class : 'table-title', text : "General" })));
            $(table).append($("<tr>").append($("<td>", { text : 'Name :', width : '100' })).append($("<td>", { text : data[external + 'cluster_name'] })));
            $(table).append($("<tr>").append($("<td>", { text : 'Description :' })).append($("<td>", { text : data[external + 'cluster_desc'] })));
            $(table).append($("<tr>", { height : '15' }).append($("<td>", { colspan : 2 })));
        }
    });

    $.ajax({
        url: '/api/connectortype?dataType=jqGrid',
        async   : false,
        success: function(connTypeData) {
                $(connTypeData.rows).each(function(row) {
                    //connectorsTypeHash = { 'pk' : connTypeData.rows[row].pk, 'connectorName' : connTypeData.rows[row].connector_name };
                    var pk = connTypeData.rows[row].pk;
                    connectorsTypeArray[pk] = {
                        name        : connTypeData.rows[row].connector_name,
                        category    : connTypeData.rows[row].connector_category
                    };
                });
            }
    });

    $.ajax({
        url     : '/api/serviceprovidermanager?service_provider_id=' + elem_id,
        success : function(data) {
            var ctnr    = $("<div>", { id : "managerslistcontainer", 'class' : 'details_section' });
            $(ctnr).appendTo($(container));
            var table   = $("<table>", { id : 'managerslist' }).prependTo($(ctnr));
            $(table).append($("<tr>").append($("<td>", { colspan : 3, class : 'table-title', text : "Managers" })));

            for (var i in data) if (data.hasOwnProperty(i)) {
                $.ajax({
                    url       : '/api/entity/' + data[i].manager_id,
                    async     : false,
                    success   : function(mangr) {
                        $.ajax({
                            url     : '/api/serviceprovider/' + mangr.service_provider_id,
                            async   : false,
                            success : function(sp) {
                                var l   = $("<tr>");
                                $("<td>", { text : data[i].manager_type + ' : ' }).css('vertical-align', 'middle').appendTo(l);
                                var std = $("<td>", { text : (sp.externalcluster_name != null) ? sp.externalcluster_name : sp.cluster_name }).appendTo(l);
                                $(std).css('vertical-align', 'middle');
                                $("<td>").append($("<a>", { text : 'Configure' }).button({ icons : { primary : 'ui-icon-wrench' } })).bind('click', { manager : data[i] }, function(event) {
                                    var manager = event.data.manager;
                                    createmanagerDialog(manager.manager_type, elem_id, function() {
                                        deleteManager(manager.pk, container_id, elem_id);
                                    });
                                }).appendTo(l);
                                $("<td>").append($("<a>", { text : 'Delete' }).button({ icons : { primary : 'ui-icon-trash' } }).bind('click', { pk : data[i].pk }, function(event) {
                                    deleteManager(event.data.pk, container_id, elem_id);
                                })).appendTo(l);
                                $(table).append(l);
                                $.ajax({
                                    url     : '/api/connector/' + mangr.pk,
                                    success : function(conn) {
                                        if (conn.connector_type_id != null) {
                                            $.ajax({
                                                url     : '/api/connectortype/' + conn.connector_type_id,
                                                success : function(conntype) {
                                                    $(std).text($(std).text() + ' - ' + conntype.connector_name);
                                                }
                                            });
                                        }
                                    }
                                });
                            }
                        });
                    }
                });
            }

            if (isThereAManager(elem_id, 'workflow_manager') === null) {
                createManagerButton('workflow_manager', ctnr, elem_id, container_id);
            }

            if (isThereAManager(elem_id, 'collector_manager') === null) {
                createManagerButton('collector_manager', ctnr, elem_id, container_id);
            }

            if (isThereAManager(elem_id, 'directory_service_manager') === null) {
                createManagerButton('directory_service_manager', ctnr, elem_id, container_id);
            }

        }
    });
}

function _managerParams() {
    var params  = {
        'ad_nodes_base_dn'  : 'Nodes container DN'
    };

    return (function(name) {
        return params[name];
    });
}
var managerParams = _managerParams();

function _managerConnectorTranslate() {
    var params  = {
        'workflow_manager'          : 'WorkflowManager',
        'collector_manager'         : 'Collectormanager',
        'directory_service_manager' : 'DirectoryServiceManager'
    };

    return (function(name) {
        return params[name];
    });
}
var managerConnectorTranslate = _managerConnectorTranslate();

function createmanagerDialog(managertype, sp_id, callback, skippable) {
    var that        = this;
    callback        = callback || $.noop;
    connectortype   = managerConnectorTranslate(managertype);
    $.ajax({
        url         : '/api/serviceprovider/' + sp_id + '/findManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'category' : connectortype }),
        success     : function(data) {
            if (data.length <= 0) {
                if (skippable) callback();
                else return;
            }
            var select  = $("<select>", { name : 'managerselection' })
            var fieldset= $('<fieldset>').css({'border' : 'none'});
            for (var i in data) if (data.hasOwnProperty(i)) {
                var theName     = data[i].name;
                var manager     = data[i];
                $.ajax({
                    url     : '/api/externalcluster/' + data[i].service_provider_id,
                    async   : false,
                    success : function(data) {
                        if (data.externalcluster_name != null) {
                            theName = data.externalcluster_name + " - " + theName;
                        }
                        $(select).append($("<option>", { text : theName, value : manager.id }));
                    }
                });
            }
            $(select).bind('change', function(event) {
                $(fieldset).empty();
                var manager_id = $(event.currentTarget).val();
                $.ajax({
                    url     : '/api/entity/' + manager_id + '/getManagerParamsDef',
                    type    : 'POST',
                    success : function(data) {
                        var current_params = {};
                        $.ajax({
                            url     : '/api/serviceprovider/' + sp_id + '/getManagerParameters',
                            type    : 'POST',
                            async   : false,
                            data    : { manager_type : managertype },
                            success : function(manager_params) {
                                current_params = manager_params;
                            }
                        });

                        for (var i in data) if (data.hasOwnProperty(i)) {
                            $(fieldset).append($('<label>', {
                                text : managerParams(data[i]) + " : ",
                                for : data[i]
                            })).append($("<input>", { name : data[i], id : data[i], value : current_params[data[i]] }));

                            // Specific management for custom form
                            if (connectortype == 'DirectoryServiceManager' && data[i] == 'ad_nodes_base_dn') {
                                $(fieldset).append($('<button>', {html : 'browse...'}).click( {manager_id : manager_id }, ActiveDirectoryBrowser ));
                            }
                        }
                    }
                });
            });
            $(select).trigger('change');
            $("<div>").append($(select)).append(fieldset).appendTo('body').dialog({
                title           : 'Add a ' + connectortype,
                closeOnEscape   : false,
                draggable       : false,
                resizable       : false,
                modal           : true,
                buttons         : {
                    'Cancel'    : function() { $(this).dialog("destroy"); if (skippable) callback(); },
                    'Ok'        : function() {
                        var dial    = this;
                        var data    = {
                            manager_type        : managertype,
                            manager_id          : $(select).attr('value')
                        };
                        var params  = {};
                        var ok      = true;
                        $(fieldset).find(':input:not(:button)').each(function() {
                            if ($(this).val() == null || $(this).val() === '') {
                              ok                            = false;
                            } else {
                              params[$(this).attr('name')]  = $(this).val();
                            }
                        });
                        if (ok === true) {
                            if (Object.keys(params).length > 0) {
                                data.manager_params = params;
                            }
                            setTimeout(function() { 
                                var dialog = $("<div>", { id : "waiting_default_insert", title : "Initializing configuration", text : "Please wait..." });
                                dialog.css('text-align', 'center');
                                dialog.appendTo("body").dialog({
                                    draggable   : false,
                                    resizable   : false,
                                    title       : ""
                                });
                                $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
                            }, 10);
                            $.ajax({
                                url           : '/api/serviceprovider/' + sp_id + '/addManager',
                                type          : 'POST',
                                contentType   : 'application/json',
                                data          : JSON.stringify(data),
                                success       : function() {
                                    $(dial).dialog("destroy");
                                    callback();
                                },
                                complete      : function() {
                                    $("div#waiting_default_insert").dialog("destroy");
                                },
                                error         : function() {
                                    if (skippable) callback();
                                }
                            });
                        }
                    }
                }
            });
        }
    });
}

function createManagerButton(managertype, ctnr, sp_id, container_id) {
    var addManagerButton    = $("<a>", {
        text : 'Add a ' + managerConnectorTranslate(managertype)
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    var that                = this;
    var reload = function() {
        $('#' + container_id).empty();
        that.loadServicesConfig(container_id, sp_id);
    };
    addManagerButton.bind('click', function() {
        createmanagerDialog(managertype, sp_id, reload);
    });
    addManagerButton.appendTo($(ctnr));
    $(ctnr).append("<br />");
}

// Build json tree as expected by jstree from ad tree
function buildADTreeJSONData(ad_tree) {
    var treedata = [];

    $.each(ad_tree, function (node_idx) {
        var node = ad_tree[node_idx];
        var treenode = {
                data        : node.name,
                attr        : { id : node.dn },
        }
        if (node.children.length > 0) {
            treenode.children = buildADTreeJSONData( node.children );
        }
        treedata.push( treenode );
    });

   return treedata;
}

function ActiveDirectoryBrowser(event) {
    var dn_input = $(this).prev();
    var ad_id    = event.data.manager_id;

    // Get AD user
    $.ajax({
        url         : '/api/entity/' + ad_id,
        async       : false,
        success     : function(data) {
            ad_user  = data.ad_user;
        }
    });

    require('common/general.js');
    callMethodWithPassword({
            login        : ad_user,
            dialog_title : "",
            url          : '/api/entity/' + ad_id + '/getDirectoryTree',
            success      : function(data) {
                require('jquery/jquery.jstree.js');
                var treedata = buildADTreeJSONData(data);

                var browser = $('<div>');
                var tree_cont = $('<div>', {style : 'height:300px'});
                var selected_dn_input = $('<input>', {style : 'width:350px'});
                browser.append(selected_dn_input);
                browser.append(tree_cont);

                tree_cont.jstree({
                    "plugins"   : ["themes","json_data","ui"],
                    "themes"    : {
                        url : "css/jstree_themes/default/style.css"
                    },
                    "json_data" : {
                        "data"                  : treedata,
                        "progressive_render"    : true
                    }
                }).bind("select_node.jstree", function (e, data) {
                    selected_dn_input.val(data.rslt.obj.attr("id"));
                });

                browser.dialog({
                    title   : 'AD Browser',
                    modal   : true,
                    width   : '400px',
                    buttons : {
                        Ok: function () {
                            dn_input.val(selected_dn_input.val());
                            $(this).dialog("close");
                        },
                        Cancel: function () {
                            $(this).dialog("close");
                        }
                    },
                    close: function (event, ui) {
                        $(this).remove();
                    }
                });
            }
    });
}
