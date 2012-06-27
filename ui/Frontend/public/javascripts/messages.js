function initMessages() {

    create_grid( {
            grid_id: 'grid-message',
            url: '/api/message',
            colNames: [ 'Id', 'From', 'Level', 'Date', 'Time', 'Content' ],
            colModel: [
                { name: 'message_id', index: 'message_id', width: 60, sorttype:'int', hidden: true, key : true },
                { name: 'message_from', index: 'message_from', width: 90 },
                { name: 'message_level', index: 'message_level',width: 40, formatter: messageStateFormatter },
                { name: 'message_creationdate', index: 'message_creationdate', width: 100, formatter: messageDateFormatter },
                { name: 'message_creationtime', index: 'message_creationtime', width: 100 },
                { name: 'message_content', index: 'message_content', width: 130 }
            ],
            sortname: 'message_id',
            //sortorder: "desc",
            height: '200px',
            rowNum: 10,
            rowList: [5, 10, 20, 50, 100],
            pager: "#msgGridPager",
            action_delete : 'no',
    } );

    // Remove rollup icon
    //$("#grid-message.ui-jqgrid-titlebar-close").remove();
    
    // Set the correct state icon for each message
    function messageStateFormatter(cell, options, row) {
        if (cell == 'info') {
            return "<img src='/images/icons/up.png' title='info' />";
        } else {
            return "<img src='/images/icons/broken.png' title='warning' />";
        }
    }

    function messageDateFormatter(cell, options, row) {
        return (new Date(row.message_creationdate)).toDateString();
    }



    $('#grid-message').jqGrid('setGridWidth', $('#view-container').parent().width() - 20);
    $("#grid-message").setGridParam({sortname:'message_id', sortorder: 'desc'})
   .trigger('reloadGrid');

    // Needed to fix bad panels resizing when opening Messages pane (south) for the first time
    // Layout will take in account the message grid size fill with data 
    $('body').layout().resizeAll();
}