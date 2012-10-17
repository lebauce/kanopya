//GLOBAL VARIABLES
var registered_nodes = [];//List of nodes already registered in Kanopya

//We format the data returned by API to respect jsTree structure
function buildNodes (rawData, parentName, parentType, grandParentName) {
    var formattedData = [];
    //Initialize register nodes list
    registered_nodes = [];
    $.each(rawData, function (index, node) {
        var treenode =  {
            'data'  :   {
                'title'         :   node.name,
//TODO Put icon depending on the type of the Node
                //'icon'        :   '',//value : /File or CSS(for eg Same name as Type)
            },
            'attr'  :   {
                'name'          :   node.name,
                'treeType'      :   node.type,
                'parent_type'   :   parentType,
                'parent_name'   :   parentName,
            },
        };
//TODO always treeType except in formatCheckedNodes
        //'treeType' used for display
        //'type' : property to be returned
        if (node.type == 'vm') {
            treenode.attr['type'] = node.type;
        }
        else {
            //Other nodes than VMs can be opened (they may contain children)
            treenode.state = 'closed';
            if (node.type == 'clusterHypervisor') {
                treenode.attr['type'] = 'hypervisor';
                treenode.attr['grand_parent_name'] = grandParentName;
            }
            else {
                treenode.attr['type'] = node.type;
            }
        }
        if (node.registered == 1) {//Item already registered
            registered_nodes.push(node.name);
        }
        formattedData.push(treenode);
    });

    return formattedData;
}


function formatCheckedNodes (nodes) {    
    var tree = [];
    $.each(nodes, function(index, raw_node) {
        var node = $(raw_node);
        if ( node.hasClass('jstree-checked') || node.hasClass('jstree-undetermined')  ) {
            var formattedNode = {
                name        : node.attr('name'),
                type        : node.attr('type'),
                children    : formatCheckedNodes(node.children('ul').children('li')),
            };
            tree.push(formattedNode);
        }
    }
    );

    return tree;
}

//Browse VMware inventary
function vmwareBrowser (event) {
    require('jquery/jquery.jstree.js');
    var browser        = $('<div>');
    var tree_container = $('<div>', {id : 'vmware_tree'});

//TODO Get ID directly from Kanopya (VirtualMachineManager)
    //Get the vSphere Component ID
    var vsphere_component_id = 100;
    var url_base = '/api/vsphere5/' + vsphere_component_id;

//TODO Use Type and Name values of node.parentElement
    //Used to save Type and Name of the Parent Node for Childrens
    var parentNodeTreeType = null;
    var parentNodeTreeName = null;
    var grandParentNodeTreeName = null;

    browser.append(tree_container);
    tree_container.jstree({
        'plugins'   :   ['themes', 'json_data', 'checkbox', 'ui'],
        'themes'    :   {
           'url' : "css/jstree_themes/default/style.css",
         },
//TODO ckeck already registered nodes
        'checkbox'  :   {
            'override_ui'         :   true,//For checking nodes on load
         },
        'ui'        :   {
            'initially_select'    :  registered_nodes,
         },
        'json_data' :   {
            'ajax'               :  {
                'type'  : 'POST',
                'url'   :   function (current_node) {
                                if (current_node == -1) {//Initial node
                                    url = url_base + '/retrieveDatacenters';
                                }
                                else {
                                    if ( current_node.attr('treeType') == 'datacenter' ) {
                                        url = url_base + '/retrieveClustersAndHypervisors';
                                    }
                                    else if ( current_node.attr('treeType') == 'cluster' ) {
                                       url = url_base + '/retrieveClusterHypervisors';
                                    }
                                    else if ( current_node.attr('treeType') == 'clusterHypervisor' ) {
                                       url = url_base + '/retrieveClusterVms';
                                    }
                                    else if ( current_node.attr('treeType') == 'hypervisor' ) {
                                       url = url_base + '/retrieveHypervisorVms';
                                    }
                                }

                                return url;
                            },
                'data'    :     function(current_node) {
                    //For Initial Node, we don't send data
                    var data_sent = {};
                    parentNodeTreeType = 'tree';
                    parentNodeTreeName = 'root';

                    //For other nodes, we send the Type and Name of node and node's parent
                    if ( current_node != -1 ) {//Not initial Node
                        parentNodeTreeType = current_node.attr('treeType');
                        parentNodeTreeName = current_node.attr('name');
                        if ( current_node.attr('treeType') == 'datacenter' ) {
                            //Retrieve Clusters and Hypervisors on a Datacenter
                            data_sent = {
                               'datacenter_name'    :    current_node.attr('name'),
                            };
                            grandParentNodeTreeName = null;
                        }
                        else if ( current_node.attr('treeType') == 'cluster' ) {
                            //Retrieve Hypervisors on a Cluster
                            data_sent = {
                               'datacenter_name'    :    current_node.attr('parent_name'),
                               'cluster_name'       :    current_node.attr('name'),
                            };
                            //We save datacenter name for Hypervisor
                            grandParentNodeTreeName = current_node.attr('parent_name');
                        }
                        else if ( current_node.attr('treeType') == 'clusterHypervisor' ) {
                            //Retrieve Virtual Machines on an Hypervisor hosted on a Cluster
                            data_sent = {
                               'datacenter_name'    :    current_node.attr('grand_parent_name'),
                               'cluster_name'       :    current_node.attr('parent_name'),
                               'hypervisor_name'    :    current_node.attr('name'),
                            };
                            grandParentNodeTreeName = null;
                        }
                        else if ( current_node.attr('treeType') == 'hypervisor' ) {
                            //Retrieve Virtual Machines on an Hypervisor hosted on a Datacenter
                            data_sent = {
                               'datacenter_name'    :    current_node.attr('parent_name'),
                               'hypervisor_name'    :    current_node.attr('name'),
                            };
                            grandParentNodeTreeName = null;
                        }
                    }

                    return data_sent;
                },
                'success'   :   function (returnedData) {
                    var returnedFormattedData = buildNodes(
                            returnedData,
                            parentNodeTreeName,
                            parentNodeTreeType,
                            grandParentNodeTreeName
                        );

                    return returnedFormattedData;
                },
//TODO  Implement error function
//                'error' :   function () {
//
//                },
            },
        },
    });

    browser.dialog({
        title   :   'VMware Browser',
        modal   :   true,
//TODO width's value in CSS rather specifing it here
        width   :   '400 px',
        buttons :   {
            Cancel: function () {
                $(this).dialog('close');
            },
            Submit: function () {
                var firstLevelTree = $(tree_container).children('ul').children('li');
                var formattedCheckedNodes = formatCheckedNodes(firstLevelTree);
console.log(formattedCheckedNodes);
//TODO Check length if > 0
                //Send Formatted checked nodes to API to be inserted in Kanopya Database
/*
                $.ajax({
                    type    :   'POST',
                    url     :   url_base + '/register',
                    data    :   {
                        'register_items'    :   formattedCheckedNodes,
                    },
                }).done(function (success_msg){
                    alert ('Data imported successfully ' + success_msg);
                }).fail(function (error_msg){
                    alert ('Error in data import ' + error_msg);
                });
*/
                $(this).dialog('close');
            },
        },
        close : function (event, ui) {
            $(this).remove();
        }
    });
}
