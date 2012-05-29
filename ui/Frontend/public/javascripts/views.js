// store handlers during menu creation, used for content callbacks
var _content_handlers = {};

function reload_content(container_id, elem_id) {
    //alert(_content_handlers['content_hosts']);
    //alert('Reload' + container_id);
    if (_content_handlers[container_id]) {
        if (_content_handlers[container_id]['onLoad']) {
           
            // Clean container content
            $('#' + container_id).html('');
           
            // Fill container using related handler
            var handler = _content_handlers[container_id]['onLoad'];
            handler(container_id, elem_id);
        }
    }
}

// Not used
function create_all_content() {
    for (var container_id in content_def) {
        create_content(container_id);
    }
}

function show_detail(grid_id, elem_id, row_data) {

    var menu_links = details_def[grid_id];
    
    // Not defined details menu
    if (menu_links === undefined) {
        alert('Details not defined yet ( menu.conf.js -> details_def["' + grid_id + '"] )');
        return;
    }
    
    // Details accessible from menu (dynamic loaded menu)
    if (menu_links.link_to_menu) {
        var view_link_id = 'link_view_' + row_data[menu_links.label_key].replace(/ /g, '_') + '_' + elem_id;
        $('#' + view_link_id + ' > .view_link').click();
        return;
    }
    
    // Else, modal details
    var id = 'view_detail_' + elem_id;
    var view_detail_container = $('<div></div>');
    build_detailmenu(view_detail_container, id, menu_links, elem_id);
    
    //var dialog = $('<div></div>')
    var dialog = $(view_detail_container)
    .dialog({
        autoOpen: true,
        modal: true,
        title: "detail entity " + elem_id,//link.attr('title' + '#content'),
        width: 800,
        height: 500,
        resizable: true,
        draggable: false,
        close: function(event, ui) { $(this).remove(); }, // detail modals are never closed, they are destroyed
        buttons: {
            Ok: function() {
                //$(this).find('#target').submit();
                //loading_start();
                $(this).dialog('close');
                
            },
            Cancel: function() {
                $(this).dialog('close');
            }
        },
    });
    
    // Show the view
    //$('#' + id).show();
    
    // Load first tab content
    reload_content('content_' + menu_links[0]['id'], elem_id);
        
    //dialog.load('/api/host/' + elem_id);
    //dialog.load('/details/iaas.html');

}

function create_grid(content_container_id, grid_id, colNames, colModel) {
    
    var content_container = $('#' + content_container_id);
    //var grid_id = content_container_id + '_grid';
    var pager_id = grid_id + '_pager';
    
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
            var row_data = $('#' + grid_id).getRowData(id);
            show_detail(grid_id, id, row_data);
            //alert('Select row: ' + id);
        },
        loadError: function (xhr, status, error) {
            var error_msg = xhr.responseText;
            alert('ERROR ' + error_msg + ' | status : ' + status + ' | error : ' + error); 
        }
        // onReload ????
        //loadComplete: function (xhr) {}
    });
    
    $('#' + grid_id).jqGrid('navGrid','#' + pager_id,{edit:false,add:false,del:false}); 
    
    $('#' + grid_id).jqGrid('setGridWidth', $('#' + grid_id).parent().width()-20);
    
}
function reload_grid (grid_id,  data_route) {
    var grid = $('#' + grid_id);
    grid.jqGrid("clearGridData");
    $.getJSON(data_route, {}, function(data) { 
        //alert(data);
        for(var i=0;i<=data.length;i++) grid.jqGrid('addRowData',i+1,data[i]);
        grid.trigger("reloadGrid");
        
    });
    
}

$(document).ready(function () {

});



