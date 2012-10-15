require('widgets/widget_common.js');

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
    if (obj.widget.element.find('.nodesStateGrid').length == 0) {return;}

     var sp_id = obj.widget.metadata.service_id;

     displayWarningNodesGrid( obj.widget, sp_id );
});

function displayWarningNodesGrid(widget, sp_id) {
    var cont = widget.element.find('.nodesStateGrid');
    cont.attr('id', 'nodestate_grid_' + widget.element.attr('id'));
    var warn_noderules = {};
    cont.jqGrid({
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

    // Populate grid with nodes having at least one verified rule
    $.get(
            'api/externalnode?service_provider_id=' + sp_id,
            function(nodes) {
                var checked_nodes = 0;
                var warn_nodes = 0;
                $.each(nodes, function(idx,node) {
                    $.get(
                            'api/externalnode/' + node.pk + '/verified_noderules',
                            function(verified_rules) {
                                var warn_rules = [];
                                $.each(verified_rules, function(i,e) {
                                    if (e.verified_noderule_state === 'verified') {warn_rules.push(e)}
                                });
                                var nb_warn_rules = warn_rules.length;
                                if (nb_warn_rules > 0) {
                                    cont.jqGrid('addRowData',
                                                node.pk,
                                                {name : node.externalnode_hostname, warn_count : nb_warn_rules});
                                    warn_noderules[node.pk] = warn_rules;
                                    // reload grid to apply sorting options at each addRow (progressive sorting)
                                    //cont.trigger('reloadGrid');
                                    warn_nodes++;
                                    //cont.jqGrid('setColProp', 'name', {label : 'Nodes ' + warn_nodes}); 
                                }
                                checked_nodes++;
                            }
                    );
                })
                // Reload grid at the end (one time sorting, more optimized)
                function sortGrid() {
                    (nodes.length === checked_nodes) ? cont.trigger('reloadGrid') : setTimeout(sortGrid, 10);
                }
                sortGrid();
            }
    );


}
