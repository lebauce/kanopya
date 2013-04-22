require('common/grid.js');
require('common/workflows.js');
require('common/formatters.js');
require('common/service_common.js');
require('common/service_item_import.js');

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
                reloadVisibleGrids();
                // Manage creation of associated rule (show prefilled rule form)
                if (form.find('#create_rule_check').attr('checked')) {
                    var field_prefix = condition_type.replace('condition', '_rule');
                    var values = {};
                    values['rule_name'] = condition[fields.name];
                    values['formula']   = 'id' + condition.pk;
                    ruleForm(sp_id, field_prefix, null, $.noop, values);
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
        form.append($('<label>', {'for':'name_input', html:'Name : '}))
            .append($('<input>', {type:'text', name:fields.name, id:'name_input', value:editid ? elem_data[fields.name] : ''}))
            .append('<br>');

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

    // Select combination handler (manage unit)
    function onSelectCombination(e) {
        var side = e.data;
        var combi_id = $(this).find('option:selected').val();
        $.get('/api/combination/'+combi_id).success(function(combi) {
           form.find('#'+side+'_unit').text(combi.combination_unit);
           checkUnit();
        });
    }

    // Left operand
    var left_operand_select = $('<select>', {name : 'left_combination_id'}).appendTo(form);
    left_operand_select.change('left', onSelectCombination);

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
    right_combi_select.change('right', onSelectCombination);

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
                dialogClass : "no-close",
                close       : function() { $(this).remove() },
                buttons     : [
        			{id:'button-cancel',text:'Cancel',click: function() { $(this).dialog("close"); }},
        			{id:'button-ok',text:'Ok',click: function() {form.submit();$(this).dialog("close");}}
        		]
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
    var button = $("<button>", { html : 'Add condition' });
    button.bind('click', function() {
        showNodeConditionModal(elem_id);
        return false;
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

/*
 * Form for creation/edition of node and service rule
 *
 * @param    sp_id      related service provider id
 * @param    type       nodemetric_rule/aggregate_rule
 * @optional editid     id of elem if edition
 * @optional onClose    callback when form closed after request
 * @optional values     default fields values
 */

function ruleForm(sp_id, type, editid, onClose, values) {
    var def_values = {};
    $.extend(def_values, values);

    var rule_fields  = {};
    rule_fields['rule_name'] = {
        label   : 'Name',
        type    : 'text',
        value   : def_values['rule_name'],
    };
    rule_fields['description'] = {
        label   : 'Description',
        type    : 'textarea',
    };
    rule_fields['formula'] = {
        label   : 'Formula',
        type    : 'text',
        value   : def_values['formula'],
    };
    rule_fields['state'] = {
        label   : 'Enabled',
        type    : 'select',
        options : rulestates,
    };
    rule_fields['service_provider_id'] = {
        type    : 'hidden',
        value   : sp_id,
    };

    var form_opts    = {
        title       : editid ? 'Edit rule' : 'Create a rule',
        name        : type.replace('_', ''),
        fields      : rule_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function(resp,form) {
            $('#service_resources_' + type + 's_' + sp_id).trigger('reloadGrid');
            if (onClose) {onClose(form)}
        }
    };

    if (editid) {
        form_opts.id = editid;
    }

    var mod = new ModalForm(form_opts);
    mod.start();

    $(function() {
        var condition_type = type.replace('rule', 'condition');
        var availableTags = new Array();
        $.ajax({
            url     : '/api/'+condition_type.replace('_','')+'?'+condition_type+'_service_provider_id=' + sp_id + '&dataType=jqGrid',
            async   : false,
            success : function(answer) {
                $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({
                        label : answer.rows[row][condition_type + '_label'],
                        value : answer.rows[row][condition_type + '_id']
                    });
                });
            }
        });
        makeAutocompleteAndTranslate($( '#input_formula' ), availableTags);
    });
}

function createRuleButton(sp_id, type, editid, onClose) {
    var button = $("<a>", { text : editid ? 'Edit' : 'Add a rule' })
        .button({ icons : { primary : editid ? 'ui-icon-pencil' : 'ui-icon-plusthick' } })
        .click(function() {
            ruleForm(sp_id, type, editid, onClose);
            return false;
        });
    return button;
}

function createServiceCondition(container_id, elem_id) {
    var button = $("<button>", {html : 'Add a Service Condition'});
    button.bind('click', function() {
        showServiceConditionModal(elem_id);
        return false;
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

var filterNotifyWorkflow    = function(grid, rowid) {
    var workflowname    = ($(grid).getRowData(rowid)).workflow_def_id;
    if (notifyworkflow_regex.exec(workflowname) != null) {
        $(grid).setCell(rowid, "workflow_def_id", " ");
    }
};

function loadServicesRules (container_id, elem_id, ext, mode_policy) {
    var container = $("#" + container_id);

    ext = ext || '';

    var displayAssociationButton = function(cid, eid, type) {
        return createWorkflowRuleAssociationButton(cid, eid, type == 'nodemetric_rule' ? 1 : 2, elem_id);
    }

    var associateTimePeriod = function (type) {
        return {
            label       : 'Associate time periods',
            action      : function (grid_id, rowid, url, method, extraParams, afterAction, data) {
                $.ajax({
                    url : "/api/" + type + "/" + rowid,
                    type : "PUT",
                    contentType : 'application/json',
                    data : JSON.stringify(data)
                });
            },
            url         : '/api/' + type,
            icon        : 'ui-icon-clock',
            extraParams : { multiselect : true },
            confirm     : function (grid, label, selection, callback) {
                (new KanopyaFormWizard({
                    title      : label,
                    type       : type,
                    id         : undefined,
                    displayed  : [ "entity_time_periods" ],
                    attrsCallback  : function (type, data, trigger) {
                        var attrs = this.getAttributes(type, data, trigger);
                        attrs.attributes = {
                            "entity_time_periods" : attrs.attributes.entity_time_periods
                        };
                        attrs.relations = {
                            "entity_time_periods" : attrs.relations.entity_time_periods
                        };
                        return attrs;
                    },
                    submitCallback : function (data, form, opts) {
                        callback(data);
                        this.closeDialog();
                    }
                })).start();
            }
        };
    }

    var ruleDetails = function(cid, eid, type) {
        var wizard = new KanopyaFormWizard({
            title      : 'Rule details',
            type       : type.replace('_', ''),
            id         : eid,
            displayed  : [ "description", "formula_label", "entity_time_periods" ],
            actionsCallback : function (data) {
                var buttons = [];
                if (data.workflow_def_id != null) {
                    $.ajax({
                        url     : '/api/workflowdef/' + data.workflow_def_id,
                        async   : false,
                        success : function (wfdef) {
                            if (notifyworkflow_regex.exec(wfdef.workflow_def_name) == null) {
                                var p = $('<p>', { text : 'Associated workflow : ' + wfdef.workflow_def_name });
                                appendWorkflowActionsButtons(p, cid, eid, data.workflow_def_id, elem_id);
                                buttons.push(p);
                                buttons.push($("<br>"));
                            } else {
                                buttons.push(displayAssociationButton(cid, eid, type));
                            }
                        }
                    });
                } else {
                    buttons.push(displayAssociationButton(cid, eid, type));
                }
                buttons.push(createRuleButton(elem_id, type, eid, function(form) {
                    // Update overview content
                    if (cid) reload_content(cid, eid);
                    // Update dialog title
                    var rule_label = form.find('#input_' + type + '_label').val();
                    container.parents('.ui-dialog').find('.ui-dialog-title').html(rule_label);
                }));
                return buttons;
            },
            attrsCallback  : function (type, data, trigger) {
                var attrs = this.getAttributes(type, data, trigger);
                var attributes = attrs.attributes;
                attrs.attributes = { };
                for (var i = 0; i < this.displayed.length; i++) {
                    attrs.attributes[this.displayed[i]] = attributes[this.displayed[i]];
                }
                attrs.relations = {
                    "entity_time_periods" : attrs.relations.entity_time_periods
                };
                return attrs;
            },
        });

        if (cid) {
            $('#' + cid).append(wizard.content);
            wizard.startWizard();
        } else {
            wizard.start();
        }

        return wizard;
    }

    ////////////////////////RULES ACCORDION//////////////////////////////////

    var divacc = $('<div id="accordionrule">').appendTo(container);
    $('<h3><a href="#">Node</a></h3>').appendTo(divacc);

    var  node_accordion_container = $('<div id="node_accordion_container">');
    divacc.append(
        node_accordion_container.append(
            $('<div>')
                .append( $('<div>', {id : 'service_nodemetric_conditions_action_buttons', class : 'action_buttons'}) )
                .append( $('<div>', {id : 'service_nodemetric_conditions_container'}) )
        )
    );

    // Display nodemetric conditions
    var serviceNodemetricConditionsGridId = 'service_resources_nodemetric_conditions_' + elem_id;
    var serviceNodemetricRulesGridId = 'service_resources_nodemetric_rules_' + elem_id;

    createNodemetricCondition('service_nodemetric_conditions_action_buttons', elem_id);
    create_grid( {
        caption: 'Conditions',
        url: '/api/serviceprovider/' + elem_id + '/nodemetric_conditions?expand=left_combination,right_combination',
        content_container_id: 'service_nodemetric_conditions_container',
        grid_id: serviceNodemetricConditionsGridId,
        colNames: [ 'id', 'Name', 'Left operand', 'Comparator', 'Right operand' ],
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 200 },
            { name: 'left_combination.label', index: 'left_combination_id', width: 100 },
            { name: 'nodemetric_condition_comparator', index: 'nodemetric_condition_comparator', width: 50,},
            { name: 'right_combination.label', index: 'right_combination_id', width: 100 },
        ],
        details: {
            onSelectRow : function(eid) { showNodeConditionModal(elem_id, eid); }
        },
        action_delete: {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/nodemetriccondition/', id, [serviceNodemetricConditionsGridId, serviceNodemetricRulesGridId]);
            }
        },
        multiselect : true,
        multiactions : {
            multiDelete : {
                label       : 'Delete node condition(s)',
                action      : removeGridEntry,
                url         : '/api/nodemetriccondition',
                icon        : 'ui-icon-trash',
                extraParams : {multiselect : true}
            }
        }
    } );

    // Display nodemetric rules
    $("<p>").appendTo('#node_accordion_container');
    node_accordion_container.append(
        $('<div>')
            .append( $('<div>', {id : 'service_nodemetric_rules_action_buttons', class : 'action_buttons'}) )
            .append( $('<div>', {id : 'service_nodemetric_rules_container'}) )
    );

    $('#service_nodemetric_rules_action_buttons').append(createRuleButton(elem_id, 'nodemetric_rule'));

    if (!mode_policy) {
        importItemButton(
                node_accordion_container.find('#service_nodemetric_rules_action_buttons'),
                elem_id,
                {
                    name        : 'node rule',
                    label_attr  : 'label',
                    desc_attr   : 'description',
                    type        : 'nodemetric_rule'
                },
                [serviceNodemetricConditionsGridId, serviceNodemetricRulesGridId]
        );
    }
    var _wizard = undefined;
    create_grid( {
        caption: 'Rules',
        url: '/api/nodemetricrule?service_provider_id=' + elem_id,
        content_container_id: 'service_nodemetric_rules_container',
        grid_id: serviceNodemetricRulesGridId,
        grid_class: 'service_resources_nodemetric_rules',
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            // Workflow name
            if (rowdata.workflow_def_id) {
                setCellWithRelatedValue(
                        '/api/workflowdef/' + rowdata.workflow_def_id,
                        grid, rowid, 'workflow_def_id', 'workflow_def_name', filterNotifyWorkflow);
            }
            require('common/notification_subscription.js');
            addSubscriptionButtonInGrid(grid, rowid, rowdata, rowelem, "service_resources_nodemetric_rules_" +  elem_id +"_alert", "ProcessRule", false);
        },
        colNames: [ 'id', 'Name', 'Enabled', 'Formula', 'Description', 'Trigger', 'Alert' ],
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'label', index: 'label', width: 120 },
            { name: 'state', index: 'state', width: 60,},
            { name: 'formula_label', index: 'formula_label', width: 120 },
            { name: 'description', index: 'description', width: 120 },
            { name: 'workflow_def_id', index: 'workflow_def_id', width: 120 },
            { name: 'alert', index: 'alert', width: 40, align: 'center', nodetails: true }
        ],
        details: {
            onOk : function () {
                if (_wizard != undefined) {
                    _wizard.validateForm();
                }
            },
            tabs : [ {
                label : 'Overview',
                id : 'overview',
                onLoad : function (cid, eid) {
                    _wizard = ruleDetails(cid, eid, 'nodemetric_rule');
                },
            }, {
                label : 'Nodes',
                id : 'nodes',
                onLoad : function(cid, eid) {
                    rule_nodes_tab(cid, eid, elem_id);
                    _wizard = undefined;
                },
                hidden : mode_policy
            } ],
            title : {
                from_column : 'label'
            },
            onClose : function() {
                $('#' + serviceNodemetricRulesGridId).trigger('reloadGrid')
            }
        },
        action_delete: {
            url : '/api/nodemetricrule'
        },
        multiselect : true,
        multiactions : {
            multiDelete : {
                label       : 'Delete node rule(s)',
                action      : removeGridEntry,
                url         : '/api/nodemetricrule',
                icon        : 'ui-icon-trash',
                extraParams : {multiselect : true}
            },
            'associateTimePeriod' : associateTimePeriod('nodemetricrule')
        }
    } );

    // Here's the second part of the accordion :
    $('<h3><a href="#">Service</a></h3>').appendTo(divacc);

    var  service_accordion_container = $('<div id="service_accordion_container">');
    divacc.append(
        service_accordion_container.append(
            $('<div>')
                .append( $('<div>', {id : 'service_resources_aggregate_conditions_action_buttons', class : 'action_buttons'}) )
                .append( $('<div>', {id : 'service_resources_aggregate_conditions_container'}) )
        )
    );

    // Display service conditions :
    var serviceAggregateConditionsGridId = 'service_resources_aggregate_conditions_' + elem_id;
    var serviceAggregateRulesGridId = 'service_resources_aggregate_rules_' + elem_id;

    createServiceCondition('service_resources_aggregate_conditions_action_buttons', elem_id);
    create_grid( {
        caption: 'Conditions',
        url: '/api/serviceprovider/' + elem_id + '/aggregate_conditions?expand=left_combination,right_combination',
        content_container_id: 'service_resources_aggregate_conditions_container',
        grid_id: serviceAggregateConditionsGridId,
        colNames: [ 'id', 'Name', 'Left operand', 'Comparator', 'Right operand' ],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_condition_label',index:'aggregate_condition_label', width:200,},
             {name:'left_combination.label',index:'left_combination_id', width:100,},
             {name:'comparator',index:'comparator', width:50,},
             {name:'right_combination.label',index:'right_combination_id', width:100,},
           ],
        details: { onSelectRow : function(eid) { showServiceConditionModal(elem_id, eid); } },
        action_delete: {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/aggregatecondition/', id, [serviceAggregateConditionsGridId, serviceAggregateRulesGridId]);
            }
        },
        multiselect : true,
        multiactions : {
            multiDelete : {
                label       : 'Delete service condition(s)',
                action      : removeGridEntry,
                url         : '/api/aggregatecondition',
                icon        : 'ui-icon-trash',
                extraParams : {multiselect : true}
            }
        }
    } );

    // Display services rules :
    $("<p>").appendTo('#service_accordion_container');
    service_accordion_container.append(
        $('<div>')
            .append( $('<div>', {id : 'service_resources_aggregate_rules_action_buttons', class : 'action_buttons'}) )
            .append( $('<div>', {id : 'service_resources_aggregate_rules_container'}) )
    );

    $('#service_resources_aggregate_rules_action_buttons').append(createRuleButton(elem_id, 'aggregate_rule'));

    if (!mode_policy) {
        importItemButton(
                service_accordion_container.find('#service_resources_aggregate_rules_action_buttons'),
                elem_id,
                {
                    name        : 'service rule',
                    label_attr  : 'label',
                    desc_attr   : 'description',
                    type        : 'aggregate_rule'
                },
                [serviceAggregateConditionsGridId, serviceAggregateRulesGridId]
        );
    }
    create_grid( {
        caption: 'Rules',
        url: '/api/aggregaterule?service_provider_id=' + elem_id,
        grid_class: 'service_resources_aggregate_rules',
        content_container_id: 'service_resources_aggregate_rules_container',
        grid_id: serviceAggregateRulesGridId,
        colNames: [ 'id', 'Name', 'Enabled', 'Last eval', 'Formula', 'Description', 'Trigger', 'Alert' ],
        colModel: [
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'label',index:'label', width:90,},
             {name:'state',index:'state', width:50,},
             {name:'aggregate_rule_last_eval',index:'aggregate_rule_last_eval', width:50, formatter : lastevalStateFormatter, hidden:mode_policy},
             {name:'formula_label',index:'formula_label', width:150,},
             {name:'description',index:'description', width:200,},
             {name: 'workflow_def_id', index: 'workflow_def_id', width: 100 },
             {name: 'alert', index: 'alert', width: 40, align: 'center', nodetails: true }
           ],
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            // Workflow name
            if (rowdata.workflow_def_id) {
                setCellWithRelatedValue(
                        '/api/workflowdef/' + rowdata.workflow_def_id,
                        grid, rowid, 'workflow_def_id', 'workflow_def_name', filterNotifyWorkflow);
            }
            require('common/notification_subscription.js');
            addSubscriptionButtonInGrid(grid, rowid, rowdata, rowelem, "service_resources_aggregate_rules_" +  elem_id +"_alert", "ProcessRule", false);
        },
        details : {
            onSelectRow : function (elem_id, row_data, grid_id) {
                ruleDetails(undefined, elem_id, 'aggregate_rule');
                $('#' + serviceAggregateRulesGridId).trigger('reloadGrid');
            }
        },
        action_delete: {
            url : '/api/aggregaterule',
        },
        multiselect : true,
        multiactions : {
            multiDelete : {
                label       : 'Delete service rule(s)',
                action      : removeGridEntry,
                url         : '/api/aggregaterule',
                icon        : 'ui-icon-trash',
                extraParams : { multiselect : true }
            },
            'associateTimePeriod' : associateTimePeriod('aggregaterule')
        }
    } );

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
                 url: '/api/node/' + row.pk + '/verified_noderules?verified_noderule_nodemetric_rule_id=' + rule_id,
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
    
    var loadNodeRulesTabGridId = 'rule_nodes_tabs';
    create_grid( {
        url: '/api/node?monitoring_state=<>,disabled&service_provider_id=' + service_provider_id,
        content_container_id: cid,
        grid_id: loadNodeRulesTabGridId,
        grid_class: 'rule_nodes_grid',
        colNames: [ 'id', 'Hostname', 'State' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'node_hostname', index: 'node_hostname', width: 110 },
            { name: 'verified_noderule_state', index: 'verified_noderule_state', width: 60, formatter: verifiedRuleNodesStateFormatter }
        ],
        action_delete : 'no'
    } );
}
