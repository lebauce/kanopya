var chart;

        // Function for loading a highchart pie
            function loadPie(title, data, obj) {
                var pieId = 'pie' + obj.closest('.widget').attr("id");
                chart = new Highcharts.Chart({
                    chart: {
                        renderTo: pieId,
                        plotBackgroundColor: null,
                        plotBorderWidth: null,
                        plotShadow: false,
                        width:650
                    },
                    title: {
                        text: title
                    },
                    tooltip: {
                        formatter: function() {
                            return '<b>'+ this.point.name +'</b>: '+ this.y + ' (' + ((this.y/this.total)*100).toFixed(0) + '%)';
                        }
                    },
                    plotOptions: {
                        pie: {
                            allowPointSelect: true,
                            cursor: 'pointer',
                            dataLabels: {
                                enabled: true,
                                color: '#000000',
                                connectorColor: '#000000',
                                formatter: function() {
                                    return '<b>'+ this.point.name +'</b>: '+ ' ' + ((this.y/this.total)*100).toFixed(0) + '%';
                                }
                            }
                        }
                    },
                        series: [{
                        type: 'pie',
                        name: title,
                        data: data
                    }]
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
            
            

// This is the code for definining the dashboard
      $(document).ready(function() {
        // load the templates
        $('#view-dashboard').append('<div id="templates"></div>');
        $("#templates").hide();
        $("#templates").load("dashboard_templates.html", initDashboard);
        function initDashboard() {

          // to make it possible to add widgets more than once, we create clientside unique id's
          // this is for demo purposes: normally this would be an id generated serverside
          var startId = 100;

          var dashboard = $('#dashboard').dashboard({
              
            // override default settings
            loadingHtml: '<div class="loading"><img alt="Loading, please wait" src="/css/theme/loading.gif" /><p>Loading...</p></div>',
              
            // layout class is used to make it possible to switch layouts
            layoutClass:'layout',
            
            // feed for the widgets which are on the dashboard when opened
            json_data : {
              //url: "jsonfeed/mywidgets_charts.json"
                url: "jsonfeed/ondashboarddefault_widgets.json"
            },
            
            // json feed; the widgets whcih you can add to your dashboard
            addWidgetSettings: {
              widgetDirectoryUrl:"jsonfeed/widgetcategories.json"
            },
            
            // Definition of the layout
            // When using the layoutClass, it is possible to change layout using only another class. In this case
            // you don't need the html property in the layout

            layouts :
              [
                { title: "Layout1",
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
          dashboard.element.live('dashboardAddWidget',function(e, obj){
            var widget = obj.widget;

            dashboard.addWidget({
              "id":startId++,
              "title":widget.title,
              "url":widget.url,
              "metadata":widget.metadata
              }, dashboard.element.find('.column:first'));
          });
          
          // binding for layout change
          dashboard.element.live('dashboardLayoutChanged',function(e){
            for (var widx in dashboard.widgets) {
                dashboard.widgets[widx].refreshContent();
            }
          });
          
          // binding for widget setting
          $('.widget').live('widgetEdit',function(e, obj){
              console.log('EDIT METADATA');
             alert('EDIT METADATA OF ' + obj.widget.id);
             obj.widget.addMetadataValue('data1_' + obj.widget.id, 'toto');
          });
          
          // binding TEST
          $('.widget').live('widgetRefresh',function(e, obj){
              console.log('Refresh');
             alert('Refresh ' + obj.widget.id);
             //obj.widget.addMetadataValue('data1_' + obj.widget.id, 'toto');
          });

                    // Make sure the pie is loaded when the widget is loaded. This makes it possible to add the pie more than once
                    dashboard.element.live('widgetLoaded',function(e, obj){

                       
                        
                        var widgetEl = obj.widget.element;
//
//                        widgetEl.append('<div class="new-widget" />');
//                        alert('WIdget loaded ' + obj.widget.id);
                        if (widgetEl.find('.do_unique_id').length > 0) {
                            widgetEl.find('.do_unique_id').each( function () {
                                $(this).attr( 'id', $(this).attr('id') + obj.widget.id);
                                $(this).removeClass('.do_unique_id');
                            });
                        }

                        widgetEl.append('<div class="widget-info" id="'+ obj.widget.id +'"/>');
                        obj.widget.element.trigger('widgetLoadContent',{"widget":obj.widget});
                        
                        
                        
                        if (widgetEl.find('.piecontainer').length > 0) {
                            // The pie needs a dic with a unique id, so create one with the widget ID (which is unique)
                            widgetEl.find('.pielocation').append('<div id="pie' + obj.widget.id + '"></div>');

                            // Some data for my pie
                            var data = [
                                ['Firefox',   45.0],
                                ['IE',       26.8],
                                {
                                    name: 'Chrome',
                                    y: 12.8,
                                    sliced: true,
                                    selected: true
                                },
                                ['Safari',    8.5],
                                ['Opera',     6.2],
                                ['Others',   0.7]
                            ];

                            loadPie('My Pie',data,widgetEl);

                        }
                        
                        if (widgetEl.find('.nodes_bargraph_container').length > 0) {
                            // The graph needs a div with a unique id, so create one with the widget ID (which is unique)
                            var div_id = 'bargraph_' + obj.widget.id;
                            widgetEl.find('.nodes_bargraph_location').append('<div id="' + div_id + '"></div>');

                            var nodelist = ['node1', 'node2', 'node3'];
                            var values = ['5', '17', '8'];
                            var max = 20;
                            var title = 'toulouloup';

                            nodemetricCombinationBarGraph(values, nodelist, div_id, max, title);
                        }
                        
                    });


          // the init builds the dashboard. This makes it possible to first unbind events before the dashboars is built.
          dashboard.init();
        
          $('.savedashboard').click(function () { console.log(dashboard.serialize())});
        }
        
        
        
      });


