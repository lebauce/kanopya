require('common/formatters.js');

// Callback for services grid
// Add extra info to each row for specific columns
// Extra columns are 'node_number' and 'rulesstate'
function addServiceExtraData(grid, rowid, rowdata, rowelem, ext) {
    // Set a generix service template name if not defined
    if (rowdata['service_template.service_name'] == undefined) {
        $(grid).setCell(rowid, 'service_template.service_name', 'Internal');
    }

    var id  = $(grid).getCell(rowid, 'pk');
    $.ajax({
        url     : '/api/node?service_provider_id=' + id,
        type    : 'GET',
        success : function(data) {
            var i   = 0;
            $(data).each(function() {
                ++i;
            });
            $(grid).setCell(rowid, 'node_number', i);
        }
    });
    // Rules State
    $.ajax({
        url     : '/api/aggregaterule?service_provider_id=' + rowelem.pk,
        type    : 'GET',
        success : function(aggregaterules) {
            var verified    = 0;
            var undef       = 0;
            var ok          = 0;
            for (var i in aggregaterules) if (aggregaterules.hasOwnProperty(i)) {
                var lasteval    = aggregaterules[i].aggregate_rule_last_eval;
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

function set_steps (service_attrdef) {
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
    }
}
