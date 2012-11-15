require('widgets/widget_common.js');
require('common/service_monitoring.js'); // for getIndicators()

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
    if (obj.widget.element.find('.nodeIndicatorView').length == 0) {return;}

     var sp_id = obj.widget.metadata.service_id;
     var node_id = obj.widget.metadata.node_id;

     initNodeIndicatorWidget(
             obj.widget.element,
             sp_id,
             node_id
     );
});

function initNodeIndicatorWidget (widget_elem, sp_id, node_id) {
    var indic_list = widget_elem.find('.indicator_list');

    indic_list.change(function () {
        showIndicatorGraph(
                this,
                this.options[this.selectedIndex].id,
                this.options[this.selectedIndex].value,
                $(this.options[this.selectedIndex]).attr('unit'),
                widget_elem.find('.graph_start_time').datetimepicker('getDate').getTime(),
                widget_elem.find('.graph_end_time').datetimepicker('getDate').getTime(),
                sp_id,
                node_id
        );
    });

    var indicators = getIndicators(sp_id);
    $.each(indicators, function (name, row) {
        indic_list.append($('<option>', {value : name, html : name, id : row.indicator_id, unit : row.indicator_unit}));
    });

    setIndicDatePicker(widget_elem);

    setIndicRefreshButton(widget_elem, sp_id, node_id);

//    // Load widget content if configured
//    if (widget.metadata.aggregate_combination_id) {
//        indic_list.find('option#' + widget.metadata.aggregate_combination_id).attr('selected', 'selected');
//        indic_list.change();
//    }
}

function setIndicDatePicker(widget_div) {
    var now = new Date();
    var start = new Date();
    start.setDate(now.getDate() - 1);

    widget_div.find('.graph_start_time').datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', start);
    widget_div.find('.graph_end_time').datetimepicker({
        dateFormat: 'mm-dd-yy'
    }).datetimepicker('setDate', now);
}

function setIndicRefreshButton(widget_div, sp_id, node_id) {
    widget_div.find('.refresh_button').click(function () {
        indic_list = widget_div.find('.indicator_list');
        showIndicatorGraph(
                widget_div,
                $(indic_list).find(':selected').attr('id'),
                $(indic_list).find(':selected').attr('value'),
                $(indic_list).find(':selected').attr('unit'),
                widget_div.find('.graph_start_time').datetimepicker('getDate').getTime(),
                widget_div.find('.graph_end_time').datetimepicker('getDate').getTime(),
                sp_id,
                node_id
        );
    }).button({ icons : { primary : 'ui-icon-refresh' } }).show();
}

function setItemList(widget_div, labels) {
    var item_list = widget_div.find('.table_elem_list');
    curr_opt_id = item_list.find(':selected').attr('id')
    item_list.empty().show();
    item_list.append($('<option>', {html : 'Select item', value : 'Select item', checked : 'checked', id : 'default'}));
    $(labels).each(function (item_idx) {
        label = labels[item_idx];
        item_list.append($('<option>', {value : label, html : label, id : label}));
    });
    item_list.find('option#'+curr_opt_id).attr('selected', 'selected').change();
}

//function triggered on node indicator selection
function showIndicatorGraph(curobj,indic_id,indic_name,indic_unit,start,stop, sp_id, node_id) {
    if (indic_id == 'default'){return}
    var widget = $(curobj).closest('.widget');
    widget_loading_start( widget );

    var widget_id = $(curobj).closest('.widget').attr("id");
    var graph_container = widget.find('.nodeIndicatorView');
    graph_container.children().remove();

    $.ajax({
        type : 'POST',
        url : '/api/serviceprovider/' + sp_id + '/getNodeMonitoringData',
        contentType : 'application/json',
        data : JSON.stringify( {
            node_id : node_id,
            indicator_ids : [indic_id],
            historical : 1,
            start   : parseInt(start / 1000),
            end     : parseInt(stop / 1000)
        }),
        success : function (data) {
            var div_id = 'node_indicator_graph_' + widget_id;
            var div = '<div id=\"'+div_id+'\"></div>';
            graph_container.css('display', 'block');
            graph_container.append(div);
            // Build input as expected by jqplot and transform unix timestamp into js timestamp
            // Also manage indicator table
            var graph_data = [];
            var table_data = {};
            var graph_labels = [];
            var min = start;
            var max = stop;
            var mode_table = null;
            $.each(data, function(indic_oid, values) {
                var line_data = [];
                // Manage table data or not
                // if it's a table then key is the index and data the map {time => value}
                // else key is time and data the value
                $.each(values, function(key, data) {
                    if (mode_table === null) {
                        mode_table = (data !== null && typeof data == 'object') ? 1 : 0;
                    }
                    if (mode_table) {
                        graph_labels.push(key);
                        var item_line_data = [];
                        $.each(data, function(time, value) {
                            item_line_data.push([time*1000, value]);
                        });
                        table_data[key] = item_line_data;
                    } else {
                        line_data.push([key*1000, data]);
                    }
                });
                if (!mode_table) {
                    graph_data.push(line_data);
                }
            });

            widget.find('.table_elem_list').unbind('change');
            if (mode_table) {
                // Manage table row select dropdown
                widget.find('.table_elem_list').change( function() {
                    var item_label = $(this).find(':selected').attr('id');
                    if (item_label != 'default') {
                        graph_container.children().remove();
                        graph_container.append(div);
                        nodeTimedGraph([table_data[item_label]], [item_label], min, max, '', indic_unit, div_id);
                    }
                });
                setItemList(widget, graph_labels);
            } else {
                if (graph_data.length != 0) {
                    widget.find('.table_elem_list').hide();
                    nodeTimedGraph(graph_data, graph_labels, min, max, '', indic_unit, div_id);
                } else {
                    $(graph_container).append('<span>No data for this indicator in the selected period</span>');
                }
            }
            widget_loading_stop( widget );
        },
        error : function (jqXHR, textStatus, errorThrown) {
            widget_loading_stop( widget );
            graph_container.append($('<div>', {'class' : 'ui-state-highlight ui-corner-all', html: textStatus}));
        }
    })

}

function nodeTimedGraph(graph_lines, graph_labels, min, max, label, ylabel, div_id) {
    $.jqplot.config.enablePlugins = true;

    var cluster_timed_graph = $.jqplot(div_id, graph_lines, {
        title:label,
        seriesDefaults: {
            breakOnNull:true,
            showMarker: false,
            trendline: {
                color : '#555555',
                show  : $('#trendlineinput').attr('checked') ? true : false,
            },
            pointLabels: { show: false },
        },
        legend: {
            labels  : graph_labels,
            show    : false,
        },
        axes:{
            xaxis:{
                renderer:$.jqplot.DateAxisRenderer,
                rendererOptions: {
                    tickInset: 0
                },
                tickRenderer: $.jqplot.CanvasAxisTickRenderer,
                tickOptions: {
                    mark: 'inside',
                    markSize: 10,
                    showGridline: false,
                    angle: -60,
                    formatString: '%m-%d-%y %H:%M'
                },
                min:min,
                max:max,
            },
            yaxis:{
                label: ylabel,
                labelRenderer: $.jqplot.CanvasAxisLabelRenderer,
                tickOptions: {
                    showMark: false,
                },
            },
        },
        grid:{
            background: '#eeeeee',
        },
        highlighter: {
            show: true,
            // formatString: '<p class="cluster_combination_tooltip">Date: %s<br /> value: %f</p>',
        }

    });

    // Attach resize event handlers
    setGraphResizeHandlers(div_id, cluster_timed_graph);
}
