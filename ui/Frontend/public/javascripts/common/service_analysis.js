

function loadServiceAnalysis(container_id, sp_id) {

    var container   = $("#" + container_id);

    var metric_x_select  = $('<select>', {id : 'metric_x_select'}).appendTo(container.append($('<span>', {text:'x: '})));
    container.append('<br>');
    var metric_y_select  = $('<select>', {id : 'metric_y_select'}).appendTo(container.append($('<span>', {text:' y: '})));
    container.append('<br>');
    var correlate_button = $('<button>', {id : 'correlate_button', text : 'correlate'});

    $.get('/api/aggregatecombination?service_provider_id=' + sp_id, function (data) {
        $(data).each( function () {
            var option = $('<option>', {id : this.aggregate_combination_id, value : this.aggregate_combination_label, text : this.aggregate_combination_label})
            metric_x_select.append(option);
            metric_y_select.append(option.clone());
        });
        correlate_button.appendTo(container);
    });

    correlate_button.click(function() {
        var selected_metric_x = metric_x_select.find('option:selected');
        var selected_metric_y = metric_y_select.find('option:selected');

        $('#scatter_graph').remove();
        var graph_container = $('<div>', {id : 'scatter_graph', style:'margin:auto'});
        container.append(graph_container);

        $.get('/monitoring/serviceprovider/'+sp_id+'/clustersview?id='+selected_metric_x.attr('id'), function(xdata) {
            var data_x = xdata.first_histovalues;
            $.get('/monitoring/serviceprovider/'+sp_id+'/clustersview?id='+selected_metric_y.attr('id'), function(ydata) {
                var data_y = ydata.first_histovalues;
                var serie = [];

                // Build serie with values of both metrics corresponding to the same time
                $.each(data_x, function(i, elem) {
                    serie.push([elem[1], data_y[i][1], elem[0]]);
                });

                graphScatterPlots(serie, {xlabel:selected_metric_x.val(), ylabel:selected_metric_y.val()});
            });
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
