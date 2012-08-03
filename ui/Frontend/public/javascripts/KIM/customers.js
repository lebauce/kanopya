require('modalform.js');
require('detailstable.js');

function Customers() {
    Customers.prototype.load_content = function(container_id, elem_id) {
        function createAddCustomerButton(cid) {
            var container = $('#' + cid);
            var user_fields  = {
                user_firstname : {
                    label : 'First Name',
                    type  : 'text'
                },
                user_lastname : {
                    label : 'Last Name',
                    type  : 'text'              
                },
                user_email : {
                    label : 'Email',
                    type  : 'text'
                },
                user_desc : {
                    label : 'Description',
                    type  : 'textarea'
                },
                user_login : {
                    label : 'Login',
                    type  : 'text'
                },
                user_password : {
                    label : 'Password',
                    type  : 'password'
                },
            };
            var user_opts = {
                title    : 'New customer',
                name     : 'user',
                fields   : user_fields,
                callback : function(data) {
                    $.ajax({
                            type: 'POST', 
                            async: false, 
                            url: '/api/user/'+ data.user_id +'/setProfiles', 
                            data: JSON.stringify( { profile_names: ['Customer'] } ), 
                            contentType: 'application/json',
                            dataType: 'json', 
                    });
                    reload_grid('customers_list', '/api/user?user_profiles.profile.profile_name=Customer');
                }
            };
                        
            var button = $("<button>", {html : 'Add a customer'}).button({
                icons   : { primary : 'ui-icon-plusthick' }
            });
            button.bind('click', function() {
                new ModalForm(user_opts).start();
            });   
            container.append(button);
        };
    
        create_grid({
            url: '/api/user?user_profiles.profile.profile_name=Customer',
            content_container_id: container_id,
            grid_id: 'customers_list',
            colNames: ['user id','first name','last name','email' ],
            colModel: [    
                 {name:'user_id',index:'user_id', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'user_firstname',index:'user_firstname', width:120},
                 {name:'user_lastname',index:'user_lastname', width:120},
                 {name:'user_email',index:'user_email', width:250,}
            ]
        });
        
        createAddCustomerButton(container_id);
    }
    
    Customers.prototype.load_details = function(container_id, elem_id) {
        var customer_opts = {
            name   : 'user',
            fields : { user_firstname : {label: 'First name'},
                       user_lastname  : {label: 'Last name'},
                       user_email     : {label: 'Email'},
                       user_desc      : {label: 'Description'},
                    },
        };
        
        var details = new DetailsTable(container_id, elem_id, customer_opts);
       
        details.addAction({label: 'Update', action: function() {
            var form = new ModalForm({
                id       : elem_id,
                title    : 'Update customer',
                name     : 'user',
                fields   : customer_opts.fields,
                callback : function() { details.refresh(); }
            }).start();
        }});
        
        details.addAction({label: 'Delete', action: function() {
            $.ajax({ 
                type: 'delete', 
                async: false, 
                url: '/api/user/'+elem_id,
                success: function() { $('#'+container_id).closest('.master_view').parent().dialog('close'); },
                error: function(jqXHR, textStatus, errorThrown) { 
                    alert(jqXHR.responseText); } 
            });
            
        }});
        details.show();
    }

    Customers.prototype.load_services = function(container_id, elem_id) {
        create_grid({
            url: '/api/cluster?user_id='+elem_id,
            content_container_id: container_id,
            grid_id: 'customer_services_list',
            colNames: ['cluster id','Name', 'Description', '' ],
            colModel: [    
                 {name:'cluster_id',index:'cluster_id', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'cluster_name',index:'cluster_name', width:120},
                 {name:'cluster_desc',index:'cluster_desc', width:300},
                 {name:'actions', index : 'action', nodetails : true}
            ],
            details : {
                onSelectRow : function(eid, e, cid) {
                    // Yes, this scope is ugly
                    // But opening the service view from here is quite difficult
                    $('#' + cid).parents('.ui-dialog').find('.ui-dialog-buttonset').find('button').first().trigger('click');
                    $('#menuhead_Services').find('a').trigger('click');
                    setTimeout(function() { 
                        $('#link_view_aaa_' + eid).find('a').trigger('click');
                    }, 400);
                }
            },
            afterInsertRow  : function(grid, rowid, rowelem, rowdata) {
                var cell    = $(grid).find('tr#' + rowid).find('td[aria-describedby="customer_services_list_actions"]');
                var graph   = $('<a>', { text : 'Graph' }).button({ icons : { primary : 'ui-icon-image' } })
                                                          .appendTo(cell);
                var csv     = $('<a>', { text : 'CSV' }).button({ icons : { primary : 'ui-icon-script' } })
                                                        .appendTo(cell);
                $(graph).bind('click', function() {
                    showConsumptionGraph(rowid);
                });
                $(csv).bind('click', function() {
                    require('KIM/services.js');
                    var s   = Service(rowid);
                });
            }
        });
    }
    
    Customers.prototype.load_infos = function(container_id, elem_id) {
        function createAddCustomerInfoButton(cid) {
            var container = $('#' + cid);
            var user_fields  = {
                user_extension_key : {
                    label   : 'Field name',
                    type    : 'text',
                },
                user_extension_value : {
                    label   : 'Value',
                    type    : 'textarea'
                },
                user_id : {
                    type    : 'hidden',
                    value   : elem_id,
                },
            };
            var user_opts = {
                title    : 'New customer info',
                name     : 'userextension',
                fields   : user_fields,
            };
                            
            var button = $("<button>", {html : 'Add customer info'}).button({
                icons : { primary : 'ui-icon-plusthick' }
            });
            button.bind('click', function() {
                new ModalForm(user_opts).start();
            });   
            container.append(button);
        };        

        create_grid({
            url: '/api/userextension?user_id='+elem_id,
            content_container_id: container_id,
            grid_id: 'cutomer_infos_list',
            colNames: ['pk', 'field name', 'value'],
            colModel: [
                {name:'pk',index:'pk',width:100,sorttype:'int',hidden:true,key:true},
                {name:'user_extension_key',index:'user_extension_key',width:100,},
                {name:'user_extension_value',index:'user_extension_value',width:100,},
            ],
        });
        createAddCustomerInfoButton(container_id);
    }
}



var customers = new Customers();

// Return AggregateCombination id from its name for a service provider
function getCombiId(sp_id, combi_name) {
    var combi_id
    $.ajax({
        url     : '/api/aggregatecombination',
        async   : false,
        data    : {
            aggregate_combination_service_provider_id   : sp_id,
            aggregate_combination_label                 : combi_name
        },
        success : function (data) {
            if (data.length > 0) {
                combi_id = data[0].pk;
            }
        }
    });
    return combi_id;
}

// Display consumption graphs in dialog box
// Based on Billing ClusterMetric core and mem
function showConsumptionGraph(sp_id) {
    var cont = $('<div>');

    // Get combinations id (billing mem and core)
    var combi_mem_id    = getCombiId(sp_id, 'BillingMemory');
    var combi_core_id   = getCombiId(sp_id, 'BillingCores');

    // Dialog box containing graphs
    var dialog = cont.dialog({
        autoOpen: true,
        modal: true,
        title: 'Consumption',
        width: 800,
        height: 500,
        resizable: false,
        draggable: true,
        close: function(event, ui) {
            $(this).remove();
        },
        buttons: {
            Ok: function() {
                $(this).dialog('close');
            }
        },
    });

    // Graph div for core and mem
    function addGraph(combi_id) {
        var graph_div   = $('<div>', { 'class' : 'widgetcontent' });
        cont.append($('<div>', {'class' : 'widget'}).append(graph_div));
        graph_div.load('/widgets/widget_historical_service_metric.html', function() {
            $('.dropdown_container').remove();
            setGraphDatePicker(graph_div);
            showCombinationGraph(graph_div, combi_id, '', '', '', sp_id);
        });
    }
    addGraph(combi_mem_id);
    addGraph(combi_core_id);
}
