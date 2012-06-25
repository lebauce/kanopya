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
                        
            $('<hr/>').appendTo(container);
            var button = $("<button>", {html : 'new customer'});
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
        
        reload_grid('customers_list', '/api/user?user_profiles.profile.profile_name=Customer');
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
       
        
        details.addAction({label: 'update', action: function() {
            var form = new ModalForm({
                id       : elem_id,
                title    : 'Update customer',
                name     : 'user',
                fields   : customer_opts.fields,
                callback : function() { details.refresh(); }
            }).start();
        }});
        
        details.addAction({label: 'detele', action: function() {
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
            colNames: ['cluster id','name', 'description' ],
            colModel: [    
                 {name:'cluster_id',index:'cluster_id', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'cluster_name',index:'cluster_name', width:120},
                 {name:'cluster_desc',index:'cluster_desc', width:300},
            ]
        });
    }
    

    
    Customers.prototype.load_infos = function(container_id, elem_id) {
        
     function createAddCustomerInfoButton(cid) {
        var container = $('#' + cid);
        var user_fields  = {
        user_extension_key    : {
            label   : 'Field name',
            type    : 'text',
        },
        user_extension_value    : {
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
                        
            $('<hr/>').appendTo(container);
            var button = $("<button>", {html : 'new customer info'});
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

