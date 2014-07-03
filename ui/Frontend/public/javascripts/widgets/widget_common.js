
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

// Update title, keeping first part (widget type) and adding conf part
function widgetUpdateTitle(widget, conf) {
    var sep = ' - ';
    var split_title = widget.title.split(sep);
    widget.setTitle(split_title[0] + sep + conf);
}

function setGraphDatePicker(widget_elem, widget, periodDate) {
    var start, end;
    periodDate = periodDate || {};

    if (periodDate.start) {
        start = periodDate.start;
        end = periodDate.end;
    } else {
        end = new Date();
        start = new Date();
        start.setDate(end.getDate() - 1);
    }

    var default_mode = 'mode1';

    var container = widget_elem.find('.graph_time_settings');

    if (default_mode == 'mode1') {container.addClass(default_mode);}
    var time_mode_button = $('<button>').button({ icons : { primary : 'ui-icon-clock' }, text : false }).click(function() {
        container.find('.timeset_mode2').toggleClass('selected-time-mode');
        container.find('.timeset_mode1').toggleClass('selected-time-mode');
        container.toggleClass('mode1');
    }).removeClass('ui-button-icon-only'); // removing this class is an ugly fix to have a correct button size
    container.append(time_mode_button);

    // Time setting mode 1 (start/end)
    var start_input = $('<input>', {type:'text', 'class':'graph_start_time'}).datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', start);
    container.append($('<span>', {css:'white-space:nowrap', 'class' : 'time_mode timeset_mode1', html:' Start: '}).append(start_input) );

    var end_input = $('<input>', {type:'text', 'class':'graph_end_time'}).datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', end);
    container.append($('<span>', {css:'white-space:nowrap', 'class' : 'time_mode timeset_mode1', html:' End: '}).append(end_input) );

    // Time setting mode 2 (last xxx)
    var select_amount       = $('<select>', {'class' : 'timeset_amount'});
    for (var i=1; i<10; i++) {
        select_amount.append($('<option>', { value: i, html: i}))
    }

    var select_timescale    = $('<select>', {'class' : 'timeset_timescale'});
    var timescale_options = {'hour(s)' : 3600, 'day(s)' : 3600*24, 'week(s)' : 3600*24*7};
    $.each(timescale_options, function(label, seconds) { select_timescale.append($('<option>', { value: seconds, html: label}))});

    container.append($('<span>', {css:'white-space:nowrap', 'class':'time_mode timeset_mode2' , html:' Last '}).append(select_amount).append(select_timescale) );

    container.find('.timeset_' + default_mode).addClass('selected-time-mode');

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

function activateWidgetPart(elems) {
    elems.not('.widget-part-enable').unbind().click( function() {
        $(this).find('span').toggleClass('ui-icon-triangle-1-e ui-icon-triangle-1-s');
        $(this).next().toggle('slide');
    })
    .css({'color': '#555'}).attr('title', '')
    .addClass('clickable widget-part-enable')
    .next().css({'border-style':'groove none'}).hide();
}

function deactivateWidgetPart(elems, title) {
    elems.unbind().css({'color': '#999'}).attr('title', title);
    elems.removeClass('widget-part-enable');
    elems.find('span').removeClass('ui-icon-triangle-1-s').addClass('ui-icon-triangle-1-e');
    elems.next().hide();
}

function widgetCommonInit(widget_elem) {
    // All .widget_part tags can be clicked to toggle the element directly under it
    widget_elem.find('.widget_part')
    .prepend($('<span>', {'class' : 'ui-icon ui-icon-triangle-1-e' }))
    .css({'font-size': '0.83em', 'font-weight': 'bold', 'display':'inline-block'});
    activateWidgetPart(widget_elem.find('.widget_part'));

    widget_elem.find('.icon-only-refresh-button').button({ icons : { primary : 'ui-icon-refresh' }, text : false })
    .css({'margin':'0px 0px 0px 10px'});
}
