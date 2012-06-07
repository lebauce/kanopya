function usersList (container_id, elem_id) {
	  function createAddUserButton(cid) {
        var user_fields  = {
                user_firstname    : {
                    label   : 'First Name',
                    type : 'text'
                },
                user_lastname    : {
                    label   : 'Last Name'
                },
                user_email    : {
                    label   : 'Email'
                },
                user_desc    : {
                    label   : 'Description',
                    type    : 'textarea'
                },
                user_login    : {
                    label   : 'Login'
                },
                user_password    : {
                    label   : 'Password'
                },
        };
        var user_opts    = {
            title       : 'Add a user',
            name        : 'user',
            fields      : user_fields,
        };
                    
        var button = $("<button>", {html : 'Add a user'});
        button.bind('click', function() {
            new ModalForm(user_opts).start();
        });   
        $('#' + cid).append(button);
    };
    
    var container = $('#' + container_id);
	create_grid(container_id, 'users_list',
            ['user id','user login', 'user email'],
            [ 
             {name:'user_id',index:'user_id', width:60, sorttype:"int", hidden:true, key:true},
             {name:'user_login',index:'user_login', width:90, sorttype:"date"},
             {name:'user_email',index:'user_email', width:200,}
           ]);
    reload_grid('users_list', '/api/user');
    createAddUserButton(container_id);
}

function loadGroups (container_id, elem_id) {
	create_grid(container_id, 'groups_list',
            ['group id','group name', 'group type'],
            [ 
             {name:'gp_id',index:'gp_id', width:60, sorttype:"int", hidden:true, key:true},
             {name:'gp_name',index:'gp_name', width:90, sorttype:"date"},
             {name:'gp_type',index:'gp_type', width:200,}
           ]);
    reload_grid('groups_list', '/api/gp?gp_type=User');
}
function groupsList (container_id, elem_id) {
	function createAddGroupButton(cid) {   
        var group_fields  = {
                gp_name    : {
                    label   : 'Group Name',
                     type    : 'text'
                },
                gp_type    : {
					//label   : 'group type',
                    type    : 'select',
                    options :  ['User','Cluster','System image','Host','Processor model','Host model','Powersupply card model','Distribution','Kernel'] 
                },
                gp_system    : {
					// label   : 'Group System',
                     type    : 'hidden',
                     value   :  '0'
                },
                
                gp_desc    : {
                    label   : 'Description',
                    type    : 'textarea'
                },
                
        };
        var group_opts    = {
            title       : 'Add a Group',
            name        : 'gp',
            fields      : group_fields,
        };
                    
        var button = $("<button>", {html : 'Add a group'});
        button.bind('click', function() {
            new ModalForm(group_opts).start();
        });   
        $('#' + cid).append(button);
    };
    
    var container = $('#' + container_id);
    create_grid(container_id, 'groups_list',
                 ['group id','group name', 'group type'],
                 [ 
             {name:'gp_id',index:'gp_id', width:60, sorttype:"int", hidden:true, key:true},
             {name:'gp_name',index:'gp_name', width:90, sorttype:"date"},
             {name:'gp_type',index:'gp_type', width:200,}
                 ]);
    reload_grid('groups_list', '/api/gp?gp_type=User');
    
    createAddGroupButton(container_id);
}
