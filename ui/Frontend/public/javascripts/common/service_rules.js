var rulestates = ['enabled','disabled'];
var comparators = ['<','>'];

    ////////////////////////NODES AND METRICS MODALS//////////////////////////////////
function nodemetricconditionmodal(elem_id, editid) {
    var service_fields  = {
        nodemetric_condition_label    : {
            label   : 'Name',
            type    : 'text',
        },
        nodemetric_condition_combination_id :{
            label   : 'Combination',
            display : 'nodemetric_combination_label',
        },
        nodemetric_condition_comparator    : {
            label   : 'Comparator',
            type    : 'select',
            options   : comparators,
        },
        nodemetric_condition_threshold: {
            label   : 'Threshold',
            type    : 'text',
        },
        nodemetric_condition_service_provider_id:{
            type: 'hidden',
            value: elem_id,
        }
    };
    var service_opts    = {
        title       : ((editid === undefined) ? 'Create' : 'Edit') + ' a Condition',
        name        : 'nodemetriccondition',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            if (editid !== undefined) {
                $.ajax({
                    url     : '/api/nodemetriccondition/' + editid + '/updateName',
                    type    : 'POST'
                });
            }
            $('#service_ressources_nodemetric_conditions_' + elem_id).trigger('reloadGrid');
        }
    };
    if (editid !== undefined) {
        service_opts.id = editid;
        service_opts.fields.nodemetric_condition_label.type = 'hidden';
    }
    (new ModalForm(service_opts)).start();
}
function createNodemetricCondition(container_id, elem_id) {
    var button = $("<button>", {html : 'Add condition'});
    button.bind('click', function() {
        nodemetricconditionmodal(elem_id);
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

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
        }
    };

    var button = $("<button>", {html : 'Add a rule'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
  
    ////////////////////////////////////// Node Rule Forumla Construciton ///////////////////////////////////////////
        
        $(function() {
    var availableTags = new Array();
    $.ajax({
        url: '/api/nodemetriccondition?dataType=jqGrid',
        async   : false,
        success: function(answer) {
                    $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({label : answer.rows[row].nodemetric_condition_label, value : answer.rows[row].nodemetric_condition_id});

                });
            }
    });

    function split( val ) {
            return val.split( / \s*/ );
        }
        function extractLast( term ) {
            return split( term ).pop();
        }

        $( "#input_nodemetric_rule_formula" )
            // don't navigate away from the field on tab when selecting an item
            .bind( "keydown", function( event ) {
                if ( event.keyCode === $.ui.keyCode.TAB &&
                        $( this ).data( "autocomplete" ).menu.active ) {
                    event.preventDefault();
                }
            })
            .autocomplete({
                minLength: 0,
                source: function( request, response ) {
                    // delegate back to autocomplete, but extract the last term
                    response( $.ui.autocomplete.filter(
                        availableTags, extractLast( request.term ) ) );
                },
                focus: function() {
                    // prevent value inserted on focus
                    return false;
                },
                select: function( event, ui ) {
                    var terms = split( this.value );
                    // remove the current input
                    terms.pop();
                    // add the selected item
                    terms.push( "id" + ui.item.value );
                    // add placeholder to get the comma-and-space at the end
                    //terms.push( "" );
                    this.value = terms;
                    this.value = terms.join(" ");
                    return false;
                }
            });
    });
    ////////////////////////////////////// END OF : Node Rule Forumla Construciton ///////////////////////////////////////////
  
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function serviceconditionmodal(elem_id, editid) {
    var service_fields  = {
        aggregate_condition_label    : {
            label   : 'Name',
            type    : 'text',
        },
        aggregate_combination_id    :{
            label   : 'Combination',
            display : 'aggregate_combination_label',
        },
        comparator  : {
            label   : 'Comparator',
            type    : 'select',
            options : comparators,
        },
        threshold:{
            label   : 'Threshold',
            type    : 'text',
        },
        state:{
            label   : 'Enabled',
            type    : 'select',
            options   : rulestates,
        },
        aggregate_condition_service_provider_id :{
            type    : 'hidden',
            value   : elem_id,
        },
    };
    var service_opts    = {
        title       : ((editid === undefined) ? 'Create' : 'Edit') + ' a Service Condition',
        name        : 'aggregatecondition',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            if (editid !== undefined) {
                $.ajax({
                    url     : '/api/aggregatecondition/' + editid + '/updateName',
                    type    : 'POST'
                });
            }
            $('#service_ressources_aggregate_conditions_' + elem_id).trigger('reloadGrid');
        }
    };
    if (editid !== undefined) {
        service_opts.id = editid;
        service_opts.fields.aggregate_condition_label.type  = 'hidden';
    }
    (new ModalForm(service_opts)).start();
}

function createServiceCondition(container_id, elem_id) {
    var button = $("<button>", {html : 'Add a Service Condition'});
    button.bind('click', function() {
        serviceconditionmodal(elem_id);
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceRule(container_id, elem_id) {
        
    var loadServicesMonitoringGridId = 'service_rule_creation_condition_listing_' + elem_id;
    create_grid( {
        url: '/api/nodemetriccondition',
        content_container_id: 'service_condition_listing_for_service_rule_creation',
        grid_id: loadServicesMonitoringGridId,
        colNames: [ 'id', 'name' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 90 },
        ],
    } );

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
        }
    };

    var button = $("<button>", {html : 'Add a Rule'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
        
    
    ////////////////////////////////////// Service Rule Forumla Construciton ///////////////////////////////////////////
    $(function() {
    var availableTags = new Array();
    $.ajax({
        url: '/api/aggregatecondition?dataType=jqGrid',
        async   : false,
        success: function(answer) {
                    $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({label : answer.rows[row].aggregate_condition_label, value : answer.rows[row].aggregate_condition_id});

                });
                availableTags.join("AND","OR");
            }
    });

    function split( val ) {
            return val.split( / \s*/ );
        }
        function extractLast( term ) {
            return split( term ).pop();
        }

        $( "#input_aggregate_rule_formula" )
            // don't navigate away from the field on tab when selecting an item
            .bind( "keydown", function( event ) {
                if ( event.keyCode === $.ui.keyCode.TAB &&
                        $( this ).data( "autocomplete" ).menu.active ) {
                    event.preventDefault();
                }
            })
            .autocomplete({
                minLength: 0,
                source: function( request, response ) {
                    // delegate back to autocomplete, but extract the last term
                    response( $.ui.autocomplete.filter(
                        availableTags, extractLast( request.term ) ) );
                },
                focus: function() {
                    // prevent value inserted on focus
                    return false;
                },
                select: function( event, ui ) {
                    var terms = split( this.value );
                    // remove the current input
                    terms.pop();
                    // add the selected item
                    terms.push( "id" + ui.item.value );
                    // add placeholder to get the comma-and-space at the end
                    //terms.push( "" );
                    this.value = terms;
                    this.value = terms.join(" ");
                    return false;
                }
            });
    });
    //////////////////////////////////////  END OF : Service Rule Forumla Construciton ///////////////////////////////////////////
    
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);  
};
    ////////////////////////END OF : NODES AND METRICS MODALS//////////////////////////////////

function loadServicesRules (container_id, elem_id, ext) {
    var container = $("#" + container_id);

    ext = ext || '';

    ////////////////////////RULES ACCORDION//////////////////////////////////
            
    var divacc = $('<div id="accordionrule">').appendTo(container);
    $('<h3><a href="#">Node</a></h3>').appendTo(divacc);
    $('<div id="node_accordion_container">').appendTo(divacc);
    // Display nodemetric conditions
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_conditions_' + elem_id;
    create_grid( {
        caption: 'Conditions',
        url: '/api/serviceprovider/' + elem_id + '/nodemetric_conditions',
        content_container_id: 'node_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid, rowdata) {
            $.ajax({
                url     : '/api/nodemetriccombination/' + rowdata.nodemetric_condition_combination_id,
                success : function(data) {
                    $(grid).setCell(rowid, 'nodemetric_condition_combination_id', data.nodemetric_combination_label);
                }
            });
        },
        colNames: [ 'id', 'name', 'combination', 'comparator', 'threshold' ],
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 120 },
            { name: 'nodemetric_condition_combination_id', index: 'nodemetric_condition_combination_id', width: 60 },
            { name: 'nodemetric_condition_comparator', index: 'nodemetric_condition_comparator', width: 60,},
            { name: 'nodemetric_condition_threshold', index: 'nodemetric_condition_threshold', width: 190 },
        ],
        details: { onSelectRow : function(eid) { nodemetricconditionmodal(elem_id, eid); } },
        action_delete: {
            url : '/api/nodemetriccondition',
        },
    } );
    createNodemetricCondition('node_accordion_container', elem_id)
    
    // Display nodemetric rules
    $("<p>").appendTo('#node_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_rules_' + elem_id;
    create_grid( {
        caption: 'Rules',
        url: '/api/serviceprovider/' + elem_id + '/nodemetric_rules',
        content_container_id: 'node_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        grid_class: 'service_ressources_nodemetric_rules',
        colNames: [ 'id', 'name', 'enabled', 'description', 'formula' ],
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/nodemetricrule/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'nodemetric_rule_formula');
        },
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_rule_label', index: 'nodemetric_rule_label', width: 120 },
            { name: 'nodemetric_rule_state', index: 'nodemetric_rule_state', width: 60,},
            { name: 'nodemetric_rule_description', index: 'nodemetric_rule_description', width: 120 },
            { name: 'nodemetric_rule_formula', index: 'nodemetric_rule_formula', width: 120 },
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
                                            }
                                        });
                                    }
                                }
                            });
                            require('KIO/workflows.js');
                            createWorkflowRuleAssociationButton(cid, eid, 1, elem_id);
                        }},
                        { label : 'Nodes', id : 'nodes', onLoad : function(cid, eid) { rule_nodes_tab(cid, eid, elem_id); } },
                    ],
            title : { from_column : 'nodemetric_rule_label' }
        },
        action_delete: {
            url : '/api/nodemetricrule',
        },
    } );
    
    createNodemetricRule('node_accordion_container', elem_id);
    // Here's the second part of the accordion :
    $('<h3><a href="#">Service</a></h3>').appendTo(divacc);
    $('<div id="service_accordion_container">').appendTo(divacc);
    // Display service conditions :
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_conditions_' + elem_id;
    create_grid( {
        caption: 'Conditions',
        url: '/api/serviceprovider/' + elem_id + '/aggregate_conditions',
        content_container_id: 'service_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            $.ajax({
                url     : '/api/aggregatecombination/' + rowdata.aggregate_combination_id,
                success : function(data) {
                    $(grid).setCell(rowid, 'aggregate_combination_id', data.aggregate_combination_label);
                }
            });
        },
        colNames: ['id','name', 'enabled', 'combination', 'comparator', 'threshold'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_condition_label',index:'aggregate_condition_label', width:120,},
             {name:'state',index:'state', width:60,},
             {name:'aggregate_combination_id',index:'aggregate_combination_id', width:60,},
             {name:'comparator',index:'comparator', width:160,},
             {name:'threshold',index:'threshold', width:60,},
           ],
        details: { onSelectRow : function(eid) { serviceconditionmodal(elem_id, eid); } }
    } );
    createServiceCondition('service_accordion_container', elem_id);
    // Display services rules :
    $("<p>").appendTo('#service_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_rules_' + elem_id;
    create_grid( {
        caption: 'Rules',
        url: '/api/serviceprovider/' + elem_id + '/aggregate_rules',
        grid_class: 'service_ressources_aggregate_rules',
        content_container_id: 'service_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        colNames: ['id','name', 'enabled', 'last eval', 'formula', 'description'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_rule_label',index:'aggregate_rule_label', width:90,},
             {name:'aggregate_rule_state',index:'aggregate_rule_state', width:90,},
             {name:'aggregate_rule_last_eval',index:'aggregate_rule_last_eval', width:90, formatter : lastevalStateFormatter},
             {name:'aggregate_rule_formula',index:'aggregate_rule_formula', width:90,},
             {name:'aggregate_rule_description',index:'aggregate_rule_description', width:200,},
           ],
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/aggregaterule/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'aggregate_rule_formula');
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
                                            }
                                        });
                                    }
                        }
                    });
                    require('KIO/workflows.js');
                    createWorkflowRuleAssociationButton(cid, eid, 2, elem_id);
               }},
            ],
            title   : { from_column : 'aggregate_rule_label' }
        },
        action_delete: {
            url : '/api/aggregaterule',
        },
    } );
    createServiceRule('service_accordion_container', elem_id);

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
        url: '/api/externalnode?outside_id=' + service_provider_id,
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
