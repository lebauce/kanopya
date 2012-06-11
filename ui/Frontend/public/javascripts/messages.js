$(document).ready(function () {

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

    create_grid( {
        grid_id: 'grid-message',
        url: '/api/message',
        colNames: [ 'Id', 'From', 'Level', 'Date', 'Time', 'Content' ],
        colModel: [
            { name: 'message_id', index: 'message_id', width: 60, key : true },
            { name: 'message_from', index: 'message_from', width: 90 },
            { name: 'message_level', index: 'message_level',width: 40, formatter: stateFormatter },
            { name: 'message_creationdate', index: 'message_creationdate', width: 100, formatter: dateFormatter },
            { name: 'message_creationtime', index: 'message_creationtime', width: 100 },
            { name: 'message_content', index: 'message_content', width: 130 }
        ],
        height: '200px',
        rowNum: 10,
        rowList: [5, 10, 20, 50, 100],
        pager: "#msgGridPager"
    } );

    $('#grid-message').jqGrid('setGridWidth', $('#view-container').parent().width() - 20);

    // Needed to fix bad panels resizing when opening Messages pane (south) for the first time
    // Layout will take in account the message grid size fill with data 
    $('body').layout().resizeAll();
});
