
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

function setGraphDatePicker(widget_elem, widget) {
    var now = new Date();
    var start = new Date();
    start.setDate(now.getDate() - 1);

    var default_mode = 'mode1';

    var container = widget_elem.find('.graph_time_settings');

    if (default_mode == 'mode1') {container.addClass(default_mode);}
    var time_mode_button = $('<button>').button({ icons : { primary : 'ui-icon-clock' }, text : false }).click(function() {
        container.find('.timeset_mode2').toggle();
        container.find('.timeset_mode1').toggle();
        container.toggleClass('mode1');
    }).removeClass('ui-button-icon-only'); // removing this class is an ugly fix to have a correct button size
    container.append(time_mode_button);

    // Time setting mode 1 (start/end)
    var start_input = $('<input>', {type:'text', 'class':'graph_start_time'}).datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', start);
    container.append($('<span>', {css:'white-space:nowrap', 'class' : 'timeset_mode1 hidden', html:' Start: '}).append(start_input) );

    var end_input = $('<input>', {type:'text', 'class':'graph_end_time'}).datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', now);
    container.append($('<span>', {css:'white-space:nowrap', 'class' : 'timeset_mode1 hidden', html:' End: '}).append(end_input) );

    // Time setting mode 2 (last xxx)
    var select_amount       = $('<select>', {'class' : 'timeset_amount'});
    for (var i=1; i<10; i++) {
        select_amount.append($('<option>', { value: i, html: i}))
    }

    var select_timescale    = $('<select>', {'class' : 'timeset_timescale'});
    var timescale_options = {'hour(s)' : 3600, 'day(s)' : 3600*24, 'week(s)' : 3600*24*7};
    $.each(timescale_options, function(label, seconds) { select_timescale.append($('<option>', { value: seconds, html: label}))});

    container.append($('<span>', {css:'white-space:nowrap', 'class':'timeset_mode2 hidden' , html:' Last '}).append(select_amount).append(select_timescale) );

    container.find('.timeset_' + default_mode).show();

    // Manage widget metadata (save and load)
    if (widget !== undefined) {
        // Save
        select_amount.change( function() {
           widget.addMetadataValue('timeset_amount', $(this).find(':selected').val());
        });
        select_timescale.change( function() {
            widget.addMetadataValue('timeset_timescale', $(this).find(':selected').val());
        });

        // Load
        var amount      = widget.metadata.timeset_amount;
        var timescale   = widget.metadata.timeset_timescale;
        if (amount !== undefined || timescale !== undefined) {
            time_mode_button.click(); // change mode to mode2
            select_amount.find('[value="' + amount + '"]').attr('selected', 'selected');
            select_timescale.find('[value="' + timescale + '"]').attr('selected', 'selected');
        }
    }
}

function getPickedDate(widget) {
    if ( ! widget.find('.graph_time_settings').hasClass('mode1')) {
        // Mode 2 -> set datepicker values according to relative time settings
        var amount      = widget.find('.timeset_amount :selected').val();
        var timescale   = widget.find('.timeset_timescale :selected').val();

        var now   = new Date();
        var start = new Date( now.getTime() - (amount*timescale*1000) );

        widget.find('.graph_end_time').datetimepicker('setDate', now);
        widget.find('.graph_start_time').datetimepicker('setDate', start);
    }

    return {
        start : widget.find('.graph_start_time').val(),
        end   : widget.find('.graph_end_time').val(),
    };
}
