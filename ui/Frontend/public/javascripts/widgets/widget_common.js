
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