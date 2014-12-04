// KIM services
require('common/service_common.js');
require('common/model.js');
require('common/general.js');
require('widgets/widget_common.js');
require('jquery/jqplot/jqplot.donutRenderer.min.js');
require('common/lib_list.js');

// Must progressively move functions in the Service class
var Service = (function(_super) {

    Service.prototype   = new _super();

    function Service(id) {
        _super.call(this, id, 'serviceprovider');
    }

    Service.prototype.getMonthlyConsommationCSV = function() {
        window.open('/consommation/cluster/' + this.id);
    };

    return Service;
})(Model);

function servicesList(container_id, elem_id) {

    var instanceCollection;
    var isRunning = false;

    clearHtml();
    loadInstanceCollection();

    function loadInstanceCollection() {

        var instanceObject;
        var filter;
        var index, value;

        instanceCollection = [];

        filter = '&cluster_id=<>,' + kanopya_cluster;
        // If the logged user is a customer, filter the list of service
        if (current_user.profiles.length == 1 && current_user.profiles[0].profile_name === "Customer") {
            filter += '&service_provider.owner_id=' + current_user.user_id;
        }
        if (elem_id) {
            filter += '&service_template.service_template_id=' + elem_id;
        }

        $.getJSON(
            '/api/cluster?expand=service_template,nodes' + filter, function(data) {
            $.each(data, function(i, obj) {
                instanceObject = createInstanceObject(obj);
                instanceCollection.push(instanceObject);
            });
            renderHtml();
        });
    }

    function createInstanceObject(obj) {

        var stateMap = {
            'up'       : {
                'label': 'Up',
                'icon' : 'fa-check',
                'canStart' : false,
                'canStop' : true
            },
            'in'       : {
                'label': 'Up',
                'icon' : 'fa-check',
                'canStart' : false,
                'canStop' : true
            },
            'down'     : {
                'label': 'Down',
                'icon' : 'fa-times',
                'canStart' : true,
                'canStop' : false
            },
            'broken'   : {
                'label': 'Broken',
                'icon' : 'fa-times',
                'canStart' : false,
                'canStop' : false
            },
            'off'      : {
                'label': 'Inactive',
                'icon' : 'fa-power-off',
                'canStart' : false,
                'canStop' : false
            }
        };

        var instanceObject = {
            'id'               : obj.pk,
            'serviceName'      : 'Internal',
            'instanceName'     : obj.cluster_name,
            'active'           : obj.active,
            'activeIcon'       : '',
            'state'            : obj.cluster_state,
            'stateCanStart'    : false,
            'stateCanStop'     : false,
            'ruleStateOk'      : 0,
            'ruleStateVerified': 0,
            'ruleStateUndef'   : 0,
            'nodeNumber'       : 0
        };

        if (obj.service_template) {
            instanceObject.serviceName = obj.service_template.service_name;
        }
        if (obj.nodes) {
            instanceObject.nodeNumber = obj.nodes.length;
        }
        index = instanceObject.state.indexOf(':');
        if (index > -1) {
            instanceObject.state = instanceObject.state.substring(0, index);
        }
        if (!instanceObject.state && instanceObject.active == '0') {
            instanceObject.state = 'off';
        }
        if (instanceObject.state in stateMap) {
            instanceObject.stateLabel = stateMap[instanceObject.state].label;
            instanceObject.stateIcon = stateMap[instanceObject.state].icon;
            instanceObject.stateCanStart = stateMap[instanceObject.state].canStart;
            instanceObject.stateCanStop = stateMap[instanceObject.state].canStop;
        }

        // Rule state
        $.ajax({
            url     : '/api/aggregaterule?service_provider_id=' + instanceObject.id,
            type    : 'GET',
            dataType: 'json',
            async   : false,
            success : function(data) {
                $.each(data, function(i, obj) {
                    if (obj.hasOwnProperty('aggregate_rule_last_eval')) {
                        value = obj.aggregate_rule_last_eval;
                        if (value === '1') {
                            ++instanceObject.ruleStateVerified;
                        } else if (value === null) {
                            ++instanceObject.ruleStateUndef;
                        } else if (value === '0') {
                            ++instanceObject.ruleStateOk;
                        }
                    }
                });
            }
        });

        return instanceObject;
    }

    function renderHtml() {

        // clearHtml();

        // Hardcoded stuff...
        // TODO: Get the permitted actions list from /api/attributes
        if (current_user_has_any_profiles([ "Administrator", "Sales" ])) {
            createAddServiceButton(container_id);
        }

        createServiceGraphs(container_id, elem_id);
        renderTemplate();
    }

    function clearHtml() {
        if($('#services_list') !=  undefined) {
            $('#services_list').jqGrid('GridDestroy');
        }
        $('#instance-home').remove();
    }

    function renderTemplate() {

        var i;
        var templateFile = '/templates/instance-home.tmpl.html';

        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('#' + container_id).append(template({
                'instanceCollection': instanceCollection
            }));
            activateEvents();
        });
    }

    function activateEvents() {

        activateExpander();

        // Detail
        $('.list-item-info .name span').click(function() {
            $(this)
                .parents('.list-item')
                .find('.button-detail')
                .trigger('click');
        });
        $('.button-detail').click(function() {
            var id = $(this).parent().data('id');
            displayDetail(id);
        });

        // Stop
        $('.button-stop').click(function() {
            stopInstance(this);
        });

        // Start
        $('.button-start').click(function() {
            startInstance(this);
        });

        // Scale out
        $('.button-scale-out').click(function() {
            executeAction('addNode', this);
        });
    }

    function getInstanceObjectById(id) {

        var instanceObject = {};

        for (var i = 0; i < instanceCollection.length; i++) {
            if (instanceCollection[i].id == id) {
                instanceObject = instanceCollection[i];
                break;
            }
        }

        return instanceObject;
    }

    function displayDetail(id) {

        var instanceObject = getInstanceObjectById(id);

        displayDetailLink(instanceObject);

        show_detail(
            'services_list',
            'services_list',
            id,
            {
                'cluster_name': instanceObject.instanceName
            },
            {
                'link_to_menu': 'yes',
                'label_key': 'cluster_name'
            }
        );
    }

    function displayDetailLink(instanceObject) {

        var detailLinkId = 'link_view_' + instanceObject.instanceName.replace(/ /g, '_') + '_' + instanceObject.id;
        var $detailLink = $('#' + detailLinkId);
        if ($detailLink.length) {
            $detailLink.parent('ul').css('display', 'block');
        }
    }

    function startInstance(element) {
        executeAction('start', element, 'This will start your instance.\nDo you want to continue?');
    }

    function stopInstance(element) {
        executeAction('stop', element, 'This will stop all your running instances.\nDo you want to continue?');
    }

    function executeAction(action, element, confirmationMessage) {

        if (isRunning === true) {
            return;
        }

       if (confirmationMessage) {
           if (confirm(confirmationMessage) === false) {
                return false;
            }
       }

        isRunning = true;

        var id = $(element).parent().data('id');
        startTextButtonAnimation(element);
        $.ajax({
            type: "POST",
            url: '/api/cluster/' + id + '/' + action,
            success: function() {
                refreshItem(id);
            },
            complete: function() {
                stopTextButtonAnimation(element);
                isRunning = false;
            }
        });
    }

    function refreshItem(id) {

        $.getJSON(
            '/api/cluster/' + id + '?expand=service_template,nodes',
            function(data) {
                var instanceObject = createInstanceObject(data);
                var $item = $('#list-item' + id);
                var $elt, $child;

                $item.children('.list-item-box').attr('class', 'list-item-box ' + instanceObject.state);

                $elt = $item.find('.state');
                $elt.children('.fa').attr('class', 'fa ' + instanceObject.stateIcon);
                $elt.children('.label').text(instanceObject.stateLabel);

                $item
                    .find('.node')
                    .children('.value')
                    .text(instanceObject.nodeNumber);

                $elt = $item.children('.panel');
                $elt.attr('class', 'panel ' + instanceObject.state);

                $elt = $elt.children('.button-group');
                $child = $elt.children('.button-start');
                if (instanceObject.stateCanStart) {
                    if ($child.length === 0) {
                        $elt.prepend('<button type="button" class="btn btn-action4 button-text button-start">Start</button>');

                            $elt.children('.button-start').click(function() {
                                startInstance(this);
                            });

                    }
                } else {
                    if ($child.length) {
                        $child.remove();
                    }
                }

                $child = $elt.children('.button-stop');
                if (instanceObject.stateCanStop) {
                    if ($child.length === 0) {
                        $elt.prepend('<button type="button" class="btn btn-action3 button-text button-stop">Stop</button>');

                            $elt.children('.button-stop').click(function() {
                                stopInstance(this);
                            });
                    }
                } else {
                    if ($child.length) {
                        $child.remove();
                    }
                }
            }
        );
    }

    function renderList() {

        var container = $('#' + container_id);

        $('a[href=#content_services_overview_static]').text('Service instances');

        var kanopya_filter = '&cluster_id=<>,' + kanopya_cluster;
        // If the logged user is a customer, filter the list of service
        var customer_filter = '';
        if (current_user.profiles.length == 1 && current_user.profiles[0].profile_name === "Customer") {
            customer_filter = '&service_provider.owner_id=' + current_user.user_id;
        }

        var grid = create_grid  ( {
            url: '/api/cluster?expand=service_template,nodes' + kanopya_filter + customer_filter,
            content_container_id: container_id,
            grid_id: 'services_list',
            afterInsertRow: function (grid, rowid, rowdata, rowelem) {
                addServiceExtraData(grid, rowid, rowdata, rowelem);
            },
            rowNum : 25,
            colNames: [ 'ID', 'Service', 'Instance Name', 'Active', 'State', 'Rules State', 'Node Number' ],
            colModel: [
                { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'service_template.service_name', index: 'service_template_name', width: 200 },
                { name: 'cluster_name', index: 'service_name', width: 200 },
                { name: 'active', index: 'active', width : 40, align : 'center', formatter : function(cell, formatopts, row) { return booleantostateformatter(cell, 'active', 'inactive') } },
                { name: 'cluster_state', index: 'service_state', width: 90, align : 'center', formatter:StateFormatter },
                { name: 'rulesstate', index : 'rulesstate' },
                { name: 'node_number', index: 'node_number', width: 150 }
            ],
            elem_name   : 'service',
            // details     : { link_to_menu : 'yes', label_key : 'cluster_name'},
            details     : {onSelectRow: regis},
            deactivate  : true
        });

    }

    function createAddServiceButton(cid) {

        if ($('#instantiate_service_button').length) {
            return;
        }

        var button = $("<button>", { id : 'instantiate_service_button', text : 'Instantiate a service'}).button({
            icons   : { primary : 'ui-icon-plusthick' }
        });

        button.bind('click', function() {
            // Use the kanopyaformwizard for policies
            (new KanopyaFormWizard({
                title        : 'Instantiate a service',
                type         : 'cluster',
                reloadable   : true,
                hideDisabled : true,
                stepsAsTags  : true,
                displayed    : [ 'cluster_name', 'cluster_desc', 'owner_id', 'service_template_id' ],
                rawattrdef   : {
                    cluster_name : {
                        label        : 'Instance name',
                        type         : 'string',
                        pattern      : '^[a-zA-Z_0-9]+$',
                        size         : 200,
                        is_mandatory : true,
                        is_editable  : true
                    },
                    cluster_desc : {
                        label        : 'Instance description',
                        type         : 'text',
                        pattern      : '^.*$',
                        is_mandatory : false,
                        is_editable  : true
                    },
                    owner_id : {
                        label        : 'Customer',
                        type         : 'relation',
                        relation     : 'single',
                        pattern      : "^[1-9][0-9]+$",
                        is_mandatory : true,
                        is_editable  : true
                    },
                    service_template_id : {
                        label        : 'Service type',
                        type         : 'relation',
                        relation     : 'single',
                        reload       : true,
                        pattern      : "^[1-9][0-9]+$",
                        welcome      : "Select a service type",
                        is_mandatory : true,
                        is_editable  : true
                    },
                    active : {
                        value : 1,
                        // Required to avoid the field disabled
                        is_editable : 1
                    }
                },
                attrsCallback : function (resource, data, trigger) {
                    var attributes;

                    // Define the cluster relation hard coded here, to avoid a call
                    // to the cluster attributes for the relations only
                    var cluster_relations = {
                        owner : {
                            resource : "user",
                            cond     : { "foreign.user_id" : "self.owner_id" },
                            attrs    : { accessor : "single" }
                        },
                        service_template : {
                            resource : "servicetemplate",
                            cond     : { "foreign.service_template_id" : "self.service_template_id" },
                            attrs    : { accessor : "single" }
                        }
                    };

                    // If the service template defined, fill the form with the service template definition
                    if (data.service_template_id) {
                        var args = { params : data, trigger : trigger };
                        attributes = ajax('POST', '/api/attributes/servicetemplate', args);

                        // Delete the service template fields other than policies ids
                        delete attributes.attributes['service_name'];
                        delete attributes.attributes['service_desc'];

                    } else {
                        attributes = { attributes : {}, relations : {} };
                    }
                    $.extend(true, attributes.relations, cluster_relations);

                    // Set steps
                    set_steps(attributes);

                    // Set the value if defined (at reload)
                    $.each([ 'cluster_name', 'cluster_desc', 'owner_id', 'service_template_id' ], function (index, attr) {
                        if (data[attr] !== undefined) {
                            if (attributes.attributes[attr] === undefined) {
                                attributes.attributes[attr] = {};
                            }
                            attributes.attributes[attr].value = data[attr];
                        }
                    });
                    return attributes;
                },
                optionsCallback : function (name, value, relations) {
                    if (name === 'owner_id') {
                        return ajax('GET', '/api/user?user_profiles.profile.profile_name=Customer');

                    } else {
                        return false;
                    }
                },
                callback : function (data) {
                    handleCreateOperation(data, $('#services_list'), null, function() {
                        // When the service is instantiated, we click on Services menu to reload menu and grid
                        // If a specific service type (in submenu) was selected by user, we click on it when it is loaded
                        var selected = $('.selected_viewlink');
                        reloadServices();
                        if (selected.attr('id') != getInstancesMenuId()) {
                            var waiter = setInterval(function(){
                                var link = $('#Services a:contains('+selected.text()+')');
                                if (link) {
                                    link.click();
                                    clearInterval(waiter);
                                }
                             },100);
                        }
                    });
                }
            })).start();
        });
        
        // $('#' + cid).append(button);
        var action_div = $('#' + cid).prevAll('.action_buttons');
        action_div.append(button);
    };
}

/*
 * For a specified service template, display core/ram usage by user and by service instance
 *
 * Add services graphs container
 * Retrieve, compute and display services usage info
 */
function createServiceGraphs(cid, service_template_id) {
    var graphs_visible = false;

    // Create graph container
    graph_cont_id = 'graphs_container';
    $('#'+graph_cont_id).remove();
    $('#'+cid)
    .prepend(
            $('<div>', {id : graph_cont_id})
            .append($('<span>', {text : 'Resources usage', class : 'clickable'}).prepend($('<span>', {class:'ui-icon ui-icon-triangle-1-e'}))
                    //.css({'font-size': '0.83em', 'font-weight': 'bold', 'display':'inline-block'})
                    // .css({'font-weight': 'normal', 'color' : '#555'})
                    .click(function() {
                        $(this).find('span').toggleClass('ui-icon-triangle-1-e ui-icon-triangle-1-s');
                        $(this).next().slideToggle();
                        if (!graphs_visible) {
                            buildGraphs();
                        }
                    })
             )
             .append(
                 $('<div>')
                .append('<div class="loading"><img alt="Loading, please wait" src="/css/theme/loading.gif" /><p>Loading...</p></div>')
                .append($('<div>', {id:'graph_users_core',    style:'width:20%;float:left'}))
                .append($('<div>', {id:'graph_users_ram',     style:'width:20%;float:left'}))
                .append($('<div>', {id:'graph_clusters_core', style:'width:20%;float:left'}))
                .append($('<div>', {id:'graph_clusters_ram',  style:'width:20%;float:left'}))
                .append($('<div>', {id:'graph_clusters_node', style:'width:20%;float:left'}))
                .append($('<div>', {style:'clear:both'}))
                .hide()
            )
    );

    // Inner function used to retrieve, compute and display services data
    function buildGraphs() {
        graphs_visible = true;
        var customer_filter = '';
        if (current_user.profiles.length == 1 && current_user.profiles[0].profile_name === "Customer") {
            customer_filter = '&service_provider.owner_id=' + current_user.user_id;
        }
        // Get infos
        var url = '/api/cluster?expand=nodes,nodes.host,owner&cluster_name=<>,Kanopya' + customer_filter;
        if (service_template_id) {
            url += '&service_template.service_template_id=' + service_template_id;
        }
        $.get(url, function(clusters) {
            var core_by_user  = {}, ram_by_user   = {},
                users_core    = [], users_ram     = [],
                clusters_core = [], clusters_ram  = [], clusters_nodes = [],
                total_core = 0, total_ram = 0, total_node = 0;
            // Retrieve and compute info for each cluster
            $(clusters).each(function(i,cluster) {
                var cluster_ram = 0, cluster_core = 0, cluster_nodes = 0;
                $(cluster.nodes).each(function(i,node){
                    cluster_core += parseFloat(node.host.host_core);
                    cluster_ram  += parseFloat(node.host.host_ram);
                    cluster_nodes++;
                });
                cluster_ram /= Math.pow(1024,2);
                total_core += cluster_core;
                total_ram  += cluster_ram;
                total_node += cluster_nodes;
                if (cluster_nodes !=0) {
                    clusters_core.push([cluster.cluster_name, cluster_core]);
                    clusters_ram.push([cluster.cluster_name, cluster_ram]);
                    clusters_nodes.push([cluster.cluster_name, cluster_nodes]);
                }
                // Add values to user data
                var user_name = cluster.owner.user_firstname + ' ' + cluster.owner.user_lastname;
                core_by_user[user_name] = core_by_user[user_name] ? core_by_user[user_name] + cluster_core : cluster_core;
                ram_by_user[user_name] = ram_by_user[user_name] ? ram_by_user[user_name] + cluster_ram : cluster_ram;
            });
            // Build users data as expected for plotting ({name:value} to [name,value])
            $.each(core_by_user,function(name,value) {
                if (value != 0) {
                    users_core.push([name, value]);
                }
            });
            $.each(ram_by_user,function(name,value) {
                if (value != 0) {
                    users_ram.push([name, value]);
                }
            });
            total_ram = Math.round(total_ram);

            // Draw graphs
            $('.loading').remove();
            if (users_core.length > 0) {
                serviceGraph('graph_users_core',    'Users core usage',        [users_core],    total_core);
                serviceGraph('graph_users_ram',     'Users RAM usage (MB)',    [users_ram],     total_ram);
                serviceGraph('graph_clusters_core', 'Services core usage',     [clusters_core], total_core);
                serviceGraph('graph_clusters_ram',  'Services RAM usage (MB)', [clusters_ram],  total_ram);
                serviceGraph('graph_clusters_node', 'Services nodes',          [clusters_nodes],total_node);
            } else {
                $('#'+graph_cont_id).find('span').next().append($('<span>', {text : 'No instance is running'}));
            }
        });
    }
}

// Create one donut graph with series data, using div_id as container
function serviceGraph(div_id, title, series, middle_text) {
    var g = $.jqplot(div_id, series, {
        seriesDefaults: {
          renderer:$.jqplot.DonutRenderer,
          rendererOptions:{
            sliceMargin     : 3,
            startAngle      : -90,
            showDataLabels  : true,
            dataLabels      : 'value',
            highlightMouseOver : true,
            fill : true,
          }
        },
        grid: {
            drawBorder: false,
            drawGridlines: false,
            background: 'rgba(1,1,1,0)',
            shadow:false
        },
        title : { text : title },
        legend: { show : false, location : 's', placement : 'outside' },
        highlighter: {
            show: true,
            formatString    :'%s : %s',
            tooltipLocation :'se',
            useAxesFormatters:false
        },
        cursor : {
            show : false
        }
    });
    setGraphResizeHandlers(div_id, g, addMiddleText);

    function addMiddleText() {
        $('#'+div_id).append($('<span>', {text:middle_text}).css({'position':'absolute', 'top':'50%', 'text-align':'center', 'width':'100%'}));
    };
    addMiddleText();
}

function loadServicesResources (container_id, elem_id) {
    var loadServicesResourcesGridId = 'service_resources_list_' + elem_id;
    var nodemetricrules;
    var container = $('#'+container_id);

    // Node indicator historical graph details handler
    function NodeIndicatorDetailsHistorical(cid, node_id) {
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_historical_node_indicator.html', function() {
          initNodeIndicatorWidget(cont, elem_id, node_id);
      });
    }

    $.ajax({
        url     : '/api/nodemetricrule?service_provider_id=' + elem_id,
        success : function(data) {
            nodemetricrules   = data;
        }
    });
    create_grid( {
        url: '/api/node?service_provider_id=' + elem_id,
        content_container_id: container_id,
        grid_id: loadServicesResourcesGridId,
        grid_class: 'service_resources_list',
        rowNum : 25,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            addResourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, elem_id, '');

            // Core and ram info
            var host_id  = $(grid).getCell(rowid, 'host_id');
            $.ajax({
                url     : '/api/host/' + host_id,
                type    : 'GET',
                success : function(data) {
                    $(grid).setCell(rowid, 'host_core', data.host_core);
                    $(grid).setCell(rowid, 'host_ram', (data.host_ram / (1024*1024)) + 'MB');
                }
            });
            // admin ip 
            $.ajax({
                url     : '/api/host/' + host_id,
                type    : 'GET',
                success : function(host) {
                    $(grid).setCell(rowid, 'admin_ip', host.admin_ip);
                }
            });
        
        },
        colNames: [ 'id', 'host id', 'State', 'Hostname', 'Core', 'Ram', 'IP Admin', 'Rules State' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'host_id', index: 'host_id', hidden: true},
            { name: 'node_state', index: 'node_state', width: 90, formatter: StateFormatter },
            { name: 'node_hostname', index: 'node_hostname', width: 200 },
            { name: 'host_core', index: 'host_core', width: 40 },
            { name: 'host_ram', index: 'host_ram' },
            { name: 'admin_ip', index: 'admin_ip' },
            { name: 'rulesstate', index: 'rulestate' }
        ],
        details : {
            tabs : [
                        { label : 'General', id : 'generalnodedetails', onLoad : nodedetailsaction },
                        { label : 'Network Interfaces', id : 'iface', onLoad : function(cid, eid) {node_ifaces_tab(cid, eid); } },
                        { label : 'Monitoring', id : 'resource_monitoring', onLoad : NodeIndicatorDetailsHistorical },
                        { label : 'Rules', id : 'rules', onLoad : function(cid, eid) { node_rules_tab(cid, eid, elem_id); } },
                        { label : 'Components', id : 'components', onLoad : function(cid, eid) { node_components_tab(cid, eid); } },
                    ],
            title : { from_column : 'node_hostname' }
        },
        action_delete:{
            callback : function (id) {
                if (confirm("This will stop the node, do you want to continue ?")) {
                    ajax('POST', '/api/cluster/' + elem_id + '/removeNode', { node_id : id });
                }
            }
        },
    } );
}

function runScaleWorkflow(type, eid, spid, successCallback) {

    var cont    = $('<div>');
    $('<label>', { text : type + ' amount : ', for : type }).appendTo(cont);
    var inp         = $('<input>', { id : type }).appendTo(cont);
    var unit_cont   = $('<span>').appendTo(cont);
    addFieldUnit({ unit : (type == 'Memory' ? 'byte' : 'core(s)') }, unit_cont, 'scale_amount_unit');

    $(cont).dialog({
        resizable       : false,
        modal           : true,
        close           : function() { $(this).remove(); },
        buttons         :[
            {id:'button-cancel',text:'Cancel',click: function() { $(this).dialog('close');}},
            {id:'button-ok',text:'Ok',click: function() {
                var amount  = $(inp).val();
                if (amount != null && amount !== "") {
                    amount = getRawValue(amount, 'scale_amount_unit');
                    $.ajax({
                        async       : false,
                        url         : '/api/serviceprovider/' + spid + '/service_provider_managers?' +
                                      'manager_category.parent.category_name=HostManager&expand=manager_category',
                        type        : 'GET',
                        success     : function(hmgr) {
                            $.ajax({
                                url         : '/api/entity/' + hmgr[0].manager_id + '/scaleHost',
                                type        : 'POST',
                                contentType : 'application/json', 
                                data        : JSON.stringify({  
                                    host_id         : eid,
                                    scalein_value   : amount,
                                    scalein_type    : type.toLowerCase()
                                }),
                                success     : function() {
                                    $(cont).dialog('close');
                                    if (successCallback && typeof successCallback == 'function') {
                                        successCallback(eid);
                                    }
                                }
                            });
                        }
                    });
                }
            }}
        ]
    });
}

function migrate(spid, eid) {
    var cont    = $('<div>');
    $('<label>', { text : 'Hypervisor : ', for : 'hypervisorselector' }).appendTo(cont);
    var sel     = $('<select>').appendTo(cont);
    $.ajax({
        async       : false,
        url         : '/api/host/' + eid + '/host_manager',
        type        : 'GET',
        success     : function(hmgr) {
            $.ajax({
                url     : '/api/virtualization/' + hmgr.entity_id + '/hypervisors?expand=node',
                type    : 'GET',
                success : function(data) {
                    for (var i in data) if (data.hasOwnProperty(i)) {
                        $(sel).append($('<option>', { text : data[i].node.node_hostname, value : data[i].pk }));
                    }
                    $(cont).dialog({
                        modal       : true,
                        resizable   : false,
                        dialogClass : "no-close",
                        buttons     : {
                            'Ok'        : function() {
                                var hyp = $(sel).val();
                                if (hyp != null && hyp != "") {
                                    $.ajax({
                                        url         : '/api/virtualization/' + hmgr.entity_id + '/migrate',
                                        type        : 'POST',
                                        contentType : 'application/json',
                                        data        : JSON.stringify({
                                            host_id         : eid,
                                            hypervisor_id   : hyp
                                        }),
                                        success     : function() {
                                            $(cont).dialog('close');
                                        }
                                    });
                                }
                            },
                            'Cancel'    : function() { $(this).dialog('close'); }
                        }
                    });
                }
            });
        }
    });
}

// Create available actions buttons for a node
// Alternatively, host id can be provided instead of node id
function nodedetailsaction(cid, eid, host_id) {
    var url;
    if (eid) { // If node id is provided
        if (eid.indexOf('_') !== -1) {
            eid = (eid.split('_'))[0];
        }
        url = '/api/node/' + eid;
    } else { // else host id is provided
        url = '/api/host/' + host_id + '/node';
    }
    url += '?expand=host';
    $.ajax({
        url     : url,
        success : function(data) {
            var remoteUrl   = data.host.remote_session_url;
            var isActive    = data.host.active;
            var isUp        = (/^up:/).test(data.host.host_state);
            var isVirtual   = false;
            $.ajax({
                url     : '/api/component/' + data.host.host_manager_id +
                          '?expand=component_type.component_type_categories.component_category',
                type    : 'GET',
                async   : false,
                success : function(manager) {
                    for (var index in manager.component_type.component_type_categories) {
                        var manager_category = manager.component_type.component_type_categories[index];
                        if (manager_category.component_category.category_name === 'VirtualMachineManager') {
                            isVirtual = true;
                        }
                    }
                }
            });
            var buttons   = [
                {
                    label   : 'Stop node',
                    sprite  : 'stop',
                    action  : '/api/serviceprovider/' + data.service_provider_id + '/removeNode',
                    data    : { node_id : data.pk },
                    confirm : 'The node will be halted'
                },
                {
                    label   : 'Resubmit node',
                    sprite  : 'refresh',
                    condition : isVirtual,
                    action  : '/api/host/' + data.host.pk + '/resubmit',
                    confirm : 'The node will be stopped and restarted'
                },
                {
                    label       : 'Scale Cpu',
                    sprite      : 'scale',
                    condition   : isVirtual,
                    action      : function() { runScaleWorkflow("CPU", data.host.pk, data.service_provider_id); }
                },
                {
                    label       : 'Scale Memory',
                    sprite      : 'scale',
                    condition   : isVirtual,
                    action      : function() { runScaleWorkflow("Memory", data.host.pk, data.service_provider_id); }
                },
                {
                    label       : 'Migrate',
                    sprite      : 'migrate',
                    condition   : isVirtual,
                    action      : function() { migrate(data.service_provider_id, data.host.pk); }
                },
                {
                    label       : 'Remote session',
                    sprite      : 'scale',
                    condition   : (remoteUrl !== null && remoteUrl !== ''),
                    action      : function() { window.open(remoteUrl); }
                },
                {
                    label       : 'Put node in maintenance',
                    icon        : 'wrench',
                    condition   : !isVirtual && isUp && isActive,
                    action      : '/api/host/' + data.host.pk + '/maintenance',
                    confirm     : 'All the virtual machines will be migrated and the hypervisor will be put in maintenance'
                },
                {
                    label       : 'Resubmit all vms',
                    icon        : 'wrench',
                    condition   : !isVirtual && isUp && isActive,
                    action      : '/api/host/' + data.host.pk + '/resubmitVms',
                    confirm     : 'All the virtual machines will be resubmited'
                },
                {
                    label       : 'Restore from maintenance',
                    icon        : 'gear',
                    condition   : !isVirtual && isUp && !isActive,
                    action      : '/api/host/' + data.host.pk + '/restore',
                    confirm     : 'hypervisor will be now used to host virtual machines'
                },
            ]
            require('KIM/services_details.js');
            var action_div=$('#' + cid);
            createallbuttons(buttons, action_div);
        }
    });
}

// load network interfaces details grid for a node
// Alternatively, host id can be provided instead of node id
function node_ifaces_tab(cid, eid, host_id) {
    if (eid) {
        var node;
        $.ajax({
            url     : '/api/node?node_id=' + eid,
            type    : 'GET',
            async   : false,
            success : function(data) {
                node = data[0];
            }
        });
        host_id = node.host_id;
    }
    create_grid( {
        url: '/api/iface?host_id=' + host_id,
        content_container_id: cid,
        grid_id: 'node_ifaces_tab',
        grid_class: 'node_ifaces_tab',
        action_delete: 'no',
        colNames: [ 'id', 'name', 'MAC address','IP address', 'pxe enabled',  ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'iface_name', index: 'iface_name', width: 10,},
            { name: 'iface_mac_addr', index: 'iface_mac_addr', width: 10 },
            { name: 'iface_ip', index: 'iface_ip', width: 10 },
            { name: 'iface_pxe', index: 'iface_pxe', width: 10 },
        ],
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            // ip address
            var iface_id = $(grid).getCell(rowid, 'pk');
            $.ajax({
                url     : '/api/ip?iface_id=' + iface_id,
                type    : 'GET',
                success : function(data) {
                    if(data.length == 1) {
                        $(grid).setCell(rowid, 'iface_ip', data[0].ip_addr);
                    } else {
                        $(grid).setCell(rowid, 'iface_ip', 'none');
                    }
                }
            });
            if(rowdata.iface_pxe == '1') { 
                $(grid).setCell(rowid, 'iface_pxe', 'yes');
            } else {
                $(grid).setCell(rowid, 'iface_pxe', 'no');
            }
        },
    });
}

// load component details grid for a node
function node_components_tab(cid, eid) {
    // get node's cluster components
    var node;
    $.ajax({
        url     : '/api/node?node_id=' + eid,
        type    : 'GET',
        async   : false,
        success : function(data) {
            node = data[0];
        }
    });

    // node's components grid
    var node_components_route = '/api/component?component_nodes.node.node_id=' + eid;
    var grid = create_grid({
        url: node_components_route + '&expand=component_type',
        content_container_id: cid,
        grid_id: 'node_ifaces_tab' + eid,
        rowNum : 7,
        action_delete: 'no',
        caption: 'Components',
        colNames: [ 'ID', 'Component', 'Version' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'component_type.component_name', index: 'component_type.component_name', width: 200 },
            { name: 'component_type.component_version', index: 'component_type.component_version', width: 200 },
        ],
    });

    // add components
    var addButton   = $('<a>', { text : 'Add component' }).prependTo( $('#' + cid) )
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', function (e) {
        (new KanopyaFormWizard({
            title      : 'Add components',
            id         : node.service_provider_id,
            displayed  : [ 'node_hostname', 'component_types' ],
            rawattrdef : {
                node_hostname : {
                    label : 'Hostname',
                    value : node.node_hostname
                },
                component_types : {
                    label        : 'Components to add',
                    type         : 'relation',
                    relation     : 'multi',
                    is_mandatory : 1,
                    is_editable  : 1,
                    hide_existing : 1,
                }
            },
            optionsCallback : function (name) {
                if (name === 'component_types') {
                    // Get the component types supported by this service provider only
                    return ajax('GET', '/api/cluster/' + node.service_provider_id +
                                       '/service_provider_type/component_types?deployable=1');
                }
                return false;
            },
            valuesCallback : function (type, id) {
                var node_component_types = ajax('GET', node_components_route)
                                     .map(function (component) { return component.component_type_id; });

                return { component_types: node_component_types };
            },
            submitCallback : function(data, $form, opts, onsuccess, onerror) {
                var params = { node: node, components: [] };
                for (var index in data.component_types) {
                    params.components.push({ component_type_id: data.component_types[index] });
                }
                ajax('PUT', '/api/cluster/' + node.service_provider_id, params, onsuccess, onerror);
            }
        })).start();
    });
}

