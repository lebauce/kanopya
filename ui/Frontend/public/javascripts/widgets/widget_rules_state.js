require('widgets/widget_common.js');
require('jquery/jqplot/jqplot.donutRenderer.min.js');

$('.widget').live('widgetLoadContent',function(e, obj){
    // Check if loaded widget is for us
     if (obj.widget.element.find('.rules_state_overview').length == 0) {return;}

     var sp_id = obj.widget.metadata.service_id;
     displayRulesGraph(
             obj.widget,
             sp_id
     );

});

function displayRulesGraph(widget, sp_id) {
    var widget_id   = widget.element.attr("id");
    var master_cont = widget.element.find('.rules_state_overview');

    // We hide only titles here because we need graph div visible to plot the graph
    master_cont.find('span').hide();
    widget_loading_start( widget.element );

    // Service rules
    var serv_graph_cont  = widget.element.find('.service_rules_state_overview');
    var srules_graph_div_id = 'srules_state_graph_' + widget_id;
    serv_graph_cont.append($('<div>', {id : srules_graph_div_id}));
    $.get(
            '/api/serviceprovider/' + sp_id + '/aggregate_rules',
            function (rules) {
                if (rules.length == 0) {
                    serv_graph_cont.find('.title').html('No service rules');
                } else {
                    var service_rules = { '0' : [], '1' : [], 'undef' : [] };
                    for (var i=0;i<rules.length;i++) {
                        var rule_state = rules[i].aggregate_rule_last_eval;
                        var type_idx = (rule_state === undefined || rule_state === null) ? 'undef' : rule_state;
                        service_rules[ type_idx ].push(rules[i]);
                    }
                    var service_rules_series = [
                                                ['ok',     service_rules['0'].length],
                                                ['warn',   service_rules['1'].length],
                                                ['undef',  service_rules['undef'].length]
                                                ];
                    rulesStateGraph(srules_graph_div_id, [service_rules_series]);
                }
            }
    );

    // Nodes rules
    var nrules_graph_div_id = 'nrules_state_graph_' + widget_id;
    var nodes_graph_cont  = widget.element.find('.node_rules_state_overview');
    nodes_graph_cont.append($('<div>', {id : nrules_graph_div_id}));
    $.get(
            'api/serviceprovider/' + sp_id + '/externalnodes?externalnode_state=<>,disabled',
            function(nodes) {
                var total_nodes = nodes.length;
                var checked_nodes = 0;
                var warn_rules  = 0;
                var undef_rules = 0;
                $.each(nodes, function(idx,node) {
                    $.get(
                            'api/externalnode/' + node.pk + '/verified_noderules',
                            function(verified_rules) {
                                $.each(verified_rules, function(i,e) {
                                    (e.verified_noderule_state === 'verified') ? warn_rules++ : undef_rules++;
                                });
                                checked_nodes++;
                            }
                    );
                })
                // Wait end of all requests to apply specific management
                function manageEndCounting() {
                    if (total_nodes === checked_nodes) {
                        $.get(
                                '/api/serviceprovider/' + sp_id + '/nodemetric_rules',
                                function(node_rules) {
                                    master_cont.hide();
                                    if (total_nodes == 0) {
                                        master_cont.empty();
                                        master_cont.html('No nodes');
                                        master_cont.show();
                                    } else if (node_rules.length == 0) {
                                        nodes_graph_cont.find('.title').html('No nodes rules');
                                        master_cont.find('span').show();
                                        master_cont.show();
                                    } else {
                                        var ok_rules = (node_rules.length * total_nodes) - warn_rules - undef_rules;
                                        var nodes_rules_series = [['ok', ok_rules], ['warn', warn_rules], ['undef', undef_rules]];
                                        master_cont.find('span').show();
                                        master_cont.show(); // must be done before graph plotting
                                        rulesStateGraph(nrules_graph_div_id, [nodes_rules_series]);
                                    }
                                    widget_loading_stop( widget.element );
                                }
                        );
                    } else {
                        setTimeout(manageEndCounting, 10);
                    }
                }
                manageEndCounting();
            }
    );
}

function rulesStateGraph(div_id, series) {
    var rules_graph = $.jqplot(div_id, series, {
        seriesDefaults: {
          renderer:$.jqplot.DonutRenderer,
          rendererOptions:{
            sliceMargin     : 3,
            startAngle      : -90,
            showDataLabels  : true,
            dataLabels      : 'value',
            highlightMouseOver: true,
          }
        },
        //legend: { show:false, location: 'e' },
        seriesColors: ["#90EE90", "orange", "#D3D3D3"], // lightgreen, orange, lightgrey
        highlighter: {
            show: false,
            formatString    :'%s',
            tooltipLocation :'n',
            useAxesFormatters:false
        },
      });
      setGraphResizeHandlers(div_id, rules_graph);
}
