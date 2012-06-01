function loadUsers (container_id, elem_id) {
	create_grid(container_id, 'users_list',
            ['user id','user login', 'user email'],
            [ 
             {name:'user_id',index:'user_id', width:60, sorttype:"int", hidden:true, key:true},
             {name:'user_login',index:'user_login', width:90, sorttype:"date"},
             {name:'user_email',index:'user_email', width:200,}
           ]);
    reload_grid('users_list', '/api/user');
}
