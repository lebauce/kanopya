require('widgets/widget_common.js');

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
     if (obj.widget.element.find('.nmBarGraph').length == 0) {return;}

     setNodesSelection(obj.widget.element, obj.widget);

     var sp_id = obj.widget.metadata.service_id;
     fillNodeMetricList(
             obj.widget,
             sp_id
     );

});

function fillNodeMetricList (widget, sp_id) {
    var indic_list = widget.element.find('.nmBargraph_list');
    
    indic_list.change(function () {
        showNodemetricCombinationBarGraph(
                this,
                this.options[this.selectedIndex].id,
                this.options[this.selectedIndex].value,
                sp_id);
        widget.addMetadataValue('nodemetric_id', this.options[this.selectedIndex].id);
        widgetUpdateTitle(widget, this.options[this.selectedIndex].value);
    });

    $.get('/api/nodemetriccombination?service_provider_id=' + sp_id, function (data) {
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
    var widget_elem = $(curobj).closest('.widget');
    var widget_id   = widget_elem.attr("id");

    var graph_container_div = widget_elem.find('.nodes_bargraph');
    var graph_div_id_prefix = 'nodes_bargraph' + widget_id;

    if (nodemetric_combination_id == 'default') { return }

    widget_loading_start( widget_elem );

    var nodes_selection_opt = getNodesSelection(widget_elem);

    var params = {id:nodemetric_combination_id};
    graph_container_div.children().remove();
    $.getJSON(nodes_view_bargraph, params, function(data) {
        if (data.error){
            graph_container_div.append($('<div>', {'class' : 'ui-state-highlight ui-corner-all', html: data.error}));
        } else {
            graph_container_div.css('display', 'block');
            var nodemetric_combination_unit = data.unit;
            var max = data.values[0];
            var min = data.values[(data.values.length-1)];
            var total = 0;
            $.each(data.values,function() {
                total += parseFloat(this);
            });
            var mean = total / data.values.length;
            if (max == mean) {
                mean = null;
            }

            // Apply nodes selection and sorting opt
            if (nodes_selection_opt.type == 'bottom' ) {
                data.nodelist.reverse();
                data.values.reverse();
            }
            if (nodes_selection_opt.count !== 'All' ) {
                data.nodelist   = data.nodelist.slice(0,nodes_selection_opt.count);
                data.values     = data.values.slice(0,nodes_selection_opt.count);
            }

            // build series
            var series = [];
            $.each(data.nodelist, function(idx,node) {
                series.unshift([parseFloat(data.values[idx]), node]);
            });

            //we generate the graph
            var div_id = graph_div_id_prefix;
            var master_div = $('<div>', {style:'height:300px;overflow-y:auto;overflow-x:hidden;display:block'});
            var div = $('<div>', {id: div_id});
            var graph_title;
            var title_align;
            if (!nodemetric_combination_label || nodemetric_combination_label == '') {
                // label not provided (i.e graph displayed in details dialog)
                graph_title = 'Unit: ' + nodemetric_combination_unit;
                title_align = 'right';
            } else {
                // widget on dashboard
                graph_title = nodemetric_combination_label + ' (' + nodemetric_combination_unit + ')';
                title_align = 'center';
            }
            graph_container_div
                .append($('<div>', {html: graph_title, style: 'text-align:' + title_align + ';color:#666'}))
                .append(master_div.append(div));
            nodemetricCombinationBarGraph(series, div_id, max, nodemetric_combination_label, nodemetric_combination_unit, mean);
        }
        widget_loading_stop( $(curobj).closest('.widget') );
    });
}

//Jqplot bar plots
function nodemetricCombinationBarGraph(series, div_id, max, title, unit, mean_value) {
    $.jqplot.config.enablePlugins = true;
    var barWidth = 12;
    var barSpace = 5;
    var nodes_bar_graph = $.jqplot(div_id,  [series], {
        //title: title + ' (' + unit + ')',
        height: Math.max(300, 100 + (barWidth + barSpace) * series.length) + 'px',//'600px',
        animate: !$.jqplot.use_excanvas,
        seriesDefaults:{
            renderer:$.jqplot.BarRenderer,
            shadowAngle: 135,
            rendererOptions:{
                varyBarColor : true,
                barWidth: barWidth,
                barDirection: 'horizontal'
            },
            pointLabels: { show: true, formatString: '%.1f', location: 'w' },
            trendline: {
                show: false, 
            },
        },
        axes: {
            yaxis: {
                renderer: $.jqplot.CategoryAxisRenderer,
                //tickRenderer: $.jqplot.CanvasAxisTickRenderer,
                tickOptions: {
                    showMark: false,
                    showGridline: false,
                    //angle: -40
                }
            },
            xaxis:{
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
            tooltipAxes: 'x',
            showMarker:false,
            formatString: '%s' + unit,
            tooltipLocation:'e'
        },
        canvasOverlay: {
            show: true,
            objects: [
              {dashedVerticalLine: {
                name: 'Average',
                x: mean_value,
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

function setNodesSelection(widget_elem, widget) {
    var type_select     = widget_elem.find('.order_type');
    var count_select    = widget_elem.find('.display_count');
    var count_options   = ['All',5,10,20,50];
    for (var i in count_options) {
        count_select.append($('<option>', { value: count_options[i], html: count_options[i]}));
    }

    // Manage save/load
    type_select.change( function() {
        var val = $(this).find(':selected').attr('id');
        if (widget !== undefined) widget.addMetadataValue('displayopt_type', val);
    });
    count_select.change( function() {
        if (widget !== undefined) widget.addMetadataValue('displayopt_count', $(this).find(':selected').val());
    })
    // Load
    var type_value  = 'top';
    var count_value = '10';
    if (widget !== undefined) {
        type_value  = widget.metadata.displayopt_type || type_value;
        count_value = widget.metadata.displayopt_count || count_value;
    }
    type_select.find('#' + type_value).attr('selected', 'selected');
    type_select.change();
    count_select.find('[value="' + count_value + '"]').attr('selected', 'selected');
}

function getNodesSelection(widget_elem) {
    var type_select     = widget_elem.find('.order_type');
    var count_select    = widget_elem.find('.display_count');

    return {
        type    : type_select.find(':selected').attr('id'),
        count   : count_select.find(':selected').val()
    }
}
