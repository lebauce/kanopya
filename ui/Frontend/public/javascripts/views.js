



function create_grid(content_container_id, colNames, colModel) {
    
    var content_container = $('#' + content_container_id);
    //content_container.append('<div>Host Content</div>');
    content_container.append("<table id='" + content_container_id + "_grid'></table>");
    content_container.append("<div id='" + content_container_id + "_pager'></div>");

//    $("<table id='" + content_container_id + "_grid'></table>").appendTo(content_container);
    $('#' + content_container_id + '_grid').jqGrid({ 
        datatype: "local",
        //loadonce: true,
        height: 'auto',
        width: 'auto',
        colNames:colNames,
        colModel:colModel,
        //multiselect: true,
        //rowNum:5, rowList:[5,10,20,50],
        //caption: "Messages",
        pager : '#' + content_container_id + '_pager',
        altRows: true,
        onSelectRow: function (id) {
            alert('Select row: ' + id);
        },
    });
    
    $('#' + content_container_id + '_grid').jqGrid('navGrid','#' + content_container_id + '_pager',{edit:false,add:false,del:false});
    
    // Quick fix to remove unwanted bugged background (TODO study this bug, UPDATE: fix with good css include)
    //$('#lui_'  + content_container_id + '_grid').removeClass('ui-widget-overlay');
    
}
function reload_grid (content_container_id) {
    var mydata = [ 
                  {mess_id:"1",date:"2007-10-01",content:"rha"},
              ]; 
    for(var i=0;i<=mydata.length;i++) jQuery('#' + content_container_id + '_grid').jqGrid('addRowData',i+1,mydata[i]);
    $('#' + content_container_id + '_grid').trigger("reloadGrid");
}

$(document).ready(function () {

    create_grid('content_hosts', ['Mess ID','Date', 'content'],
                    [ 
                      {name:'mess_id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
                      {name:'date',index:'date', width:90, sorttype:"date"},
                      {name:'content',index:'content', width:200,}
                    ]
    );
    reload_grid('content_hosts');

    create_grid('content_iaas', ['ID','Name', 'Type', 'Status', 'Admin IP', 'Auto-scale'],
            [ 
              {name:'id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
              {name:'date',index:'date', width:90, sorttype:"date"},
              {name:'type',index:'type', width:200,},
              {name:'status',index:'status', width:200,},
              {name:'admin_ip',index:'admin_ip', width:200,},
              {name:'auto_scale',index:'auto_scale', width:200,},
            ]
    );
});
