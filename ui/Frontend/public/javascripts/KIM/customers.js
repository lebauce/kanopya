require('modalform.js');
require('detailstable.js');

function Customers() {
    Customers.prototype.load_content = function(container_id, elem_id) {
        function createAddCustomerButton(cid) {
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
                        
            var button = $("<button>", {html : 'new customer'});
            button.bind('click', function() {
                new ModalForm(user_opts).start();
            });   
            $('#' + cid).append(button);
        };
    
        var container = $('#' + container_id);
        create_grid({
            url: '/api/user?user_profiles.profile.profile_name=Customer',
            content_container_id: container_id,
            grid_id: 'customers_list',
            colNames: ['user id','first name','last name','user email' ],
            colModel: [    
                 {name:'user_id',index:'user_id', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'user_firstname',index:'user_firstname', width:120},
                 {name:'user_lastname',index:'user_lastname', width:120},
                 {name:'user_email',index:'user_email', width:250,}
            ]
        });
        
        //reload_grid('customers_list', '/api/user?user_profiles.profile.profile_name=Customer');
        createAddCustomerButton(container_id);
    }
    
    Customers.prototype.load_details = function(container_id, elem_id) {
        var customer_opts = {
            fields : {
                param1 : { value : 'toto' },
                param2 : { value : 'totdsjlkfjqmdlkfo' },
                param3 : { value : 't o t d dvdvev b  o' }
            }
        };
        
        new DetailsTable(container_id, elem_id, customer_opts);
    }
}

var customers = new Customers();

