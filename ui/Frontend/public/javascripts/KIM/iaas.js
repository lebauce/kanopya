function load_iaas_detail_hypervisor (container_id, elem_id) {
    var container = $('#' + container_id);
    $('<div>Hypervisor for iaas ID = ' + elem_id + '<div>').appendTo(container);
    create_grid(container_id, 'iaas_hyp_list',
            ['ID','Base hostname', 'Initiator name'],
            [ 
             {name:'entity_id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
             {name:'host_hostname',index:'host_hostname', width:90, sorttype:"date"},
             {name:'host_initiatorname',index:'host_initiatorname', width:200,}
           ]);
    reload_grid('iaas_hyp_list', '/api/host');
}

function load_iaas_content (container_id) {
    //alert('on load ' + id);
    var container = $('#' + container_id);
     
    create_grid(container_id, 'iaas_list',
                ['ID','Name', 'Type', 'State', 'Admin IP', 'Auto-scale'],
                [ 
                 {name:'id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'cluster_name',index:'cluster_name', width:90, sorttype:"date"},
                 {name:'cluster_type',index:'cluster_type', width:200,},
                 {name:'cluster_state',index:'cluster_state', width:200,},
                 {name:'admin_ip',index:'admin_ip', width:200,},
                 {name:'auto_scale',index:'auto_scale', width:200,},
                 ]);
    reload_grid('iaas_list', '/api/cluster');
    
    $('<div>Just another grid to show how to put several grid<div>').appendTo(container);
    
    create_grid(container_id, 'iaas_list2',
            ['ID','Name', 'Type', 'State'],
            [ 
             {name:'id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
             {name:'cluster_name',index:'cluster_name', width:90, sorttype:"date"},
             {name:'cluster_type',index:'cluster_type', width:200,},
             {name:'cluster_state',index:'cluster_state', width:200,},
             ]);
    reload_grid('iaas_list2', '/api/cluster');
}