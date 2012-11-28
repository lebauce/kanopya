require('common/general.js');

function currentalertslist(cid, eid) {
    create_grid({
        url                  : '/api/alert?alert_active=1&entity_id='+eid,   
        caption                 : 'Current alerts',
        content_container_id    : cid,
        grid_id                 : 'currentalertsgrid',
        action_delete           : "no",
        colNames                : [ 'Id', 'Date', 'Time', 'Message' ],
        colModel                : [
            { name : 'pk', index : 'pk', sorttype : 'int', hidden : true, key : true },
            { name : 'alert_date', index : 'alert_date', width : 50, align : 'center' },
            { name : 'alert_time', index : 'alert_time', width : 50, align : 'center' },
            { name : 'alert_message', index : 'alert_time', width : 500 }
        ]
    });
    $('<br />').appendTo('#'+cid);
}

function historicalertslist(cid, eid) {
    create_grid({
        url                  : '/api/alert?alert_active=0&entity_id='+eid,   
        caption                 : 'History',
        content_container_id    : cid,
        grid_id                 : 'historyalertsgrid',
        action_delete           : "no",
        colNames                : [ 'Id', 'Date', 'Time', 'Message' ],
        colModel                : [
            { name : 'pk', index : 'pk', sorttype : 'int', hidden : true, key : true },
            { name : 'alert_date', index : 'alert_date', width : 50, align : 'center' },
            { name : 'alert_time', index : 'alert_time', width : 50, align : 'center' },
            { name : 'alert_message', index : 'alert_time', width : 500 }
        ]
    });
}


