// store handlers during menu creation, used for content callbacks
var _content_handlers = {};

var SQLops = {
'eq' : '=',        // equal
'ne' : '<>',       // not equal
'lt' : '<',        // less than
'le' : '<=',       // less than or equal
'gt' : '>',        // greater than
'ge' : '>=',       // greater than or equal
'bw' : 'LIKE',     // begins with
'bn' : 'NOT LIKE', // doesn't begin with
'in' : 'LIKE',     // is in
'ni' : 'NOT LIKE', // is not in
'ew' : 'LIKE',     // ends with
'en' : 'NOT LIKE', // doesn't end with
'cn' : 'LIKE',     // contains
'nc' : 'NOT LIKE'  // doesn't contain
};

var searchoptions = { sopt : $.map(SQLops, function(n) { return n; } ) };

function reload_content(container_id, elem_id) {
    //alert(_content_handlers['content_hosts']);
    //alert('Reload' + container_id);
    if (_content_handlers[container_id]) {
        if (_content_handlers[container_id]['onLoad']) {
           
            // Clean prev container content
            var current_content = $('.current_content')
            current_content.removeClass('current_content');
            current_content.children().remove();

            // Tag this container as current
            $('#' + container_id).addClass('current_content');

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
    
    // Override generic behavior, custom detail handling
    if (menu_links.onSelectRow) {
        menu_links.onSelectRow(elem_id);
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

// Callback when click on remove icon for a row
function removeGridEntry (grid_id, id, url) {
    var dialog_height   = 120;
    var dialog_width    = 300;
    $("#"+grid_id).jqGrid(
            'delGridRow',
            id,
            {
                url             : url + '/' + id,
                ajaxDelOptions  : { type : 'DELETE'},
                modal           : true,
                drag            : false,
                resize          : false,
                width           : dialog_width,
                height          : dialog_height,
                top             : ($(window).height() / 2) - (dialog_height / 2),
                left            : ($(window).width() / 2) - (dialog_width / 2),
                afterComplete   : function () {$("#"+grid_id).trigger('gridChange')}
            }
    );
}

function create_grid(options) {

    var content_container = $('#' + options.content_container_id);
    var pager_id = options.grid_id + '_pager';

    // Grid class allow to manipulate grid (show_detail of a row) even if grid is associated to an instance (same grid logic but different id)
    var grid_class = options.grid_class || options.grid_id;
    content_container.append($("<table>", {'id' : options.grid_id, 'class' : grid_class}));

    if (!options.pager) {
        content_container.append("<div id='" + pager_id + "'></div>");
    }

    $.each(options.colModel, function (model) {
        model.searchoptions = searchoptions;
        model.search = true;
    });

    options.afterInsertRow = options.afterInsertRow || $.noop;

    // Add delete action column
    options.colNames.push('');
    options.colModel.push({index:'action_remove', width : '40px', formatter: 
        function(cell, formatopts, row) {
            // We can't directly use 'actions' default formatter because it not support DELETE
            // So we implement our own action delete formatter based on default 'actions' formatter behavior
            var remove_action = '';
            remove_action += '<div class="ui-pg-div ui-inline-del"';
            remove_action += 'onmouseout="jQuery(this).removeClass(\'ui-state-hover\');"';
            remove_action += 'onmouseover="jQuery(this).addClass(\'ui-state-hover\');"';
            remove_action += 'onclick="removeGridEntry(\''+  options.grid_id + '\',' +row.pk + ',\'' + options.url + '\')" style="float:left;margin-left:5px;" title="Delete selected row">';
            remove_action += '<span class="ui-icon ui-icon-trash"></span>';
            remove_action += '</div>';
            return remove_action;
        }});
    var actions_col_idx = options.colNames.length - 1;

    var grid = $('#' + options.grid_id).jqGrid({ 
        jsonReader : {
            root: "rows",
            page: "page",
            total: "pages",
            records: "records",
            repeatitems: false,
        },

        afterInsertRow: function(rowid, rowdata, rowelem) { return options.afterInsertRow(grid, rowid, rowdata, rowelem); },

        height: options.height || 'auto',
        //width: options.width || 'auto',
        autowidth   : true,
        shrinkToFit : true,
        colNames: options.colNames,
        colModel: options.colModel,
        pager: options.pager || '#' + pager_id,
        altRows: true,
        rowNum: options.rowNum || 10,
        rowList: options.rowList || undefined,

//        onSelectRow: function (id) {
//            var row_data = $('#' + options.grid_id).getRowData(id);
//            show_detail(options.grid_id, id, row_data);
//        },

        onCellSelect: function(rowid, index, contents, target) {
            if (index != actions_col_idx) {
                var row_data = $('#' + options.grid_id).getRowData(rowid);
                show_detail(grid_class, rowid, row_data)
            }
        },

        loadError: function (xhr, status, error) {
            var error_msg = xhr.responseText;
            alert('ERROR ' + error_msg + ' | status : ' + status + ' | error : ' + error); 
        },

        datatype: function (postdata) {
            var data = { dataType : 'jqGrid' };

            if (postdata.page) {
                data.page = postdata.page;
            }

            if (postdata.rows) {
                data.rows = postdata.rows;
            }

            if (postdata.sidx) {
                data.order_by = postdata.sidx;
                if (postdata.sord == "desc") {
                    data.order_by += " DESC";
                }
            }

            if (postdata._search) {
                var operator = SQLops[postdata.searchOper];
                var query = postdata.searchString;

                if (postdata.searchOper == 'bw' || postdata.searchOper == 'bn') query = query + '%';
                if (postdata.searchOper == 'ew' || postdata.searchOper == 'en' ) query = '%' + query;
                if (postdata.searchOper == 'cn' || postdata.searchOper == 'nc' ||
                    postdata.searchOper == 'in' || postdata.searchOper == 'ni') {
                    query = '%' + query + '%';
                }

                data[postdata.searchField] = (operator != "=" ? operator + "," : "") + query;
            }

            $.getJSON(options.url, data, function (data) {
                var thegrid = jQuery('#' + options.grid_id)[0];
                thegrid.addJSONData(data);
            });
        },
    });
    
    $('#' + options.grid_id).jqGrid('navGrid', '#' + pager_id, { edit: false, add: false, del: false }); 

   //$('#' + options.grid_id).jqGrid('setGridWidth', $('#' + options.grid_id).closest('.current_content').width() - 20, true);

    return grid;
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



