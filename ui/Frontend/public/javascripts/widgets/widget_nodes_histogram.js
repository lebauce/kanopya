require('widgets/widget_common.js');

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
    if (obj.widget.element.find('.nmHistogram').length == 0) {return;}

    console.log('Load content of widget histo ' + obj.widget.id);

     var sp_id = obj.widget.metadata.service_id;
     fillNodeMetricList2(
             obj.widget,
             sp_id
     );
});

// Can be factorized with the equivalent for nmBarGraph but will be removed soon (with widget advanced config)
function fillNodeMetricList2 (widget, sp_id) {
    var indic_list = widget.element.find('.nmHistogram_list');
    var part_number = 10;
    
    indic_list.change(function () {
        showNodemetricCombinationHistogram(this, this.options[this.selectedIndex].id, this.options[this.selectedIndex].value, part_number, sp_id);
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

function showNodemetricCombinationHistogram(curobj,nodemetric_combination_id,nodemetric_combination_label,part_number, sp_id) {
    var nodes_view_histogram = '/monitoring/serviceprovider/' + sp_id +'/nodesview/histogram';

    var widget_id = $(curobj).closest('.widget').attr("id");

    var graph_container_div = $(curobj).closest('.widget').find('.nodes_histogram');
    var graph_div_id = 'nodes_histogram' + widget_id;
    var graph_div = $('<div>', { id : graph_div_id });
    
    graph_container_div.children().remove();
    graph_container_div.append(graph_div);
    
    if (nodemetric_combination_id == 'default') { return }
    if (!isInt(part_number)) {
        alert(part_number+' is not an integer');
        return
    } else if (!part_number) {
        part_number = 10;
    }
    widget_loading_start( $(curobj).closest('.widget') );
    var params = {id:nodemetric_combination_id,pn:part_number};
    //graph_div.html('');
    $.getJSON(nodes_view_histogram, params, function(data) {
        if (data.error){ alert (data.error); }
        else {
            graph_div.css('display', 'block');
            nodemetricCombinationHistogram(data.nbof_nodes_in_partition, data.partitions, graph_div_id, data.nodesquantity, nodemetric_combination_label);
        }
//        var button = '<input type=\"button\" value=\"refresh\" id=\"nch_button\" onclick=\"nch_replot()\"/>';
//        $("#"+div_id).append(button);
        widget_loading_stop( $(curobj).closest('.widget') );
    });
}

function nodemetricCombinationHistogram(nbof_nodes_in_partition, partitions, div_id, nodesquantity, title) {
    $.jqplot.config.enablePlugins = true;
    var nodes_bar_graph = $.jqplot(div_id, [nbof_nodes_in_partition], {
    title: title,
        animate: !$.jqplot.use_excanvas,
        seriesDefaults:{
            renderer:$.jqplot.BarRenderer,
            rendererOptions:{ varyBarColor : true, shadowOffset: 0, barWidth: 30 },
            pointLabels: { show: true },
            trendline: {
                show: false, 
            },
        },
        axes: {
            xaxis: {
                renderer: $.jqplot.CategoryAxisRenderer,
                ticks: partitions,
                tickRenderer: $.jqplot.CanvasAxisTickRenderer,
                tickOptions: {
                    showMark: false,
                    showGridline: false,
                    angle: -40,
                }
            },
            yaxis:{
                label:'# nodes',
                labelRenderer: $.jqplot.CanvasAxisLabelRenderer,
                min:0,
                max:nodesquantity,
            },
        },
        grid:{
            background: '#eeeeee',
        },
        seriesColors: ["#D4D4D4" ,"#999999"],
        highlighter: { 
            show: true,
            showMarker:false,
        }
    });

    // Attach resize event handlers
    setGraphResizeHandlers(div_id, nodes_bar_graph);

}

//simple function to check if a variable is an integer
function isInt(n) {
   return n % 1 == 0;
}
