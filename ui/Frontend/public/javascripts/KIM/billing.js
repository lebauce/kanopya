require('common/formatters.js');

var repeats = ['', 'Daily' ];

function billingRepeatFormatter(e) {
    return repeats[e];
}

function billinglist(cid, eid) {
    create_grid({
        content_container_id    : cid,
        grid_id                 : 'billing_list',
        url                     : '/api/billinglimit?service_provider_id=' + eid,
        colNames                : ['Id', 'Type', 'Value', 'Soft limit ?', 'Start Time', 'End Time', 'Repeat', 'Repeat Start Time', 'Repeat End Time'],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'type', index : 'type' },
            { name : 'value', index : 'value' },
            { name : 'soft', index : 'soft', formatter : booleantostateformatter, width : 40, align : 'center'},
            { name : 'start', index : 'start', formatter : datetimeformatter },
            { name : 'ending', index : 'ending', formatter : datetimeformatter },
            { name : 'repeats', index : 'repeats', formatter : billingRepeatFormatter },
            { name : 'repeat_start_time', index : 'repeat_start_time', formatter : timeformatter },
            { name : 'repeat_end_time', index : 'repeat_end_time', formatter : timeformatter }
        ]
    });
}
