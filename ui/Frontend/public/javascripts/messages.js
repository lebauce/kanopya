$(document).ready(function () {

    var SQLops = {
        'eq' : '=',        // equal
        'ne' : '<>',       // not equal
        'lt' : '<',        // less than
        'le' : '<=',       // less than or equal
        'gt' : '>',        // greater than
        'ge' : '>=',       // greater than or equal
        'bw' : 'LIKE',     // begins with
        'bn' : 'NOT LIKE', // doesn't begin with
        'in' : 'LIKE',     // is in
        'ni' : 'NOT LIKE', // is not in
        'ew' : 'LIKE',     // ends with
        'en' : 'NOT LIKE', // doesn't end with
        'cn' : 'LIKE',     // contains
        'nc' : 'NOT LIKE'  // doesn't contain
    };

    var searchoptions = { sopt : $.map(SQLops, function(n) { return n; } ) };

    $("#grid-message").jqGrid({
        url:'/api/message',
        jsonReader : {
              root:"rows",
              page: "page",
              total: "pages",
              records: "records",
              repeatitems: false,
           },
        // By comment loadonce the user will able to refresh the grid content
        loadonce: false,
        height: '200px',
        width: 'auto',
        colNames: [ 'Id', 'From', 'Level', 'Date', 'Time', 'Content' ],
        colModel: [
            { name: 'message_id', index: 'message_id', width: 60, key : true, searchoptions: searchoptions },
            { name: 'message_from', index: 'message_from', width: 90, searchoptions: searchoptions },
            { name: 'message_level', index: 'message_level',width: 40, formatter: stateFormatter, searchoptions: searchoptions },
            { name: 'message_creationdate', index: 'message_creationdate', width: 100, formatter: dateFormatter, searchoptions: searchoptions },
            { name: 'message_creationtime', index: 'message_creationtime', width: 100, searchoptions: searchoptions },
            { name: 'message_content', index: 'message_content', width: 130, searchoptions: searchoptions }
        ],
        // multiselect: true,
        rowNum: 10,
        rowList: [5, 10, 20, 50, 100],
        pager: '#msgGridPager',
        caption: "",
        altRows: false,
        onSelectRow: function (id) {
        },
        datatype: function (postdata) {
            var data = { dataType : 'jqGrid' };

            if (postdata.page) {
                data.page = postdata.page;
            }

            if (postdata.rows) {
                data.rows = postdata.rows;
            }

            if (postdata.sidx) {
                data.order_by = postdata.sidx;
                if (postdata.sord == "desc") {
                    data.order_by += " DESC";
                }
            }

            if (postdata._search) {
                var operator = SQLops[postdata.searchOper];
                var query = postdata.searchString;

                if (postdata.searchOper == 'bw' || postdata.searchOper == 'bn') query = query + '%';
                if (postdata.searchOper == 'ew' || postdata.searchOper == 'en' ) query = '%' + query;
                if (postdata.searchOper == 'cn' || postdata.searchOper == 'nc' ||
                    postdata.searchOper == 'in' || postdata.searchOper == 'ni') {
                    query = '%' + query + '%';
                }

                data[postdata.searchField] = (operator != "=" ? operator + "," : "") + query;
            }

            $.getJSON('/api/message', data, function (data) {
                var thegrid = jQuery("#grid-message")[0];
                thegrid.addJSONData(data);
            });
        },
    });

    // Remove rollup icon
    $("#grid-message.ui-jqgrid-titlebar-close").remove();
    
    // Set the correct state icon for each message
    function stateFormatter(cell, options, row) {
        if (cell == 'info') {
            return "<img src='/images/icons/up.png' title='info' />";
        } else {
            return "<img src='/images/icons/broken.png' title='warning' />";
        }
    }

    function dateFormatter(cell, options, row) {
        return (new Date(row.message_creationdate)).toDateString();
    }



    $('#grid-message').jqGrid('setGridWidth', $('#view-container').parent().width() - 20);

    // Needed to fix bad panels resizing when opening Messages pane (south) for the first time
    // Layout will take in account the message grid size fill with data 
    $('body').layout().resizeAll();
});