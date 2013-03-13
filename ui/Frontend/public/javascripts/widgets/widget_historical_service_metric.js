require('widgets/widget_common.js');

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
    if (obj.widget.element.find('.clusterCombinationView').length == 0) {return;}

    setGraphDatePicker(obj.widget.element, obj.widget);
    widgetCommonInit(obj.widget.element);

     var sp_id = obj.widget.metadata.service_id;
     fillServiceMetricCombinationList(
             obj.widget,
             sp_id
     );

});

function fillServiceMetricCombinationList (widget, sp_id) {
    var indic_list = widget.element.find('.combination_list');

    indic_list.change(function () {
        var time_settings   = getPickedDate(widget.element);
        var metric_id       = this.options[this.selectedIndex].id;
        var metric_name     = this.options[this.selectedIndex].value

        setRefreshButton(widget.element, metric_id, metric_name, sp_id);

        showCombinationGraph(
                this,
                metric_id,
                metric_name,
                time_settings.start,
                time_settings.end,
                sp_id
        );
        widget.addMetadataValue('aggregate_combination_id', this.options[this.selectedIndex].id);
        widgetUpdateTitle(widget, metric_name);
    });

    $.get('/api/aggregatecombination?service_provider_id=' + sp_id, function (data) {
        $(data).each( function () {
            indic_list.append('<option id ="' + this.aggregate_combination_id + '" value="' + this.aggregate_combination_label + '">' + this.aggregate_combination_label + '</option>');
        });

        // Load widget content if configured
        if (widget.metadata.aggregate_combination_id) {
            indic_list.find('option#' + widget.metadata.aggregate_combination_id).attr('selected', 'selected');
            indic_list.change();
        }
    });
}

function setRefreshButton(widget_div, combi_id, combi_name, sp_id) {
    widget_div.find('.refresh_button').unbind('click');
    widget_div.find('.refresh_button').click(function () {
        var time_settings = getPickedDate(widget_div);
        showCombinationGraph(
                widget_div,
                combi_id,
                combi_name,
                time_settings.start,
                time_settings.end,
                sp_id
        );
    }).button({ icons : { primary : 'ui-icon-refresh' } }).show();
}

//function triggered on cluster_combination selection
function showCombinationGraph(curobj,combi_id,label,start,stop, sp_id) {
    if (combi_id == 'default'){return}
    var widget = $(curobj).closest('.widget');
    widget_loading_start( widget );
    
    var clustersview_url = '/monitoring/serviceprovider/' + sp_id +'/clustersview';
    var widget_id = $(curobj).closest('.widget').attr("id");
    var graph_container = widget.find('.clusterCombinationView');
    var model_container = widget.find('.datamodel_fields');
    graph_container.children().remove();
    
    var params = {id:combi_id,start:start,stop:stop};
    $.getJSON(clustersview_url, params, function(data) {
        if (data.error) {
            graph_container.append('<br>').append($('<div>', {'class' : 'ui-state-highlight ui-corner-all', html: data.error}));
            deactivateWidgetPart(widget.find('.widget_part_forcasting'), 'You must have data on the graph to forecast');
        } else {
            var button = '<input type=\"button\" value=\"refresh\" id=\"cb_button\" onclick=\"c_replot()\"/>';
            var div_id = 'cluster_combination_graph_' + widget_id;
            var div = '<div id=\"'+div_id+'\"></div>';
            graph_container.css('display', 'block');
            graph_container.append(div);
            timedGraph([data.first_histovalues], data.min, data.max, label, data.unit, div_id);

            activateWidgetPart(widget.find('.widget_part_forcasting'));

            // Fill models list and bind change event
            var model_list = widget.find('.model_list');
            model_list.unbind('change').change({
                graph_container   : graph_container,
                model_container   : model_container,
                histovalues : data.first_histovalues,
                min         : data.min,
                max         : data.max,
                label       : label,
                unit        : data.unit,
                graph_div_id: div_id,
                combi_id    : combi_id,
                widget      : widget
            }, dataModelManagement);

            widget.find('.refresh_models_button').unbind().click(function() {
                model_list.empty();
                model_list.append($('<option>', {text : 'Select a model', id : 'model_default'}));
                $.get('/api/combination/'+combi_id+'/data_models', function (data) {
                    $(data).each( function () {
                        model_list.append($('<option>', {id : this.pk, value : this.start_time + ':' + this.end_time, text : this.label}));
                    });
                    model_list.append($('<option>', {text : 'New model...', id : 'new_model'}));
                    model_list.change();
                });
            }).click();
        }
        widget_loading_stop( widget );
    });

}

/*
 * Allow user to click on the graph to select start and end date
 * Selected range will be highlighted on the graph (using overlays, keeping existing one)
 * Callback will be called with start and stop params
 */
function pickTimeRange(params, overlays, callback) {
    var selected_start_time;
    var selected_end_time;
    $('#'+params.graph_div_id).bind("jqplotClick", function(ev, gridpos, datapos, neighbor) {
      if (selected_start_time === undefined || selected_end_time !== undefined) {
          selected_start_time = datapos.xaxis;
          selected_end_time = undefined;
      } else {
          selected_end_time = datapos.xaxis;
          var current_selected_start_time = parseInt(selected_start_time / 1000);
          var current_selected_end_time = parseInt(selected_end_time / 1000);
          var ext_overlays = new Array(overlays);
          ext_overlays.push( {line: {
              name      : 'pebbles',
              start     : [selected_start_time,0],
              stop      : [selected_end_time,0],
              lineWidth : 1000,
              lineCap   : 'butt',
              color     : 'rgba(89, 198, 154, 0.45)',
              shadow    : false
          }});
          params.graph_container.children().remove();
          params.graph_container.append($('<div>', {id:params.graph_div_id}));
          timedGraph([params.histovalues], params.min, params.max, params.label, params.unit, params.graph_div_id, ext_overlays);
          callback(current_selected_start_time, current_selected_end_time);
          pickTimeRange(params, overlays, callback);
      }
  });
}

function elem_loading_start( elem ) {
    var loadingHtml = '<div class="loading"><img alt="Loading, please wait" src="/css/theme/loading.gif" /><p>Loading...</p></div>';
    $(loadingHtml).appendTo(elem);
    $('*').addClass('cursor-wait');
}

function elem_loading_stop( elem ) {
    elem.find('.loading').remove();
    $('*').removeClass('cursor-wait');
}

/*
 * Transform time series format from API : {timestamps: [t1, t2], values: [v1,v2]}
 * to jqplot expected format : [[t1*1000, v1], [t2*1000, v2]]
 */
function _formatTimeSerie(ts) {
    var formatted_ts = [];
    for (var i=0; i< ts.timestamps.length; i++) {
        // We multiply value by 1 to force number
        formatted_ts.push([ts.timestamps[i] * 1000, 1 * ts.values[i]]);
    }
    return formatted_ts;
}

/*
 * Allow user to click on graph to select start and end date for data learning
 * Then click on predict button to launch data model selector autoPredict
 * Display the prediction with an horizon corresponding to last date visible on the graph
 */
function setAutoPredictControl(params) {
    pickTimeRange(params, [], function(start, end) {
        var graph_container = params.graph_container;
        var graph_div = $('<div>', {id: params.graph_div_id});

        params.model_container.find('.instant_predict').prop('disabled', false).unbind().click(function() {
            graph_container.children().remove();
            graph_container.append(graph_div);
            elem_loading_start(graph_container);

            var time_settings = getPickedDate(graph_container.parent());
            $.ajax({
                url         : '/api/datamodelselector/autoPredict',
                type        : 'POST',
                contentType : 'application/json',
                data        : JSON.stringify(
                        {
                            //model_list      : ['LinearRegression'],
                            combination_id  : params.combi_id,
                            start_time      : start,
                            end_time        : end,
                            horizon         : parseInt(new Date(time_settings.end).getTime() / 1000),
                        }
                ),
                success     : function (prediction_data) {
                    elem_loading_stop(graph_container);
                    timedGraph(
                            [params.histovalues, _formatTimeSerie(prediction_data)],
                            params.min, params.max,
                            params.label, params.unit,
                            params.graph_div_id,
                            []
                    );
                },
                error       : function(error) {
                    graph_container.append('<br>').append($('<div>', {'class' : 'ui-state-highlight ui-corner-all', html: error.responseText}));
                }
            });
        });
    });
}

function dataModelManagement(e) {
    var graph_info      = e.data;
    var model_container = e.data.model_container;
    var graph_container = e.data.graph_container;
    var graph_div = $('<div>', {id: e.data.graph_div_id});

    selected_model_id = $(this).find('option:selected').attr('id');
    if (selected_model_id === 'model_default') {
        model_container.find('.forcast_config').hide();
        model_container.find('.new_model_config').hide();

        setAutoPredictControl(e.data);

        return;
    }

    graph_container.children().remove();
    graph_container.append(graph_div);
    if (selected_model_id === 'new_model') {
        timedGraph(
                [graph_info.histovalues],
                graph_info.min, graph_info.max,
                graph_info.label, graph_info.unit,
                graph_info.graph_div_id,
                []
        );
        model_container.find('.forcast_config').hide();
        model_container.find('.new_model_config').show();
        model_container.find('.learn_data').prop('disabled', true);
        pickTimeRange(e.data, [], function(start, end) {
            model_container.find('.learn_data').prop('disabled', false).unbind().click(function() {
                $.post('/api/combination/' + e.data.combi_id + '/computeDataModel', {start_time:start, end_time:end}, function() {
                    alert('Operation enqueued');
                });
            });
        });
    } else {
        model_container.find('.forcast_config').show();
        model_container.find('.new_model_config').hide();
        var selected_model_id = $(this).find('option:selected').attr('id');
        var model_time_range = $(this).find('option:selected').val().split(":");
        var overlays = [{line: {
            name      : 'pebbles',
            start     : [model_time_range[0] * 1000,0],
            stop      : [model_time_range[1] * 1000,0],
            lineWidth : 1000,
            lineCap   : 'butt',
            color     : 'rgba(89, 198, 154, 0.45)',
            shadow    : false
        }}];
        var time_settings = getPickedDate(graph_container.parent());
        var sampling_period = model_container.find('.model_sampling').val();

        // Utility function specific to used date format
        // Return Unix epoch time (sec) from date/time string formatted as 'mm-dd-yy HH:MM'
        function dateTimeToEpoch(dateTime) {
            return parseInt(Date.parse(dateTime.replace(/-/g, '/')) / 1000);
        }

        widget_loading_start( graph_info.widget );
        $.ajax({
            url         : '/api/datamodel/'+selected_model_id+'/predict',
            async       : false,
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify(
                  {
                      start_time      : dateTimeToEpoch(time_settings.start),
                      end_time        : dateTimeToEpoch(time_settings.end),
                      sampling_period : sampling_period * 60,
                      data_format     :'pair',
                      time_format     :'ms'
                  }
            ),
            success     : function (prediction_data) {
                timedGraph(
                      [graph_info.histovalues, prediction_data],
                      graph_info.min, graph_info.max,
                      graph_info.label, graph_info.unit,
                      graph_info.graph_div_id,
                      overlays
                );
            },
            complete    : function () {
                widget_loading_stop( graph_info.widget );
            }
        });
    }
}

function timedGraph(graph_lines, min, max, label, unit, div_id, overlays, opts) {
    $.jqplot.config.enablePlugins = true;
    // var first_graph_line=[['03-14-2012 16:23', 0], ['03-14-2012 16:17', 0], ['03-14-2012 16:12', 0],['03-14-2012 16:15',null], ['03-14-2012 16:19', 0], ['03-14-2012 16:26', null]];

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
        axes:{
            xaxis:{
                renderer:$.jqplot.DateAxisRenderer,
                rendererOptions: {
                    tickInset: 0
                },
                tickRenderer: $.jqplot.CanvasAxisTickRenderer,
                tickOptions: {
                    mark        : 'inside',
                    markSize    : 10,
                    showGridline: false,
                    angle       : -60,
                    formatString: '%m-%d-%y %H:%M'
                },
                min:min,
                max:max,
            },
            yaxis:{
                label           : unit,
                labelRenderer   : $.jqplot.CanvasAxisLabelRenderer,
                tickOptions     : {
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
        },
        seriesColors : ['#4bb2c5', 'rgba(200, 100, 100, 0.45)'],
        canvasOverlay: {
            show    : true,
            objects :  overlays
        },
        cursor: {
            show                : (opts && opts.show_cursor) || true,
            showVerticalLine    : true,
            clickReset          : true,
            showTooltip         : false,
        }
    });

    // Attach resize event handlers
    setGraphResizeHandlers(div_id, cluster_timed_graph);
}

function toggleTrendLine() {
    if (cluster_timed_graph) {
        cluster_timed_graph.series[0].trendline.show = ! cluster_timed_graph.series[0].trendline.show;
        cluster_timed_graph.replot();
    }
}
