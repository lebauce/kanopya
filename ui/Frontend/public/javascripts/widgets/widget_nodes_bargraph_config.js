var sp_id = 67;
var nodes_view_bargraph = '/monitoring/serviceprovider/' + sp_id +'/nodesview/bargraph';

$(document).ready(function() {

    //initNodesBargraph(widget_id);

    //fillNodeMetricList();

});


    
                        
$('.widget').live('widgetLoadContent',function(e, obj){
   // alert('AAAAAAAAAAAAAAAAAAAAAAA');
            //if ($('.new-widget')) {
            //     $('.new-widget').remove();
                 console.log('Load content ' + obj.widget.id);
                 //alert('LOad content ' + obj.widget.id);
                 fillNodeMetricList(obj.widget.id);
            //}
});
          
function initNodesBargraph (widget_id) {
    alert(widget_id);
}

function fillNodeMetricList (widget_id) {
    var indic_list = $('#nmBargraph_list' + widget_id);
    $.get('/api/serviceprovider/' + sp_id + '/nodemetric_combinations', function (data) {
        $(data).each( function () {
            indic_list.append('<option id ="' + this.nodemetric_combination_id + '" value="' + this.nodemetric_combination_label 
            + '">' + this.nodemetric_combination_label + '</option>');
        });
    });
}

//functions triggered on nodemetrics combination selection
function showNodemetricCombinationBarGraph(curobj,nodemetric_combination_id, nodemetric_combination_label) {
    
    var widget_id = $(curobj).closest('.widget').attr("id");
    
    //alert('######## ' + widget_id);
    
    var graph_div_id = 'nodes_bargraph' + widget_id;
    
    if (nodemetric_combination_id == 'default') { return }
    //loading_start();
    var params = {id:nodemetric_combination_id};
    document.getElementById(graph_div_id).innerHTML='';
    $.getJSON(nodes_view_bargraph, params, function(data) {
        if (data.error){ alert (data.error); }
        else {
            document.getElementById(graph_div_id).style.display='block';
            var min = data.values[0];
            var max = data.values[(data.values.length-1)];
            // alert('min: '+min+ ' max: '+max); 
            var max_nodes_per_graph = 50;
            var graph_number = Math.round((data.nodelist.length/max_nodes_per_graph)+0.5);
            var nodes_per_graph = data.nodelist.length/graph_number;
            for (var i = 0; i<graph_number; i++) {
                var div_id = graph_div_id + '_'+i;
                var div = '<div id=\"'+div_id+'\"></div>';
                //create the graph div container
                $("#" + graph_div_id).append(div);
                //slice the array
                var indexOffset = nodes_per_graph*i;
                var toElementNumber = nodes_per_graph*(i+1);
                var sliced_values = data.values.slice(indexOffset,toElementNumber);
                var sliced_nodelist = data.nodelist.slice(indexOffset,toElementNumber);
                //we generate the graph
                nodemetricCombinationBarGraph(sliced_values, sliced_nodelist, div_id, max, nodemetric_combination_label);
            }
            var button = '<input type=\"button\" value=\"refresh\" id=\"ncb_button\" onclick=\"nc_replot()\"/>';
            $("#"+graph_div_id).append(button);
        }
        //loading_stop();
    });
}

//Jqplot bar plots
function nodemetricCombinationBarGraph(values, nodelist, div_id, max, title) {
    $.jqplot.config.enablePlugins = true;
    nodes_bar_graph = $.jqplot(div_id, [values], {
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
            },
        },
        seriesColors: ["#D4D4D4" ,"#999999"],
        highlighter: { 
            show: true,
            showMarker:false,
        }
    });
}

//replot  nodemetric combination bar graph
function nc_replot() {
    var nmcombination_dropdown_list = document.getElementById('nmBargraph_list');
    showNodemetricCombinationBarGraph(this,nmcombination_dropdown_list.options[nmcombination_dropdown_list.selectedIndex].id,nmcombination_dropdown_list.options[nmcombination_dropdown_list.selectedIndex].value)  
}
