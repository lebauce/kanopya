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
                                // Manager type + connector provider name
                                $("<td>", { text : data[i].manager_type + ' : ' }).css('vertical-align', 'middle').appendTo(l);
                                var std = $("<td>", { text : (sp.externalcluster_name != null) ? sp.externalcluster_name : sp.cluster_name }).appendTo(l);
                                $(std).css('vertical-align', 'middle');

                                // Configuration button
                                $.ajax({
                                    url     : '/api/entity/' + mangr.pk + '/getManagerParamsDef',
                                    type    : 'POST',
                                    async   : false,
                                    success : function(manager_params) {
                                        if (Object.keys(manager_params).length > 0) {
                                            $("<td>").append($("<a>", { text : 'Configure' }).button({ icons : { primary : 'ui-icon-wrench' } })).bind('click', { manager : data[i] }, function(event) {
                                                var manager = event.data.manager;
                                                createmanagerDialog(manager.manager_type, elem_id, $.noop, false, manager.pk, manager.manager_id);
                                            }).appendTo(l);
                                        } else {
                                            // Don't show configuration button if no parameters for this manager
                                            $("<td>").appendTo(l);
                                        }
                                    }
                                });

                                // Deletion button
                                $("<td>").append($("<a>", { text : 'Delete' }).button({ icons : { primary : 'ui-icon-trash' } }).bind('click', { pk : data[i].pk }, function(event) {
                                    deleteManager(event.data.pk, container_id, elem_id);
                                })).appendTo(l);
                                $(table).append(l);

                                // Concrete connector type name
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

/*
 * We manage here param info/def for all possible manager params of all managers
 * UGLY
 * TODO other (same mecanism as attr_def)
 */
function _managerParams() {
    var params  = {
        'ad_nodes_base_dn'  : { label : 'Nodes container DN', mandatory : 1 },
        'mockmonit_config'  : { label : 'Configuration', type : 'textarea' }
    };

    return (function(name) {
        return params[name] ? params[name] : { label : name };
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

function createmanagerDialog(managertype, sp_id, callback, skippable, instance_id, comp_id) {
    var that        = this;
    var mode_config = instance_id && instance_id > 0;
    callback        = callback || $.noop;
    connectortype   = managerConnectorTranslate(managertype);
    $.ajax({
        url         : '/api/serviceprovider/' + sp_id + '/findManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'category' : connectortype }),
        success     : function(data) {
            // we skip all managers of the Kanopya cluster (id=1)
            for (var i in data) if (data.hasOwnProperty(i)) {
                if (data[i].service_provider_id == 1) {
                    data.splice(i,1);
                }
            }

            if (data.length <= 0) {
                if (skippable) callback();
                else {
                    alert('No technical service connected to a ' + connectortype + '.\nSee: Administration -> Technical Services');
                }
                return;
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
                        if (mode_config) {
                            $.ajax({
                                url     : '/api/serviceprovider/' + sp_id + '/getManagerParameters',
                                type    : 'POST',
                                async   : false,
                                data    : { manager_type : managertype },
                                success : function(manager_params) {
                                    current_params = manager_params;
                                }
                            });
                        }
                        for (var i in data) if (data.hasOwnProperty(i)) {
                            $(fieldset).append($('<label>', {
                                text : managerParams(data[i]).label + " : ",
                                for : data[i]
                            })).append($('<'+ (managerParams(data[i]).type || 'input') +'>',
                                        { name : data[i], id : data[i], value : current_params[data[i]] })
                            );

                            // Specific management for custom form
                            if (connectortype == 'DirectoryServiceManager' && data[i] == 'ad_nodes_base_dn') {
                                $(fieldset).append($('<button>', {html : 'browse...'}).click( {manager_id : manager_id }, ActiveDirectoryBrowser ));
                            }
                        }
                    }
                });
            });

            // Don't show the manager dropdown list if we are configuring an alredy linked manager instance
            // Set the value to the correct manager id (used to load params)
            if (mode_config) {
                $(select).val(comp_id);
                $(select).hide();
            }
            $(select).trigger('change');

            $("<div>").append($(select)).append(fieldset).appendTo('body').dialog({
                title           : mode_config ? connectortype + ' configuration' : 'Link to a ' + connectortype,
                closeOnEscape   : false,
                resizable       : false,
                modal           : true,
                buttons         : {
                    'Cancel'    : function() {
                        $(this).dialog("destroy");
                        if (skippable) callback();
                    },
                    'Ok'        : function() {
                        var dial    = this;
                        var data    = {
                            manager_type        : managertype,
                            manager_id          : $(select).attr('value')
                        };
                        var params  = {};
                        var ok      = true;
                        $(fieldset).find(':input:not(:button)').each(function() {
                            if ( managerParams($(this).attr('name')).mandatory && ($(this).val() == null || $(this).val() === '')) {
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
                                    resizable   : false,
                                    title       : ""
                                });
                                $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
                            }, 10);

                            var url;
                            var post_data;
                            if (mode_config) {
                                url         = '/api/serviceprovidermanager/' + instance_id + '/addParams';
                                post_data   = {
                                        params      : data.manager_params,
                                        override    : 1
                                };
                            } else {
                                url         = '/api/serviceprovider/' + sp_id + '/addManager';
                                post_data   = data;
                            }
                            $.ajax({
                                url           : url,
                                type          : 'POST',
                                contentType   : 'application/json',
                                data          : JSON.stringify(post_data),
                                success       : function() {
                                    $(dial).dialog("destroy");
                                    callback();
                                },
                                complete      : function() {
                                    $("div#waiting_default_insert").dialog("destroy");
                                },
                                error         : function(error) {
                                    alert(error.responseText);
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
        text : 'Link to a ' + managerConnectorTranslate(managertype)
    }).button({ icons : { primary : 'ui-icon-link' } });
    var that                = this;
    var reload = function() {
        $('#' + container_id).empty();
        that.loadServicesConfig(container_id, sp_id);
    };
    addManagerButton.bind('click', function() {
        createmanagerDialog(managertype, sp_id, reload, false, 0);
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
