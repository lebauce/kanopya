require('common/grid.js');
require('common/workflows.js');
require('common/formatters.js');
require('common/service_common.js');

var rulestates = ['enabled','disabled'];
var comparators = ['<','>'];

// Manage creation or edition of condition (node or service)
function conditionDialog(sp_id, condition_type, fields, editid) {
    $('*').addClass('cursor-wait');

    // Get info of selected item (edit mode)
    var elem_data;
    if (editid) {
        $.ajax({
           url      : '/api/' + condition_type + '/' + editid + '?expand=right_combination',
           async    : false,
           success  : function(cond) {
               elem_data = cond;
           }
        });
    }

    var dial = $('<div>');
    var form = $('<form>').appendTo(dial).submit(submitForm);

    // Submit the form (create or update)
    // Also manage creation of associated rule
    function submitForm() {
        // remove hidden element from form (unused fields depending on condition type)
        $(this).find('.hidden').remove();
        var inputs  = $(this).serialize();
        inputs      += '&'+fields.serviceprovider+'='+sp_id;
        $.ajax({
            type    : (editid ? 'PUT' : 'POST'),
            url     : (editid ? '/api/'+condition_type+'/'+editid : '/api/'+condition_type),
            data    : inputs,
            error   : function(error) { alert(error.responseText) },
            success : function(condition) {
                // Manage creation of associated rule
                if (form.find('#create_rule_check').attr('checked')) {
                    var field_prefix = condition_type.replace('condition', '_rule');
                    var data = {};
                    data[field_prefix + '_label']                = condition[fields.name];
                    data[field_prefix + '_service_provider_id']  = sp_id;
                    data[field_prefix + '_formula']              = 'id' + condition.pk;
                    data[field_prefix + '_state']                = 'enabled';
                    $.ajax({
                        url     : '/api/' + field_prefix.replace('_', ''),
                        type    : 'POST',
                        data    : data,
                        success : function() { reloadVisibleGrids() }
                    });
                } else {
                    reloadVisibleGrids();
                }
            }
        });
        return false;
    }

    function checkUnit() {
        var right_unit  = form.find('#right_unit').text();
        var unit_warn   = form.find('#unit_warning');
        if (right_unit && form.find('#left_unit').text() !== right_unit) {
            unit_warn.text('warning : not the same unit ('+right_unit+')');
            unit_warn.show();
        } else {
            unit_warn.hide();
        }
    }

    // Name input
    if (!editid) {
        form.append($('<label>', {'for':'name_input', html:'Name : '}))
            .append($('<input>', {type:'text', name:fields.name, id:'name_input'})).append('<br>');
    }

    // Condition type
    var type_select = $('<select>', {id:'type_select'})
        .append($('<option>', {value:'cond_thresh', html:'Threshold condition'}))
        .append($('<option>', {value:'cond_combi',  html:'Combinations comparison'}))
        .change(function() {
            $('.cond_view').toggleClass('hidden');
            if ($('#view_cond_combi').is(':visible')) {
                $('#view_cond_combi select').change();
            } else {
                form.find('#right_unit').empty();
                form.find('#unit_warning').hide();
            }
        });
    form.append($('<label>', {'for':'type_select', html:'Type : '})).append(type_select);
    form.append('<br>').append('<br>');

    // Left operand
    var left_operand_select = $('<select>', {name : 'left_combination_id'}).appendTo(form);
    left_operand_select.change(function() {
        var combi_id = $(this).find('option:selected').val();
        $.get('/api/combination/'+combi_id+'?expand=unit').success(function(combi) {
           form.find('#left_unit').text(combi.unit);
           checkUnit();
        });
    });

    // Operator
    var operator_select = $('<select>', {name:fields.operator}).appendTo(form);
    $.each(['>', '<', '==', '>=', '<='], function(i,v) { operator_select.append($('<option>', {value:v, html:v})) });

    // Condition specific fields (depending on condition type)
    // 1 - type threshold
    var right_threshold_input = $('<input>', {type : 'text', name:fields.threshold});
    $('<span>', {id : 'view_cond_thresh', 'class':'cond_view hidden'}).append(
            right_threshold_input
    ).appendTo(form);
    // 2 - type combination
    var right_combi_select               = $('<select>', {name:'right_combination_id'});
    var right_combi_select_group_node    = $('<optgroup>', {label : 'Node combinations'});
    var right_combi_select_group_service = $('<optgroup>', {label : 'Service combinations'});
    $('<span>', {id:'view_cond_combi', 'class':'cond_view hidden'}).append(
            right_combi_select.append(right_combi_select_group_node).append(right_combi_select_group_service)
    ).appendTo(form);
    right_combi_select.change(function() {
        var combi_id = $(this).find('option:selected').val();
        $.get('/api/combination/'+combi_id+'?expand=unit').success(function(combi) {
            form.find('#right_unit').text(combi.unit);
            checkUnit();
        });
    });

    // Unit info
    form.append('<br>').append($('<label>', {'for':'unit_info', html:'Unit : '}))
        .append($('<span>', {id:'left_unit'})).append($('<span>', {id:'right_unit', 'class':'hidden'}))
        .append('<br>').append($('<span>', {id:'unit_warning', 'class':'ui-state-error'}));

    // Create associated rule option
    if (!editid) {
        form.append('<br>').append('<br>');
        form.append($('<label>', {'for':'create_rule_check', html:'Create associated rule '}))
            .append($('<input>', {type:'checkbox', id:'create_rule_check'}));
    }

    // Add options to combinations selects
    // case nodemetric cond : left operand = node metric combi      #   right operand = node metric combi | service metric combi
    // case aggregate cond  : left operand = service metric combi   #   right operand = service metric combi
    var loaded = 0;
    if (condition_type === 'nodemetriccondition') {
        $.get('/api/nodemetriccombination?service_provider_id=' + sp_id).success( function(node_combinations) {
            $.each(node_combinations, function(i,combi) {
                left_operand_select.append($('<option>', {value:combi.pk, html:combi.label}));
                right_combi_select_group_node.append($('<option>', {value:combi.pk, html:combi.label}));
            });
            loaded++;
        });
    } else {loaded++}
    $.get('/api/aggregatecombination?service_provider_id=' + sp_id).success( function(service_combinations) {
        if (condition_type === 'aggregatecondition') {
            right_combi_select.empty();
            $.each(service_combinations, function(i,combi) {
                right_combi_select.append($('<option>', {value:combi.pk, html:combi.label}));
                left_operand_select.append($('<option>', {value:combi.pk, html:combi.label}));
            });
        } else {
            $.each(service_combinations, function(i,combi) {
                right_combi_select_group_service.append($('<option>', {value:combi.pk, html:combi.label}));
            });
        }
        loaded++;
    });

    // Open the dialog only when all combinations (for selects) are retrieved
    // Set the value of fields (default or according to edited condition)
    function openDialogWhenLoaded() {
        if (loaded < 2) {
            setTimeout(openDialogWhenLoaded, 10);
        } else {
            // Select default type or elem options if edit mode
            if (!editid) {
                type_select.find("option[value='cond_thresh']").attr('selected','selected');
                form.find('#view_cond_thresh').removeClass('hidden');
            } else {
                left_operand_select.find("option[value='" + elem_data.left_combination_id + "']").attr('selected','selected');
                operator_select.find("option[value='" + elem_data[fields.operator] + "']").attr('selected','selected');
                if (elem_data.right_combination.value) {
                    // combination type 1 (on threshold)
                    type_select.find("option[value='cond_thresh']").attr('selected','selected');
                    right_threshold_input.val(elem_data.right_combination.value);
                    form.find('#view_cond_thresh').removeClass('hidden');
                } else {
                    // combination type 2 (on combination)
                    type_select.find("option[value='cond_combi']").attr('selected','selected');
                    right_combi_select.find("option[value='" + elem_data.right_combination_id + "']").attr('selected','selected');
                    form.find('#view_cond_combi').removeClass('hidden');
                }
            }
            left_operand_select.change();

            // Open dialog when everything is loaded
            $('*').removeClass('cursor-wait');
            dial.dialog({
                title       : editid ? elem_data[fields.name] : 'Create condition',
                width       : '700px',
                modal       : true,
                resizable   : false,
                close       : function() { $(this).remove() },
                buttons     : {
                    'Cancel' : function() { $(this).dialog("close"); },
                    'Ok'     : function() {
                        form.submit();
                        $(this).dialog("close");
                    }
                }
            });
        }
    }
    openDialogWhenLoaded();
}

function showNodeConditionModal(sp_id, editid) {
    conditionDialog(
            sp_id,
            'nodemetriccondition',
            {
                'name'              : 'nodemetric_condition_label',
                'operator'          : 'nodemetric_condition_comparator',
                'threshold'         : 'nodemetric_condition_threshold',
                'serviceprovider'   : 'nodemetric_condition_service_provider_id'
            },
            editid
    );
}

function showServiceConditionModal(sp_id, editid) {
    conditionDialog(
            sp_id,
            'aggregatecondition',
            {
                'name'              : 'aggregate_condition_label',
                'operator'          : 'comparator',
                'threshold'         : 'threshold',
                'serviceprovider'   : 'aggregate_condition_service_provider_id'
            },
            editid
    );
}

function createNodemetricCondition(container_id, elem_id) {
    var button = $("<button>", {html : 'Add condition'});
    button.bind('click', function() {
        showNodeConditionModal(elem_id);
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

/*
 * Allow clone and import of objects in a service provider (sp_id)
 * Display all object of specified type (sorted by service provider)
 * Only display service providers with the same collector manager than dest service provider
 * Allow user to select objects and import them
 *
 * @param container_id id of the dom elment to add the import button
 * @param sp_id        id of the service provider where to import selected objects
 * @param obj_info     hash of type info of objects to import :
 *      type        : object type (format as table name). Used also to compute object api route (by removing '_')
 *      name        : object user friendly name
 *      relation    : relationship name from service provider to object type
 *      label_attr  : name of the object label attr
 *      desc_attr   : name of the object description attr
 * @param grid_ids     list of id of grid to refresh after import
 */
function importItemButton(container_id, sp_id, obj_info, grid_ids) {
    var collector_manager_id;

    function loadItemTree() {
        // Build items tree
        var items_tree = [];
        var sp_treated = 0;

        function addServiceProviderItems(i,sp) {
            // Do not list destination service provider
            if (sp.pk != sp_id) {
                // List only service providers with the same collector manager than dest service provider
                $.get('/api/serviceprovider/' + sp.pk + '/service_provider_managers?manager_type=collector_manager')
                .success(function(manager) {
                    if (manager.length > 0 && manager[0].manager_id === collector_manager_id) {
                        // Get related items and add them to the tree
                        $.get('/api/serviceprovider/' + sp.pk + '/' + obj_info.relation).success( function(related) {
                            var items = [];
                            $.each(related, function(i,item) {
                                items.push({
                                    data : item[obj_info.label_attr],
                                    attr : {
                                        item_id     : item.pk,
                                        item_desc   : item[obj_info.desc_attr]
                                    }
                                });
                            });
                            // Add only service with items
                            if (items.length > 0) {
                                items_tree.push( {
                                    data        : sp.label,
                                    children    : items
                                } );
                            }
                            sp_treated++;
                        });
                    } else { sp_treated++ }
                });
            } else { sp_treated++ }
        }

        $.get('/api/serviceprovider').success( function(serviceproviders) {
            var sp_count   = serviceproviders.length;

            $.each(serviceproviders, addServiceProviderItems);

           // Wait end of tree building and then display tree
            function displayTree() {
                if (sp_count == sp_treated) {
                    var browser = $('<div>');
                    var msg     = $('<span>', {
                        html : 'Select '
                                + obj_info.name
                                + 's to import from existing services.<br>Both services must have the same collector manager.'
                    });
                    browser.append(msg).append($('<hr>'));
                    var tree_cont   = $('<div>', {style : 'height:300px;overflow:auto'}).appendTo(browser);
                    var item_detail = $('<div>').appendTo(browser);
                    require('jquery/jquery.jstree.js');
                    tree_cont.jstree({
                        "plugins"   : ["themes","json_data", "ui", "checkbox"],
                        "themes"    : {
                            url : "css/jstree_themes/default/style.css",
                            icons : false
                        },
                        "json_data" : {
                            "data"                  : items_tree,
                            "progressive_render"    : true
                        }
                    }).bind("hover_node.jstree", function (event, data) {
                        var node = data.rslt.obj;
                        if (node.attr('item_id')) {
                            item_detail.html('Description: ' + node.attr("item_desc"));
                        }
                    }).bind("dehover_node.jstree", function (event, data) {
                        item_detail.html('');
                    });

                    function importChecked() {
                        var checked_items = tree_cont.jstree('get_checked',null,true)
                        var treated_count = 0;
                        checked_items.each( function() {
                            var item_id     = $(this).attr('item_id');
                            var obj_route   = obj_info.type.replace(/_/g,'');
                            var data        = {service_provider_id : sp_id};
                            data[obj_info.type + '_id'] = item_id;
                            if (item_id) {
                                $.ajax({
                                    type    : 'POST',
                                    url     : '/api/' + obj_route,
                                    data    : data,
                                    success : function () { treated_count++ },
                                    error   : function (error) {alert(error.responseText)}
                                });
                            } else {
                                treated_count++;
                            }
                        });
                        function endImport() {
                            if (treated_count == checked_items.length) {
                                $.each(grid_ids, function(i,grid_id) {
                                    $('#'+grid_id).trigger('reloadGrid');
                                });
                                browser.dialog("close");
                            } else {
                                setTimeout(endImport, 10);
                            }
                        }
                        endImport();
                    }

                    // Show dialog
                    browser.dialog({
                        title   : 'Import ' + obj_info.name + 's',
                        modal   : true,
                        width   : '400px',
                        buttons : {
                            'Import' : importChecked,
                            'Cancel' : function () {
                                $(this).dialog("close");
                            }
                        },
                        close: function (event, ui) {
                            $(this).remove();
                        }
                    });
                } else {
                    setTimeout(displayTree, 10);
                }
            }
            displayTree()
        });
    }

    // Retrieve collector manager id (used to check available service providers for import)
    // Add import button only if there is a linked collector manager
    $.get('/api/serviceprovider/' + sp_id + '/service_provider_managers?manager_type=collector_manager')
    .success(function(manager) {
        if (manager.length > 0) {
            collector_manager_id = manager[0].manager_id;

            // Create and bind import button
            $("<button>", {html : 'Import ' + obj_info.name + 's'})
            .button({ icons : { primary : 'ui-icon-plusthick' } })
            .appendTo('#' + container_id)
            .click( loadItemTree );
        }
    });
}

function createNodemetricRule(container_id, elem_id) {
    var service_fields  = {
        nodemetric_rule_label    : {
            label   : 'Name',
            type    : 'text',
        },
        nodemetric_rule_description    : {
            label   : 'Description',
            type    : 'textarea',
        },
        nodemetric_rule_formula : {
            label   : 'Formula',
            type    : 'text',   
        },
        nodemetric_rule_state   :{
            label   : 'Enabled',
            type    : 'select',
            options   : rulestates,
        },
        nodemetric_rule_service_provider_id :{
            type    : 'hidden',
            value   : elem_id,
        },
    };
    var service_opts    = {
        title       : 'Create a Rule',
        name        : 'nodemetricrule',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            $('#service_resources_nodemetric_rules_' + elem_id).trigger('reloadGrid');
        }
    };

    var button = $("<button>", {html : 'Add a rule'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();

        $(function() {
            var availableTags = new Array();
            $.ajax({
                url: '/api/nodemetriccondition?nodemetric_condition_service_provider_id=' + elem_id + '&dataType=jqGrid',
                async   : false,
                success: function(answer) {
                            $(answer.rows).each(function(row) {
                            var pk = answer.rows[row].pk;
                            availableTags.push({label : answer.rows[row].nodemetric_condition_label, value : answer.rows[row].nodemetric_condition_id});
                        });
                    }
            });

            makeAutocompleteAndTranslate($( "#input_nodemetric_rule_formula" ), availableTags);

        });

    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceCondition(container_id, elem_id) {
    var button = $("<button>", {html : 'Add a Service Condition'});
    button.bind('click', function() {
        showServiceConditionModal(elem_id);
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceRule(container_id, elem_id) {
    var service_fields  = {
        aggregate_rule_label    : {
            label   : 'Name',
            type    : 'text',
        },
        aggregate_rule_description  :{
            label   : 'Description',
            type    : 'textearea',  
        },
        aggregate_rule_formula :{
            label   : 'Formula',
            type    : 'text',
        },
        aggregate_rule_state    :{
            label   : 'Enabled',
            type    : 'select',
            options   : rulestates, 
        },
        aggregate_rule_service_provider_id  :{
            type    : 'hidden',
            value   : elem_id,
        },
    };
    var service_opts    = {
        title       : 'Create a Rule',
        name        : 'aggregaterule',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            $('#service_resources_aggregate_rules_' + elem_id).trigger('reloadGrid');
        }
    };

    var button = $("<button>", {html : 'Add a Rule'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();

        $(function() {
            var availableTags = new Array();
            $.ajax({
                url: '/api/aggregatecondition?aggregate_condition_service_provider_id=' + elem_id + '&dataType=jqGrid',
                async   : false,
                success: function(answer) {
                            $(answer.rows).each(function(row) {
                            var pk = answer.rows[row].pk;
                            availableTags.push({label : answer.rows[row].aggregate_condition_label, value : answer.rows[row].aggregate_condition_id});
                        });
                        availableTags.join("AND","OR");
                    }
            });

            makeAutocompleteAndTranslate( $( "#input_aggregate_rule_formula" ), availableTags );

        });

    
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);  
};

function loadServicesRules (container_id, elem_id, ext, mode_policy) {
    var container = $("#" + container_id);

    ext = ext || '';

    ////////////////////////RULES ACCORDION//////////////////////////////////
            
    var divacc = $('<div id="accordionrule">').appendTo(container);
    $('<h3><a href="#">Node</a></h3>').appendTo(divacc);
    $('<div id="node_accordion_container">').appendTo(divacc);
    // Display nodemetric conditions
    var serviceNodemetricConditionsGridId = 'service_resources_nodemetric_conditions_' + elem_id;
    var serviceNodemetricRulesGridId = 'service_resources_nodemetric_rules_' + elem_id;
    create_grid( {
        caption: 'Conditions',
        url: '/api/serviceprovider/' + elem_id + '/nodemetric_conditions',
        content_container_id: 'node_accordion_container',
        grid_id: serviceNodemetricConditionsGridId,
        afterInsertRow: function(grid, rowid, rowdata) {
            setCellWithRelatedValue(
                    '/api/combination/' +  rowdata.left_combination_id,
                    grid, rowid, 'left_combination_id', 'label'
            );
            setCellWithRelatedValue(
                    '/api/combination/' +  rowdata.right_combination_id,
                    grid, rowid, 'right_combination_id', 'label'
            );
        },
        colNames: [ 'id', 'name', 'left operand', 'comparator', 'right operand' ],
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 200 },
            { name: 'left_combination_id', index: 'left_combination_id', width: 100 },
            { name: 'nodemetric_condition_comparator', index: 'nodemetric_condition_comparator', width: 50,},
            { name: 'right_combination_id', index: 'right_combination_id', width: 100 },
        ],
        details: {
            onSelectRow : function(eid) { showNodeConditionModal(elem_id, eid); }
        },
        action_delete: {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/nodemetriccondition/', id, [serviceNodemetricConditionsGridId, serviceNodemetricRulesGridId]);
            }
        },
    } );
    createNodemetricCondition('node_accordion_container', elem_id)
    
    // Display nodemetric rules
    $("<p>").appendTo('#node_accordion_container');
    create_grid( {
        caption: 'Rules',
        url: '/api/serviceprovider/' + elem_id + '/nodemetric_rules',
        content_container_id: 'node_accordion_container',
        grid_id: serviceNodemetricRulesGridId,
        grid_class: 'service_resources_nodemetric_rules',
        afterInsertRow: function(grid, rowid, rowdata) {
            // Workflow name
            if (rowdata.workflow_def_id) {
                setCellWithRelatedValue(
                        '/api/workflowdef/' + rowdata.workflow_def_id,
                        grid, rowid, 'workflow_def_id', 'workflow_def_name');
            }
        },
        colNames: [ 'id', 'name', 'enabled', 'formula', 'description', 'trigger' ],
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_rule_label', index: 'nodemetric_rule_label', width: 120 },
            { name: 'nodemetric_rule_state', index: 'nodemetric_rule_state', width: 60,},
            { name: 'formula_label', index: 'formula_label', width: 120 },
            { name: 'nodemetric_rule_description', index: 'nodemetric_rule_description', width: 120 },
            { name: 'workflow_def_id', index: 'workflow_def_id', width: 120 },
        ],
        details: {
            tabs : [
                        { label : 'Overview', id : 'overview', onLoad : function(cid, eid) {
                            $.ajax({
                                url     : '/api/nodemetricrule/' + eid,
                                success : function(data) {
                                    var container   = $('#' + cid);
                                    var p           = $('<p>', { text : data.nodemetric_rule_label + " : " + data.nodemetric_rule_description });
                                    $(container).prepend(p);
                                    if (data.workflow_def_id != null) {
                                        $.ajax({
                                            url     : '/api/workflowdef/' + data.workflow_def_id,
                                            success : function(wfdef) {
                                                $(p).html($(p).html() + '<br /><br />Associated workflow : ' + wfdef.workflow_def_name);
                                                appendWorkflowActionsButtons(p, cid, eid, data.workflow_def_id, elem_id);
                                            }
                                        });
                                    } else {
                                        createWorkflowRuleAssociationButton(cid, eid, 1, elem_id);
                                    }
                                }
                            });
                        }},
                        { label : 'Nodes', id : 'nodes', onLoad : function(cid, eid) { rule_nodes_tab(cid, eid, elem_id); }, hidden : mode_policy },
                    ],
            title : { from_column : 'nodemetric_rule_label' },
            onClose : function() {$('#'+serviceNodemetricRulesGridId).trigger('reloadGrid')}
        },
        action_delete: {
            url : '/api/nodemetricrule'
        },
    } );
    
    createNodemetricRule('node_accordion_container', elem_id);
    if (!mode_policy) {
        importItemButton(
                'node_accordion_container',
                elem_id,
                {
                    name        : 'node rule',
                    relation    : 'nodemetric_rules',
                    label_attr  : 'nodemetric_rule_label',
                    desc_attr   : 'nodemetric_rule_description',
                    type        : 'nodemetric_rule'
                },
                [serviceNodemetricConditionsGridId, serviceNodemetricRulesGridId]
        );
    }

    // Here's the second part of the accordion :
    $('<h3><a href="#">Service</a></h3>').appendTo(divacc);
    $('<div id="service_accordion_container">').appendTo(divacc);
    // Display service conditions :
    var serviceAggregateConditionsGridId = 'service_resources_aggregate_conditions_' + elem_id;
    var serviceAggregateRulesGridId = 'service_resources_aggregate_rules_' + elem_id;
    create_grid( {
        caption: 'Conditions',
        url: '/api/serviceprovider/' + elem_id + '/aggregate_conditions',
        content_container_id: 'service_accordion_container',
        grid_id: serviceAggregateConditionsGridId,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            setCellWithRelatedValue(
                    '/api/combination/' +  rowdata.left_combination_id,
                    grid, rowid, 'left_combination_id', 'label'
            );
            setCellWithRelatedValue(
                    '/api/combination/' +  rowdata.right_combination_id,
                    grid, rowid, 'right_combination_id', 'label'
            );
        },
        colNames: ['id','name', 'left operand', 'comparator', 'right operand'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_condition_label',index:'aggregate_condition_label', width:200,},
             {name:'left_combination_id',index:'left_combination_id', width:100,},
             {name:'comparator',index:'comparator', width:50,},
             {name:'right_combination_id',index:'right_combination_id', width:100,},
           ],
        details: { onSelectRow : function(eid) { showServiceConditionModal(elem_id, eid); } },
        action_delete: {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/aggregatecondition/', id, [serviceAggregateConditionsGridId, serviceAggregateRulesGridId]);
            }
        },
    } );
    createServiceCondition('service_accordion_container', elem_id);

    // Display services rules :
    $("<p>").appendTo('#service_accordion_container');
    create_grid( {
        caption: 'Rules',
        url: '/api/serviceprovider/' + elem_id + '/aggregate_rules',
        grid_class: 'service_resources_aggregate_rules',
        content_container_id: 'service_accordion_container',
        grid_id: serviceAggregateRulesGridId,
        colNames: ['id','name', 'enabled', 'last eval', 'formula', 'description', 'trigger'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_rule_label',index:'aggregate_rule_label', width:90,},
             {name:'aggregate_rule_state',index:'aggregate_rule_state', width:90,},
             {name:'aggregate_rule_last_eval',index:'aggregate_rule_last_eval', width:90, formatter : lastevalStateFormatter, hidden:mode_policy},
             {name:'formula_label',index:'formula_label', width:90,},
             {name:'aggregate_rule_description',index:'aggregate_rule_description', width:200,},
             {name: 'workflow_def_id', index: 'workflow_def_id', width: 120 },
           ],
        afterInsertRow: function(grid, rowid, rowdata) {
            // Workflow name
            if (rowdata.workflow_def_id) {
                setCellWithRelatedValue(
                        '/api/workflowdef/' + rowdata.workflow_def_id,
                        grid, rowid, 'workflow_def_id', 'workflow_def_name');
            }
        },
        details : {
            tabs    : [
                { label : 'Overview', id : 'overview', onLoad : function(cid, eid) {
                    $.ajax({
                        url     : '/api/aggregaterule/' + eid,
                        success : function(data) {
                                    var container   = $('#' + cid);
                                    var p           = $('<p>', { text : data.aggregate_rule_label + " : " + data.aggregate_rule_description });
                                    $(container).prepend(p);
                                    if (data.workflow_def_id != null) {
                                        $.ajax({
                                            url     : '/api/workflowdef/' + data.workflow_def_id,
                                            success : function(wfdef) {
                                                $(p).html($(p).html() + '<br /><br />Associated workflow : ' + wfdef.workflow_def_name);
                                                appendWorkflowActionsButtons(p, cid, eid, data.workflow_def_id, elem_id);
                                            }
                                        });
                                    } else {
                                        createWorkflowRuleAssociationButton(cid, eid, 2, elem_id);
                                    }
                        }
                    });
               }},
            ],
            title   : { from_column : 'aggregate_rule_label' },
            onClose : function() {$('#'+serviceAggregateRulesGridId).trigger('reloadGrid')}
        },
        action_delete: {
            url : '/api/aggregaterule',
        },
    } );
    createServiceRule('service_accordion_container', elem_id);
    if (!mode_policy) {
        importItemButton(
                'service_accordion_container',
                elem_id,
                {
                    name        : 'service rule',
                    relation    : 'aggregate_rules',
                    label_attr  : 'aggregate_rule_label',
                    desc_attr   : 'aggregate_rule_description',
                    type        : 'aggregate_rule'
                },
                [serviceAggregateConditionsGridId, serviceAggregateRulesGridId]
        );
    }

    $('#accordionrule').accordion({
        autoHeight  : false,
        active      : false,
        change      : function (event, ui) {
            // Set all grids size to fit accordion content
            ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
        }
    });
    
    ////////////////////////END OF : RULES ACCORDION//////////////////////////////////
}


// This function load a grid with the list of current service's nodes for state corelation with rules
function rule_nodes_tab(cid, rule_id, service_provider_id) {
    
    function verifiedRuleNodesStateFormatter(cell, options, row) {
        var VerifiedRuleFormat;
            // Where rowid = rule_id
            
            $.ajax({
                 url: '/api/externalnode/' + row.pk + '/verified_noderules?verified_noderule_nodemetric_rule_id=' + rule_id,
                 async: false,
                 success: function(answer) {
                    if (answer.length == 0) {
                        VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                    } else if (answer[0].verified_noderule_state == undefined) {
                        VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                    } else if (answer[0].verified_noderule_state == 'verified') {
                        VerifiedRuleFormat = "<img src='/images/icons/broken.png' title='broken' />";
                    } else if (answer[0].verified_noderule_state == 'undef') {
                        VerifiedRuleFormat = "<img src='/images/icons/down.png' title='down' />";
                    }
                  }
            });
        return VerifiedRuleFormat;
    }
//         url: '/api/externalnode/' + eid,
    
    var loadNodeRulesTabGridId = 'rule_nodes_tabs';
    create_grid( {
        url: '/api/externalnode?externalnode_state=<>,disabled&service_provider_id=' + service_provider_id,
        content_container_id: cid,
        grid_id: loadNodeRulesTabGridId,
        grid_class: 'rule_nodes_grid',
        colNames: [ 'id', 'hostname', 'state' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'externalnode_hostname', index: 'externalnode_hostname', width: 110,},
            { name: 'verified_noderule_state', index: 'verified_noderule_state', width: 60, formatter: verifiedRuleNodesStateFormatter,}, 
        ],
        action_delete : 'no',
    } );
}
