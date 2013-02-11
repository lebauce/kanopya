require('widgets/widget_common.js');

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
    if (obj.widget.element.find('.nodesStateGrid').length == 0) {return;}

     var sp_id = obj.widget.metadata.service_id;

     displayWarningNodesGrid( obj.widget, sp_id );
});

function displayWarningNodesGrid(widget, sp_id) {

    // GAUGE
    var warn_node_gauge = widget.element.find('.warnNodesGauge');
    warn_node_gauge.progressbar();

    // Styling : orange bar and centered caption over bar
    warn_node_gauge.find('.ui-progressbar-value').css('background', 'orange');
    warn_node_gauge.css('position', 'relative');
    warn_node_gauge.find('.caption').attr('style', 'position: absolute; width: 100%; text-align: center; line-height: 1.9em; color: #666');

    // GRID
    var nodes_grid = widget.element.find('.nodesStateGrid');
    nodes_grid.attr('id', 'nodestate_grid_' + widget.element.attr('id'));
    var warn_noderules = {};
    nodes_grid.jqGrid({
        datatype : 'local',
        colNames : ['Node name', 'Warnings'],
        colModel : [
                    {name:'name', index:'name', width:'80'},
                    {name:'warn_count', index:'warn_count', width:'20' }
        ],
        sortname        : 'warn_count',
        sortorder       : 'desc',
        autowidth       : true,
        shrinkToFit     : true,
        rowNum          : 1000,
        subGrid         : true,
        subGridOptions: {
            "plusicon"  : "ui-icon-triangle-1-e",
            "minusicon" :"ui-icon-triangle-1-s",
            "openicon"  : "ui-icon-arrowreturn-1-e",
            "reloadOnExpand" : false,
            "selectOnExpand" : true
        },
        subGridRowExpanded : function(subgridDivId, rowId) {
            var subgridTableId = subgridDivId + "_t";
            $("#" + subgridDivId).html("<table id='" + subgridTableId + "'></table>");
            var rules_grid_cont = $("#" + subgridTableId);
            rules_grid_cont.jqGrid({
                datatype    : 'local',
                colNames    : ['Rule'],
                colModel    : [
                    { name: 'name' }
                ],
                height      : 'auto',
                autowidth   : true,
                shrinkToFit : true,
            });
            // Hide subgrid header
            $('#'+subgridDivId).find('.ui-jqgrid-hdiv th').hide();

            // Populate subgrid with verified rules for this node
            $.each(warn_noderules[rowId], function(idx,warnrule) {
                $.get(
                        'api/nodemetricrule/' + warnrule.verified_noderule_nodemetric_rule_id,
                        function(rule) {
                            rules_grid_cont.jqGrid('addRowData', rule.pk, {name : rule.nodemetric_rule_label});
                        }
                );
            });
        }
    });

    widget.element.find('.ui-jqgrid').hide();
    widget_loading_start( widget.element );

    // Populate grid with nodes having at least one verified rule
    $.get(
            'api/serviceprovider/' + sp_id + '/nodes?monitoring_state=<>,disabled',
            function(nodes) {
                var total_nodes = nodes.length;
                var checked_nodes = 0;
                var warn_nodes = 0;
                $.each(nodes, function(idx,node) {
                    $.get(
                            'api/node/' + node.pk + '/verified_noderules',
                            function(verified_rules) {
                                var warn_rules = [];
                                $.each(verified_rules, function(i,e) {
                                    if (e.verified_noderule_state === 'verified') {warn_rules.push(e)}
                                });
                                var nb_warn_rules = warn_rules.length;
                                if (nb_warn_rules > 0) {
                                    nodes_grid.jqGrid('addRowData',
                                                node.pk,
                                                {name : node.node_hostname, warn_count : nb_warn_rules});
                                    warn_noderules[node.pk] = warn_rules;
                                    // reload grid to apply sorting options at each addRow (progressive sorting)
                                    //nodes_grid.trigger('reloadGrid');
                                    warn_nodes++;
                                    warn_node_gauge.progressbar('value',warn_nodes*100/total_nodes);
                                    warn_node_gauge.find('.caption').html(warn_nodes + '/' + total_nodes + ' nodes');
                                }
                                checked_nodes++;
                            }
                    );
                })
                // Wait end of all requests to apply specific management
                function manageEndCheck() {
                    if (total_nodes === checked_nodes) {
                        if (warn_nodes === 0) {
                            // No warnings, pretty display
                            widget.element.find('.ui-jqgrid').hide();
                            warn_node_gauge.css('background', 'lightGreen');
                            warn_node_gauge.find('.caption').html('no warnings');
                        } else {
                            // Reload grid at the end (one time sorting, more optimized)
                            nodes_grid.trigger('reloadGrid');
                            widget.element.find('.ui-jqgrid').show();
                        }
                        widget_loading_stop( widget.element );
                    } else {
                        setTimeout(manageEndCheck, 10);
                    }
                }
                manageEndCheck();
            }
    );


}
