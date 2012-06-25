// Current service instance
var service_id;

// Dashboard instance used for all services dashboard
var service_dashboard;

// DOM element used by dashboard
var dash_div;
var dash_header;
var dash_template;

function initServiceDashboard() {
    // Dashboard
    dash_div = $('<div id="service_dashboard" class="dashboard"></div>');
    var dash_layout_div = $('<div class="layout">');
    dash_layout_div.append('<div class="column first column-first"></div>');
    dash_layout_div.append('<div class="column second column-second"></div>');
    dash_layout_div.append('<div class="column third column-third"></div>');
    dash_div.append(dash_layout_div);

    // Dashboard actions
    dash_header = $('<div class="headerlinks"></div>');
    dash_header.append($('<button>', { 'class' : 'openaddwidgetdialog', html : 'Add Widget'}));
//    dash_header.append($('<button>', { 'class' : 'editlayout', html : 'Edit layout'}));
    dash_header.append($('<button>', { 'class' : 'savedashboard', html : 'Save Dashboard'}));

    //$('#view-container').append(dash_header);
    $('#view-container').append(dash_div);

    // Dashboard template
    var template_id = "template";
    dash_template =  $('<div id="template"></div>');
    $('body').append(dash_template);
    $("#template").hide();
    //$("#template").load("dashboard_templates.html", initDashboard);

    $.ajax({
        url: "dashboard_templates.html",
        async : false,
        success : function(data) {
            $('#template').html(data);
            initDashboard();
        }
      });

    function initDashboard() {

        // to make it possible to add widgets more than once, we create clientside unique id's
        // this id is update when loading existing widgets to always be the greater id
        var startId = 1;

        var s_dashboard = $('#service_dashboard').dashboard({

            debuglevel: 3,

            // override default settings
            loadingHtml: '<div class="loading"><img alt="Loading, please wait" src="/css/theme/loading.gif" /><p>Loading...</p></div>',

            // layout class is used to make it possible to switch layouts
            layoutClass:'layout',

            // feed for the widgets which are on the dashboard when opened
            json_data : {
                url: "jsonfeed/ondashboarddefault_widgets.json"
            },

            // json feed; the widgets whcih you can add to your dashboard
            addWidgetSettings: {
                widgetDirectoryUrl:"jsonfeed/widgetcategories.json",
                //dialogId: 'addwidgetdialog_' + elem_id
            },

            // Definition of the layout
            // When using the layoutClass, it is possible to change layout using only another class. In this case
            // you don't need the html property in the layout
            layouts :
                [
                 {title: "Layout1",
                     id: "layout1",
                     image: "layouts/layout1.png",
                     classname: 'layout-a'
                 },
                 { title: "Layout2",
                     id: "layout2",
                     image: "layouts/layout2.png",
                     classname: 'layout-aa'
                 },
                 { title: "Layout3",
                     id: "layout3",
                     image: "layouts/layout3.png",
                     classname: 'layout-ba'
                 },
                 { title: "Layout4",
                     id: "layout4",
                     image: "layouts/layout4.png",
                     classname: 'layout-ab'
                 },
                 { title: "Layout5",
                     id: "layout5",
                     image: "layouts/layout5.png",
                     classname: 'layout-aaa'
                 }
                 ]
        }); // end dashboard call

        // binding for a widgets is added to the dashboard
        s_dashboard.element.live('dashboardAddWidget',function(e, obj){
            var widget = obj.widget;

            s_dashboard.addWidget({
                "id":startId++,
                "title":widget.title,
                "url":widget.url,
                "column":widget.column || 'first',
                "metadata":widget.metadata
                },
                s_dashboard.element.find('.column:first')
            );
        });

        // binding for layout change
        s_dashboard.element.live('dashboardLayoutChanged',function(e){
            for (var widx in s_dashboard.widgets) {
                s_dashboard.widgets[widx].refreshContent();
            }
        });

        // binding for widget loaded
        s_dashboard.element.live('widgetLoaded',function(e, obj){

            var widgetEl = obj.widget.element;

            // Update the next id for future added widget
            var widget_id = parseInt(obj.widget.id);
            if (startId <= widget_id) {
                startId = widget_id + 1;
            }

            obj.widget.addMetadataValue("service_id", service_id);

            obj.widget.element.trigger('widgetLoadContent',{"widget":obj.widget});
        });

        service_dashboard = s_dashboard;
    } // end inner function initDasboard
}

function loadServicesOverview (container_id, elem_id) {
    var container = $('#' + container_id);
    var externalclustername = '';

    // First init
    if (service_dashboard === undefined) {
        initServiceDashboard();
    }

    service_id = elem_id;

    dash_div.hide();
    container.append(dash_header);
    container.append(dash_div);
    //container.append(dash_template);

    // Needed to have the container with a good height
    container.css('overflow', 'hidden');

    // Make jquery button (must be done after append to container, each time)
    container.find(".openaddwidgetdialog").button({ icons : { primary : 'ui-icon-plusthick' } });
    container.find(".savedashboard").button({ icons : { primary : 'ui-icon-disk' } });

    //service_dashboard.setLayout(undefined);
    //service_dashboard.setLayout('layout2');

    // Set save dashboard callback
    $('.savedashboard').click(function () {
        $.getJSON('/api/dashboard?dashboard_service_provider_id=' + elem_id, function (resp) {
            // Default ajax req params (create dashboard conf)
            var req = {
                    url     : '/api/dashboard',
                    type    : 'POST',
                    data    : {
                                dashboard_config : service_dashboard.serialize(),
                                dashboard_service_provider_id : elem_id
                    },
                    success : function () {alert('Dashboard saved')},
                    error   : function () {alert('An error occured')} // TODO error management
            }
            // Change req params for update id dashboard conf exists
            if (resp.length > 0) {
                req.type    = 'PUT';
                req.url = req.url + '/' + resp[0].pk;
            }

            // Update or Create
            $.ajax(req);
        });
    });

    // Clear dashboard (remove widgets)
    $.each(service_dashboard.widgets, function(id, widget) {
        widget.remove();
        delete service_dashboard.widgets[id];
    });

    // Retrieve saved conf and set dashboard
    var dashboard_data;
    $.getJSON('/api/dashboard?dashboard_service_provider_id=' + elem_id, function (resp) {
        // Default dashboard conf (TODO load default from server)
        var conf = {
                url : 'jsonfeed/ondashboarddefault_widgets.json'
        };
        // Load saved dashboard conf if exist
        if (resp[0]) {
            conf = JSON.parse(resp[0].dashboard_config);
        }
        // Init dashboard
        service_dashboard.init({
            json_data : conf
        });
        dash_div.show();
    });

}
