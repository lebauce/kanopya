
// Dashboard widget loading
// TODO: use dashboard conf (loadingHtml, widgetContentClass), maybe use events
function widget_loading_start( widget ) {
    var loadingHtml = '<div class="loading"><img alt="Loading, please wait" src="/css/theme/loading.gif" /><p>Loading...</p></div>';
    $(loadingHtml).appendTo(widget.find('.widgetcontent'));
}

function widget_loading_stop( widget ) {
    widget.find('.loading').remove();
}

// Set resizing handlers for jqplot graph
function setGraphResizeHandlers (graph_div_id, graph) {
    $('#'+graph_div_id).on('resizeGraph', function() {
        graph.replot();
    });
    
    $('#'+graph_div_id).closest('.widget').on('widgetOpenFullScreen', function(e, obj) {
        //widget_loading_start( obj.widget.element );
        //$('#'+graph_div_id).hide();
        // We need to wait a bit for widget resizing
        setTimeout(function() { graph.replot(); }, 10);
        //widget_loading_stop( obj.widget.element )
        //$('#'+graph_div_id).show();
    });
    
    $('#'+graph_div_id).closest('.widget').on('widgetCloseFullScreen', function(e, obj) {
        // We need to wait a bit for widget resizing
        setTimeout(function() { graph.replot(); }, 10);
    });
}

function setGraphDatePicker(widget) {
    var now = new Date();
    var start = new Date();
    start.setDate(now.getDate() - 1);

    var container = widget.find('.graph_time_settings');

    var start_input = $('<input>', {type:'text', 'class':'graph_start_time'}).datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', start);
    container.append ($('<span>', {css:'white-space:nowrap', html:'Start: '}).append(start_input) );

    var end_input = $('<input>', {type:'text', 'class':'graph_end_time'}).datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', now);
    container.append ($('<span>', {css:'white-space:nowrap', html:'End: '}).append(end_input) );

}

function getPickedDate(widget) {
    return {
        start : widget.find('.graph_start_time').val(),
        end   : widget.find('.graph_end_time').val(),
    };
}
