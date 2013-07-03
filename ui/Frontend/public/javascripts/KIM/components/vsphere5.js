require('KIM/component.js');

var Vsphere5 = (function(_super) {
    Vsphere5.prototype = new _super();

    function Vsphere5(id) {
        _super.call(this, id);

        this.displayed = [ 'vsphere5_login', 'vsphere5_pwd', 'vsphere5_url', 'overcommitment_cpu_factor', 'overcommitment_memory_factor'];

        this.actionsCallback = function () {
            var vsphereButton = $('<input>', { type : 'button' }).val('Import vSphere').bind('click', function(event) {
                // TODO confirmation of insertion
                $('.ui-dialog').find('#button-ok').click();
                vsphereBrowser(event);
            });
            var buttons = [ vsphereButton.button() ];
            return buttons;
        };
    };

    return Vsphere5;
})(Component);

// VSPHERE BROWSER TREE

var registered_nodes = [];// list of nodes already registered in Kanopya

// format the data returned by API to respect jsTree structure
function buildNodes (rawData, parentName, parentType, grandParentName) {
    var formattedData = [];
    // initialize register nodes list
    registered_nodes = [];
    $.each(rawData, function (index, node) {
        var treenode =  {
            'data'  :   {
                'title'         :   node.name,
                // TODO Put icon depending on the type of the Node
                //'icon'        :   '',//value : /File or CSS(for eg Same name as Type)
            },
            'attr'  :   {
                'name'          :   node.name,
                'treeType'      :   node.type,
                'parent_type'   :   parentType,
                'parent_name'   :   parentName,
            },
        };
        // 'treeType' : used for display & 'type' : property to be returned
        if (node.type == 'vm') {
            treenode.attr['type'] = node.type;
            //Only VM and Hypervisors have UUID
            treenode.attr['uuid'] = node.uuid;
        }
        else {
            // other nodes than VMs can be opened (they may contain children)
            treenode.state = 'closed';
            if (node.type == 'clusterHypervisor') {
                treenode.attr['type'] = 'hypervisor';
                // only VM and Hypervisors have UUID
                treenode.attr['uuid'] = node.uuid;
                treenode.attr['grand_parent_name'] = grandParentName;//to save Datacenter Name of Hypervisor
            }
            else {
                treenode.attr['type'] = node.type;
                if (node.type == 'hypervisor') {
                    // only VM and Hypervisors have UUID
                    treenode.attr['uuid'] = node.uuid;
                }
            }
        }
        if (node.registered == 1) {// item already registered
            registered_nodes.push(node.name);
        }
        formattedData.push(treenode);
    });

    return formattedData;
}

// format tree's checked nodes to respect API format
function formatCheckedNodes (nodes) {    
    var tree = [];
    $.each(nodes, function(index, raw_node) {
        var node = $(raw_node);
        if ( node.hasClass('jstree-checked') || node.hasClass('jstree-undetermined')  ) {
            var formattedNode = {
                name        : node.attr('name'),
                type        : node.attr('type'),
                uuid        : node.attr('uuid'),
                children    : formatCheckedNodes(node.children('ul').children('li')),
            };
            tree.push(formattedNode);
        }
    }
    );

    return tree;
}

// browse vSphere Infrastructure
function vsphereBrowser (event) {
    require('jquery/jquery.jstree.js');
    var browser        = $('<div>');
    var tree_container = $('<div>', {id : 'vsphere_tree'});

    // get the vSphere Component ID
    var vsphere_component_id;
    $.ajax( {
        url : '/api/vsphere5',
        success : function (data) {
                      vsphere_component_id = data[0].pk;
                  },
        contentType : 'application/json',
        async : false
    } );

    var url_base = '/api/vsphere5/' + vsphere_component_id;

    var parents = [];// to save parents of nodes
    var id_request = 0;

    browser.append(tree_container);
    tree_container.jstree({
        'plugins'   :   ['themes', 'json_data', 'checkbox', 'ui'],
        'themes'    :   {
           'url' : "css/jstree_themes/default/style.css",
         },
        // TODO ckeck already registered nodes
        'checkbox'  :   {
            'override_ui'         :   true,// for checking nodes on load
         },
        'ui'        :   {
            'initially_select'    :  registered_nodes,
         },
        'json_data' :   {
            'ajax'               :  {
                'type'  : 'POST',
                'url'   :   function (current_node) {
                                if (current_node == -1) {// initial node
                                    url = url_base + '/retrieveDatacenters';
                                }
                                else {
                                    if ( current_node.attr('treeType') == 'datacenter' ) {
                                        url = url_base + '/retrieveClustersAndHypervisors';
                                    }
                                    else if ( current_node.attr('treeType') == 'cluster' ) {
                                       url = url_base + '/retrieveClusterHypervisors';
                                    }
                                    else if ( current_node.attr('treeType') == 'hypervisor' ||
                                              current_node.attr('treeType') == 'clusterHypervisor' ) {
                                       url = url_base + '/retrieveHypervisorVms';
                                    }
                                }

                                return url;
                            },
                'data'    :     function(current_node) {
                    var data_sent = {};
                    if ( current_node == -1 ) {// initial node : we don't send data
                        parents[id_request] = {
                            parentNodeTreeType      : 'tree',
                            parentNodeTreeName      : 'root',
                            grandParentNodeTreeName : null
                        };
                    }
                    else {
                        parents[id_request] = {
                            parentNodeTreeType  : current_node.attr('treeType'),
                            parentNodeTreeName  : current_node.attr('name')
                        };
                        if ( current_node.attr('treeType') == 'datacenter' ) {
                            // retrieve Clusters and Hypervisors on a Datacenter
                            data_sent = {
                                'datacenter_name'    :    current_node.attr('name'),
                            };
                            parents[id_request].grandParentNodeTreeName = null;
                        }
                        else if ( current_node.attr('treeType') == 'cluster' ) {
                            // retrieve Hypervisors on a Cluster
                            data_sent = {
                                'datacenter_name'    :    current_node.attr('parent_name'),
                                'cluster_name'       :    current_node.attr('name'),
                            };
                            // we save datacenter name for Hypervisor
                            parents[id_request].grandParentNodeTreeName = current_node.attr('parent_name');
                        }
                        else if ( current_node.attr('treeType') == 'clusterHypervisor') {
                            // retrieve Virtual Machines on an Hypervisor hosted on a Cluster
                            data_sent = {
                                'datacenter_name'    :    current_node.attr('grand_parent_name'),
                                'hypervisor_uuid'    :    current_node.attr('uuid'),
                            };
                            parents[id_request].grandParentNodeTreeName = null;
                        }
                        else if ( current_node.attr('treeType') == 'hypervisor' ) {
                            // retrieve Virtual Machines on an Hypervisor hosted on a Datacenter
                            data_sent = {
                                'datacenter_name'    :    current_node.attr('parent_name'),
                                'hypervisor_uuid'    :    current_node.attr('uuid'),
                            };
                            parents[id_request].grandParentNodeTreeName = null;
                        }
                    }
                    data_sent['id_request'] = id_request;
                    id_request++;

                    return data_sent;
                },
                'success'   :   function (returnedData) {
                    var id_response = returnedData.id_response;
                    var parentNodeTreeName = parents[id_response].parentNodeTreeName;
                    var parentNodeTreeType = parents[id_response].parentNodeTreeType;
                    var grandParentNodeTreeName = parents[id_response].grandParentNodeTreeName;
                    var returnedFormattedData = buildNodes(
                            returnedData.items_list,
                            parentNodeTreeName,
                            parentNodeTreeType,
                            grandParentNodeTreeName
                        );
                        
                    return returnedFormattedData;
                }
            }
        }
    });

    browser.dialog({
        title   :   'Import vSphere architecture',
        modal   :   true,
        // TODO width's value in CSS
        width   :   '400 px',
        buttons :   {
            Cancel: function () {
                $(this).dialog('close');
            },
            Submit: function () {
                var firstLevelTree = $(tree_container).children('ul').children('li');
                var formattedCheckedNodes = formatCheckedNodes(firstLevelTree);

                // send formatted checked nodes to API for insertion in Kanopya Database
                $.ajax({
                    type        :   'POST',
                    url         :   url_base + '/register',
                    contentType : 'application/json',
                    data        :   JSON.stringify({
                        'register_items'    :   formattedCheckedNodes,
                    }),
                }).done(function (success_msg){
                    alert ('Data imported successfully in Kanopya');
                }).fail(function (error_msg){
                    alert ('Error in data import');
                });

                $(this).dialog('close');
            },
        },
        close : function (event, ui) {
            $(this).remove();
        }
    });
}
