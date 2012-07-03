require('common/formatters.js');

// Callback for services grid
// Add extra info to each row for specific columns
// Extra columns are 'node_number' and 'rulesstate'
function addServiceExtraData(grid, rowid, rowdata, rowelem, ext) {
    var id  = $(grid).getCell(rowid, 'pk');
    $.ajax({
        url     : '/api/externalnode?service_provider_id=' + id,
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
        url     : '/api/aggregaterule?aggregate_rule_service_provider_id=' + rowelem.pk,
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

//Callback for service ressources grid
//Add extra info to each row for specific columns
//Extra column is 'rulesstate'
function addRessourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, sp_id, ext) {
    for (var i in nodemetricrules) if (nodemetricrules.hasOwnProperty(i)) {
        var     ok          = $('<span>', { text : 0, rel : 'ok', css : {'padding-right' : '10px'} });
        var     notok       = $('<span>', { text : 0, rel : 'notok', css : {'padding-right' : '10px'} });
        var     undef       = $('<span>', { text : 0, rel : 'undef', css : {'padding-right' : '10px'} });
        var     cellContent = $('<div>');
        $(cellContent).append($('<img>', { rel : 'ok', src : '/images/icons/up.png' })).append(ok);
        $(cellContent).append($('<img>', { rel : 'notok', src : '/images/icons/broken.png' })).append(notok);
        $(cellContent).append($('<img>', { rel : 'undef', src : '/images/icons/down.png' })).append(undef);
        var req_data = { 'externalnode_id' : rowdata.pk };
        req_data[ext + 'cluster_id'] = sp_id;
        $.ajax({
            url         : '/api/nodemetricrule/' + nodemetricrules[i].pk + '/isVerifiedForANode',
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify(req_data),
            success     : function(data) {
                if (parseInt(data) === 0) {
                    $(ok).text(parseInt($(ok).text()) + 1);
                } else if (parseInt(data) === 1) {
                    $(notok).text(parseInt($(notok).text()) + 1);
                } else if (data === null) {
                    $(undef).text(parseInt($(undef).text()) + 1);
                }
                if (parseInt($(ok).text()) <= 0) { $(cellContent).find('*[rel="ok"]').css('display', 'none'); } else { $(cellContent).find('*[rel="ok"]').css('display', 'inline'); }
                if (parseInt($(notok).text()) <= 0) { $(cellContent).find('*[rel="notok"]').css('display', 'none'); } else { $(cellContent).find('*[rel="notok"]').css('display', 'inline'); }
                if (parseInt($(undef).text()) <= 0) { $(cellContent).find('*[rel="undef"]').css('display', 'none'); } else { $(cellContent).find('*[rel="undef"]').css('display', 'inline'); }
                $(grid).setGridParam({ autoencode : false });
                $(grid).setCell(rowid, 'rulesstate', $(cellContent).html());
                $(grid).setGridParam({ autoencode : true });
            }
        });
    }
}

//This function load grid with list of rules for verified state corelation with the the selected node :
function node_rules_tab(cid, eid, service_provider_id) {

    function verifiedNodeRuleStateFormatter(cell, options, row) {

        var VerifiedRuleFormat;
        // Where rowid = rule_id
        $.ajax({
             url: '/api/externalnode/' + eid + '/verified_noderules?verified_noderule_nodemetric_rule_id=' + row.pk,
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
        url: '/api/nodemetricrule?nodemetric_rule_service_provider_id=' + service_provider_id,
        content_container_id: cid,
        grid_id: loadNodeRulesTabGridId,
        grid_class: 'node_rules_tab',
        colNames: [ 'id', 'rule', 'state' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_rule_label', index: 'nodemetric_rule_label', width: 90,},
            { name: 'nodemetric_rule_state', index: 'nodemetric_rule_state', width: 200, formatter: verifiedNodeRuleStateFormatter },
        ],
        action_delete : 'no',
    } );
}

function node_actions_tab(cid, eid, elem_id) {
    
}
