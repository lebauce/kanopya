require('common/formatters.js');

// Callback for services grid
// Add extra info to each row for specific columns
// Extra columns are 'node_number' and 'rulesstate'
function addServiceExtraData(grid, rowid, rowdata, rowelem) {
    // Set a generix service template name if not defined
    if (rowelem.hasOwnProperty('service_template') && rowdata['service_template.service_name'] == undefined) {
        $(grid).setCell(rowid, 'service_template.service_name', 'Internal');
    }

    // Set the node number
    $(grid).setCell(rowid, 'node_number', rowelem.nodes.length);

    // Rules State
    var verified = 0;
    var undef    = 0;
    var ok       = 0;

    // Get the rules of each row as extra data, because expanding rules and nodes
    // when getting service providers list raise a combinatorial explosion (thanks to underling generic sql joins).
    $.ajax({
        url     : '/api/aggregaterule?service_provider_id=' + rowelem.pk,
        type    : 'GET',
        async   : true,
        success : function(aggregaterules) {
            for (var index in aggregaterules) {
                var rule = aggregaterules[index];

                // Filter on rules concrete type in js (bad), because the api do not support it for instance.
                if (! rule.hasOwnProperty('aggregate_rule_last_eval'))
                    continue;

                var lasteval = rule.aggregate_rule_last_eval;
                if (lasteval === '1') {
                    ++verified;
                } else if (lasteval === null) {
                    ++undef;
                } else if (lasteval === '0') {
                    ++ok;
                }
                var cellContent = $('<div>');
                if (ok > 0) {
                    $(cellContent).append($('<img>', { src : '/images/icons/up.png' })).append(ok + "&nbsp;");
                }
                if (verified > 0) {
                    $(cellContent).append($('<img>', { src : '/images/icons/broken.png' })).append(verified + "&nbsp;");
                }
                if (undef > 0) {
                    $(cellContent).append($('<img>', { src : '/images/icons/down.png' })).append(undef);
                }
                $(grid).setGridParam({ autoencode : false });
                $(grid).setCell(rowid, 'rulesstate', cellContent.html());
                $(grid).setGridParam({ autoencode : true });
            }
        }
    });
}

//Callback for service resources grid
//Add extra info to each row for specific columns
//Extra column is 'rulesstate'
function addResourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, sp_id, ext) {
    // Do not display lights if monitoring is disabled for this node
    if (rowelem.monitoring_state && rowelem.monitoring_state == 'disabled') {
        $(grid).setCell(rowid, 'rulesstate', 'Not evaluated');
        return;
    }
    var     verifiednoderules = {};
    var     ok          = $('<span>', { text : 0, rel : 'ok', css : {'padding-right' : '10px'} });
    var     notok       = $('<span>', { text : 0, rel : 'notok', css : {'padding-right' : '10px'} });
    var     undef       = $('<span>', { text : 0, rel : 'undef', css : {'padding-right' : '10px'} });
    var     cellContent = $('<div>');
    $(cellContent).append($('<img>', { rel : 'ok', src : '/images/icons/up.png' })).append(ok);
    $(cellContent).append($('<img>', { rel : 'notok', src : '/images/icons/broken.png' })).append(notok);
    $(cellContent).append($('<img>', { rel : 'undef', src : '/images/icons/down.png' })).append(undef);
    for (var i in rowelem.verified_noderules) if (rowelem.verified_noderules.hasOwnProperty(i)) {
        verifiednoderules[rowelem.verified_noderules[i].verified_noderule_nodemetric_rule_id] =
            rowelem.verified_noderules[i].verified_noderule_state;
    }
    for (var i in nodemetricrules) if (nodemetricrules.hasOwnProperty(i)) {
        var verified_node_rule = verifiednoderules[nodemetricrules[i].nodemetric_rule_id];
        if (verified_node_rule === undefined) {
            // Do not show green light for lisibility
            $(ok).text(parseInt($(ok).text()) + 1);
        } else if (verified_node_rule === 'verified') {
            $(notok).text(parseInt($(notok).text()) + 1);
        } else if (verified_node_rule === 'undef') {
            $(undef).text(parseInt($(undef).text()) + 1);
        }
        if (parseInt($(ok).text()) <= 0) { $(cellContent).find('*[rel="ok"]').css('display', 'none'); } else { $(cellContent).find('*[rel="ok"]').css('display', 'inline'); }
        if (parseInt($(notok).text()) <= 0) { $(cellContent).find('*[rel="notok"]').css('display', 'none'); } else { $(cellContent).find('*[rel="notok"]').css('display', 'inline'); }
        if (parseInt($(undef).text()) <= 0) { $(cellContent).find('*[rel="undef"]').css('display', 'none'); } else { $(cellContent).find('*[rel="undef"]').css('display', 'inline'); }
        $(grid).setGridParam({ autoencode : false });
        $(grid).setCell(rowid, 'rulesstate', $(cellContent).html());
        $(grid).setGridParam({ autoencode : true });
    }
}

// Allow to use dashboard widget outside of the dashboard
function integrateWidget(cid, widget_type, callback) {
    var cont = $('#' + cid);
    var widget_div = $('<div>', { 'class' : 'widgetcontent' });
    cont.addClass('widget').append(widget_div);
    widget_div.load('/widgets/'+ widget_type +'.html', function() {callback(widget_div)});
}

//This function load grid with list of rules for verified state corelation with the the selected node :
function node_rules_tab(cid, eid, service_provider_id) {

    function verifiedNodeRuleStateFormatter(cell, options, row) {

        var VerifiedRuleFormat;
        // Where rowid = rule_id
        $.ajax({
             url: '/api/node/' + eid + '/verified_noderules?verified_noderule_nodemetric_rule_id=' + row.pk,
             async: false,
             success: function(answer) {
                if (answer.length == 0) {
                    VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                } else if (answer[0].verified_noderule_state == 'verified') {
                    VerifiedRuleFormat = "<img src='/images/icons/broken.png' title='broken' />"
                } else if (answer[0].verified_noderule_state == 'undef') {
                    VerifiedRuleFormat = "<img src='/images/icons/down.png' title='down' />";
                }
              }
        });
        return VerifiedRuleFormat;
    }

    var loadNodeRulesTabGridId = 'node_rules_tabs';
    create_grid( {
        url: '/api/nodemetricrule?service_provider_id=' + service_provider_id,
        content_container_id: cid,
        grid_id: loadNodeRulesTabGridId,
        grid_class: 'node_rules_tab',
        colNames: [ 'id', 'rule', 'state' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'label', index: 'label', width: 90,},
            { name: 'state', index: 'state', width: 200, formatter: verifiedNodeRuleStateFormatter },
        ],
        action_delete : 'no',
    } );
}

function node_monitoring_tab(cid, node_id, service_provider_id) {
    integrateWidget(cid, 'widget_historical_view', function(widget_div) {
        customInitHistoricalWidget(
                widget_div,
                service_provider_id,
                {
                    clustermetric_combinations : 'from_ajax',
                    nodemetric_combinations    : 'from_ajax',
                    nodes                      : [{id:node_id}],
                },
                {open_config_part : true}
        );
    });
}

// Make the field autocomplete and replace autocompleted name with corresponding id
function makeAutocompleteAndTranslate(field, availableTags) {
    // don't navigate away from the field on tab when selecting an item
    field.bind( "keydown", function( event ) {
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
                availableTags, request.term.split( / \s*/ ).pop() ) );
        },
        focus: function() {
            // prevent value inserted on focus
            return false;
        },
        select: function( event, ui ) {
            var terms = this.value.split(/ \s*/);
            // remove the current input
            terms.pop();
            // add the selected item
            terms.push( "id" + ui.item.value );

            $(this).val(terms.join(" "))

            // trick to avoid bad form validator behaviour
            $(this).blur().focus();
            return false;
        }
    });
}


function getServiceProviders(category) {
    if (category['category'] !== undefined) {
        category = category['category'];
    }

    var providers = [];
    var expand = 'components.component_type.component_type_categories.component_category';
    var filter = 'components.component_type.component_type_categories.component_category.category_name=' + category;
    $.ajax({
        url         : '/api/serviceprovider?' + filter + '&expand=' + expand + '&deep=1',
        type        : 'GET',
        async       : false,
        success     : function(data) {
            providers = data;
        }
    });
    return providers;
}

function findManager(category, service_provider_id, exclude) {
    if (category['category'] !== undefined) {
        service_provider_id = category['service_provider_id'];
        category = category['category'];
    }

    var expand = 'component_type.component_type_categories.component_category';
    var filter = 'component_type.component_type_categories.component_category.category_name=' + category;
    var managers = [];

    var url = '/api/component?expand=' + expand + '&' + filter;
    if (service_provider_id) {
        url += '&service_provider_id=' + (exclude ? '<>,' : '') + service_provider_id;
    }

    $.ajax({
        url     : url,
        type    : 'GET',
        async   : false,
        success : function(data) {
            managers = data;
        }
    });
    return managers;
}

function set_steps (service_attrdef, force_editable) {
    var step;
    for (var index in service_attrdef.displayed) {
        attrname = service_attrdef.displayed[index];

        if (! $.isPlainObject(attrname) && attrname.match(/_policy_id$/) != undefined) {
            step = attrname.replace('_policy_id','');
            step = step.substr(0,1).toUpperCase() + step.substr(1);
        }
        if (step) {
            var attrnames = [attrname];
            if ($.isPlainObject(attrname)) {
                attrnames = Object.keys(attrname);
            }
            for (index in attrnames){
                service_attrdef.attributes[attrnames[index]].step = step;
            }
        }
        if (force_editable !== undefined) {
            service_attrdef.attributes[attrnames[index]].is_editable = force_editable;
        }
    }
}
