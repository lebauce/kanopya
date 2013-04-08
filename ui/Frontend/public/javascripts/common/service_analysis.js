

function loadServiceAnalysis(container_id, sp_id) {

    var container   = $("#" + container_id);

    var metric_x_select  = $('<select>', {id : 'metric_x_select'}).appendTo(container.append($('<span>', {text:'x: '})));
    container.append('<br>');
    var metric_y_select  = $('<select>', {id : 'metric_y_select'}).appendTo(container.append($('<span>', {text:' y: '})));
    container.append('<br>');
    var correlate_button = $('<button>', {id : 'correlate_button', text : 'correlate'}).button();

    $.get('/api/aggregatecombination?service_provider_id=' + sp_id, function (data) {
        $(data).each( function () {
            var option = $('<option>', {id : this.aggregate_combination_id, value : this.aggregate_combination_label, text : this.aggregate_combination_label})
            metric_x_select.append(option);
            metric_y_select.append(option.clone());
        });
        correlate_button.appendTo(container);
        container.append('<br>')
    });

    correlate_button.click(function() {
        var selected_metric_x = metric_x_select.find('option:selected');
        var selected_metric_y = metric_y_select.find('option:selected');

        $('#scatter_graph').remove();
        $('#histo_graph').remove();
        var graph_container = $('<div>', {id : 'scatter_graph', style:'float:left;width:30%'});
        var histo_graph_container = $('<div>', {id : 'histo_graph', style:'float:left;width:60%;margin-left:5%'});
        container.append(graph_container).append(histo_graph_container).append($('<div>', {style:'clear:both'}));

        graph_container.append('<div class="loading"><img alt="Loading, please wait" src="/css/theme/loading.gif" /><p>Loading...</p></div>');

        // Request data and build serie for corellation
        var request_count = 2;
        var data_x, data_y;
        $.get('/monitoring/serviceprovider/'+sp_id+'/clustersview?id='+selected_metric_x.attr('id'), function(xdata) {
            data_x = xdata.first_histovalues;
            request_count --;
        });
        $.get('/monitoring/serviceprovider/'+sp_id+'/clustersview?id='+selected_metric_y.attr('id'), function(ydata) {
            data_y = ydata.first_histovalues;
            request_count --;
        });

        var data_loaded = setInterval(function() {
            if (request_count == 0) {
                clearInterval(data_loaded);

                if (data_x === undefined || data_y === undefined) {
                    graph_container.find('.loading').remove();
                    graph_container.append($('<span>', {html: 'Not enough data to correlate'}));
                } else {
                    // Build serie with values of both metrics corresponding to the same time
                    var serie = [];
                    $.each(data_x, function(i, elem) {
                        serie.push([elem[1], data_y[i][1], elem[0]]);
                    });
                    graph_container.find('.loading').remove();
                    graphScatterPlots(serie, {xlabel:selected_metric_x.val(), ylabel:selected_metric_y.val()});
                }
            }
        }, 10);

        // Add historical graph
        integrateWidget('histo_graph', 'widget_historical_view', function(widget_div) {
            customInitHistoricalWidget(
                widget_div,
                sp_id,
                {
                    clustermetric_combinations : [
                           {id:selected_metric_x.attr('id'), name:selected_metric_x.val(), unit:''},
                           {id:selected_metric_y.attr('id'), name:selected_metric_y.val(), unit:''}
                     ],
                    nodemetric_combinations    : null,
                    nodes                      : null
                },
                {hide_config_part : true}
            );
        });

    });
}

function graphScatterPlots(serie, info) {
    $.jqplot.config.enablePlugins = true;

    var label = '';
    var graph_labels = ['graph label'];

    var scatter_graph = $.jqplot('scatter_graph', [serie], {
        title : label,
        seriesDefaults: {
            breakOnNull:true,
            showMarker: true,
            showLine: false,
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
                label: info.xlabel,
                labelRenderer: $.jqplot.CanvasAxisLabelRenderer,
                tickOptions: {
                    showMark: false,
                },
            },
            yaxis:{
                label: info.ylabel,
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
            yvalues:2,
            formatString: 'x: %s,  y: %s, date: %s'
        },
        cursor : {
            show : false
        }
    });

    function _resizeGraph() {
        var parent_width = $('#'+'scatter_graph').parent().width();
        $('#'+'scatter_graph').height(parent_width/3);
        $('#'+'scatter_graph').width(parent_width/3);
        scatter_graph.replot();
    }

    _resizeGraph();
    $('#'+'scatter_graph').on('resizeGraph', _resizeGraph);
}
