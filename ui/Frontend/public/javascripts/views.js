var content_def = {
    'content_hosts' : {
        grid : { 
            params : {
                colNames : ['ID','Base hostname', 'Initiator name'],
                colModel : [ 
                            {name:'entity_id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
                            {name:'host_hostname',index:'host_hostname', width:90, sorttype:"date"},
                            {name:'host_initiatorname',index:'host_initiatorname', width:200,}
                          ],
            },
            data_route : '/api/host',
        }
    },
    'content_iaas' : { 
        grid : { 
            params : {
                colNames : ['ID','Name', 'Type', 'Status', 'Admin IP', 'Auto-scale'],
                colModel : [ 
                            {name:'id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
                            {name:'date',index:'date', width:90, sorttype:"date"},
                            {name:'type',index:'type', width:200,},
                            {name:'status',index:'status', width:200,},
                            {name:'admin_ip',index:'admin_ip', width:200,},
                            {name:'auto_scale',index:'auto_scale', width:200,},
                            ],
            },
            data_route : '/api/cluster',
        }
    },
};

function reload_content(container_id) { 
    //alert('Reload' + container_id);
    if (content_def[container_id]) {
        if (content_def[container_id]['grid']) {
            reload_grid(container_id, content_def[container_id]['grid']['data_route']);
        }
    }
}

function create_content(container_id) {
    var grid_params = content_def[container_id]['grid']['params'];
    create_grid(container_id, grid_params['colNames'], grid_params['colModel'])
}

function create_all_content() {
    for (var container_id in content_def) {
        create_content(container_id);
    }
}

function show_detail(elem_id) {
    var dialog = $('<div></div>')
    .dialog({
        autoOpen: true,
        modal: true,
        title: "detail entity " + elem_id,//link.attr('title' + '#content'),
        width: 500,
        height: 500,
        resizable: true,
        draggable: false,
        buttons: {
            Ok: function() {
                //$(this).find('#target').submit();
                //loading_start();
                //$(this).dialog('close');
            },
            Cancel: function() {
                $(this).dialog('close');
            }
        },
    });
    
    dialog.load('/api/host/' + elem_id);
    
//alert('pouet');
//return false;
 
    //dialog.dialog('open');
    //dialog.show();
    
    //    link.click(function() {
//        if ($(this).parents(".disabled").length) {
//            return false;
//        }
//        dialog.load($(this).attr('href'))
//        dialog.dialog('open');
//        return false;
//    });

}

function create_grid(content_container_id, colNames, colModel) {
    
    var content_container = $('#' + content_container_id);
    var grid_id = content_container_id + '_grid';
    var pager_id = content_container_id + '_pager';
    
    //content_container.append('<div>Host Content</div>');
    content_container.append("<table id='" + grid_id + "'></table>");
    content_container.append("<div id='" + pager_id + "'></div>");

    $('#' + grid_id).jqGrid({ 
        datatype: "local",
        //loadonce: true,
        height: 'auto',
        width: 'auto',
        colNames:colNames,
        colModel:colModel,
        //multiselect: true,
        //rowNum:5, rowList:[5,10,20,50],
        //caption: "Messages",
        pager : '#' + pager_id,
        altRows: true,
        onSelectRow: function (id) {
            show_detail(id);
            //alert('Select row: ' + id);
        },
    });
    
    $('#' + grid_id).jqGrid('navGrid','#' + pager_id,{edit:false,add:false,del:false}); 
    
}
function reload_grid (content_container_id,  data_route) {
    var grid = $('#' + content_container_id + '_grid');
    grid.jqGrid("clearGridData");
    $.getJSON(data_route, {}, function(data) { 
        //alert(data);
        for(var i=0;i<=data.length;i++) grid.jqGrid('addRowData',i+1,data[i]);
        grid.trigger("reloadGrid");
        
    });
    
}

$(document).ready(function () {
    create_all_content();
});
