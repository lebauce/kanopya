require('widgets/widget_common.js');

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
     if (obj.widget.element.find('.nmBarGraph').length == 0) {return;}

     console.log('Load content of widget bargraph ' + obj.widget.id);

     var sp_id = obj.widget.metadata.service_id;
     fillNodeMetricList(
             obj.widget,
             sp_id
     );
});

function initNodesBargraph (widget_id) {
    alert(widget_id);
}

function fillNodeMetricList (widget, sp_id) {
    var indic_list = widget.element.find('.nmBargraph_list');
    
    indic_list.change(function () {
        showNodemetricCombinationBarGraph(this, this.options[this.selectedIndex].id, this.options[this.selectedIndex].value, sp_id);
        widget.addMetadataValue('nodemetric_id', this.options[this.selectedIndex].id);
    });

    $.get('/api/serviceprovider/' + sp_id + '/nodemetric_combinations', function (data) {
        $(data).each( function () {
            indic_list.append('<option id ="' + this.nodemetric_combination_id + '" value="' + this.nodemetric_combination_label 
            + '">' + this.nodemetric_combination_label + '</option>');
        });

        // Load widget content if configured
        if (widget.metadata.nodemetric_id) {
            indic_list.find('option#' + widget.metadata.nodemetric_id).attr('selected', 'selected');
            indic_list.change();
        }
    });
}

//functions triggered on nodemetrics combination selection
function showNodemetricCombinationBarGraph(curobj,nodemetric_combination_id, nodemetric_combination_label, sp_id) {

    var nodes_view_bargraph = '/monitoring/serviceprovider/' + sp_id +'/nodesview/bargraph';

    var widget_id = $(curobj).closest('.widget').attr("id");

    var graph_container_div = $(curobj).closest('.widget').find('.nodes_bargraph');
    var graph_div_id_prefix = 'nodes_bargraph' + widget_id;
    
    if (nodemetric_combination_id == 'default') { return }

    widget_loading_start( $(curobj).closest('.widget') );

    var params = {id:nodemetric_combination_id};
    graph_container_div.children().remove();
    $.getJSON(nodes_view_bargraph, params, function(data) {
        if (data.error){ alert (data.error); }
        else {
            graph_container_div.css('display', 'block');
            var nodemetric_combination_unit = data.unit;
            var max = data.values[0];
            var min = data.values[(data.values.length-1)];
            var total = 0;
            $.each(data.values,function() {
                total += parseInt(this);
            });
            var mean = total / data.values.length;

            var max_nodes_per_graph = 50;
            var graph_number = Math.round((data.nodelist.length/max_nodes_per_graph)+0.5);
            var nodes_per_graph = data.nodelist.length/graph_number;
            for (var i = 0; i<graph_number; i++) {
                var div_id = graph_div_id_prefix + '_'+i;
                var div = '<div id=\"'+div_id+'\"></div>';
                //create the graph div container
                graph_container_div.append(div);
                //slice the array
                var indexOffset = nodes_per_graph*i;
                var toElementNumber = nodes_per_graph*(i+1);
                var sliced_values = data.values.slice(indexOffset,toElementNumber);
                var sliced_nodelist = data.nodelist.slice(indexOffset,toElementNumber);

                //we generate the graph
                nodemetricCombinationBarGraph(sliced_values, sliced_nodelist, div_id, max, nodemetric_combination_label, nodemetric_combination_unit, mean);
            }
            //var button = '<input type=\"button\" value=\"refresh\" id=\"ncb_button\" onclick=\"nc_replot()\"/>';
            //graph_container_div.append(button);
        }
        widget_loading_stop( $(curobj).closest('.widget') );
    });
}

//Jqplot bar plots
function nodemetricCombinationBarGraph(values, nodelist, div_id, max, title, unit, mean_value) {
    $.jqplot.config.enablePlugins = true;
    var nodes_bar_graph = $.jqplot(div_id, [values], {
    title: title,
        animate: !$.jqplot.use_excanvas,
        seriesDefaults:{
            renderer:$.jqplot.BarRenderer,
            rendererOptions:{ varyBarColor : true, barWidth: 30 - (nodelist.length * 0.5) },
            pointLabels: { show: true },
            trendline: {
                show: false, 
            },
        },
        axes: {
            xaxis: {
                renderer: $.jqplot.CategoryAxisRenderer,
                ticks: nodelist,
                tickRenderer: $.jqplot.CanvasAxisTickRenderer,
                tickOptions: {
                    showMark: false,
                    showGridline: false,
                    angle: -40,
                }
            },
            yaxis:{
                min:0,
                max:max,
                label: unit,
                labelRenderer: $.jqplot.CanvasAxisLabelRenderer,
            },
        },
        grid:{
            background: '#eeeeee',
        },
        //seriesColors: ["#D4D4D4" ,"#999999"],
        seriesColors: ["#4BB2C5" ,"#6DD4E7"],
        highlighter: { 
            show: true,
            //useAxesFormatters: true,
            tooltipAxes: 'y',
            showMarker:false,
        },
        canvasOverlay: {
            show: true,
            objects: [
              {dashedHorizontalLine: {
                name: 'Average',
                y: mean_value,
                lineWidth: 1,
                color: "#999999",
                //shadow: true,
                show: true,
                //dashPattern: [16, 12],
                xOffset: 0
              }}
            ]
          }
    });

    // Allow to customize tooltip with the name of th x label, but not working for y value... TODO workaround
//    $("#" + div_id).bind('jqplotMouseMove', function(ev, gridpos, datapos, neighbor, plot) {
//        if (neighbor) {;
//            $(".jqplot-highlighter-tooltip").html("" + plot.axes.xaxis.ticks[neighbor.pointIndex] + ", " + plot.axes.yaxis.ticks[neighbor.pointIndex]);
//        }
//    });

    // Attach resize event handlers
    setGraphResizeHandlers(div_id, nodes_bar_graph);
}
