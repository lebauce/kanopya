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

// keep_last option is a quick fix to avoid remove content when opening details dialog
function reload_content(container_id, elem_id, keep_last) {
    if (_content_handlers.hasOwnProperty(container_id)) {
        if (_content_handlers[container_id]['onLoad']) {
            // Clean prev container content
            var current_content = $('.current_content');
            current_content.removeClass('current_content');

            if (keep_last === undefined || keep_last == false) {
                current_content.children().remove();
            } else {
                current_content.addClass('last_content');
            }

            // Tag this container as current
            $('#' + container_id).addClass('current_content');

            // Fill container using related handler
            var handler = _content_handlers[container_id]['onLoad'];
            handler(container_id, elem_id);

            // Fill info panel
            if (_content_handlers[container_id]['info']) {
                $('#info-container').load(_content_handlers[container_id]['info'].url);
            } else {
                $('#info-container').html('');
            }
        }
    }
}

// Not used
function create_all_content() {
    for (var container_id in content_def) {
        create_content(container_id);
    }
}

// function show_detail manage grid element details
// param 'details' is optionnal and allow to specify/override details_def for this grid
function show_detail(grid_id, grid_class, elem_id, row_data, details) {

    var details_info = details || details_def[grid_class];
    
    // Not defined details menu
    if (details_info === undefined) {
        //console.log('No details for grid ' +  grid_class);
        return;
    }
    
    // Details accessible from menu (dynamic loaded menu)
    if (details_info.link_to_menu) {
        var view_link_id = 'link_view_' + row_data[details_info.label_key].replace(/ /g, '_') + '_' + elem_id;
        $('#' + view_link_id + ' > .view_link').click();
        return;
    }

    // Override generic behavior, custom detail handling
    if (details_info.onSelectRow) {
        details_info.onSelectRow(elem_id, row_data, grid_id);
        return;
    }

    // Else, modal details
    var id = 'view_detail_' + elem_id;
    var view_detail_container = $('<div></div>');

    //build_detailmenu(view_detail_container, id, details_info.tabs, elem_id);
    build_submenu(view_detail_container, id, details_info.tabs, elem_id);
    view_detail_container.find('#' + id).show();

    // Set dialog title using column defined in conf
    var title = details_info.title && details_info.title.from_column && row_data[details_info.title.from_column];

    if (!(details_info.noDialog)) {
        var dialog = $(view_detail_container)
        .dialog({
            autoOpen    : true,
            modal       : true,
            title       : title,
            width       : 800,
            height      : details_info.height || 500,
            resizable   : details_info.resizable || false,
            close: function(event, ui) {
                if (details_info.onClose) {details_info.onClose()}
                $('.last_content').addClass('current_content').removeClass('last_content');
                $(this).remove(); // detail modals are never closed, they are destroyed
            },
            buttons: {
                Ok: function() {
                    if (details_info.onOk) {details_info.onOk()}
                    $(this).dialog('close');
                    
                },
                Cancel: function() {
                    $(this).dialog('close');
                }
            },
        });
        // Remove dialog title if wanted
        if (details_info.title == 'none') {
            $(view_detail_container).dialog('widget').find(".ui-dialog-titlebar").hide();
        }
    }
    else {
        var masterview  = $('#' + grid_id).parents('div.master_view');
        $(masterview).hide();
        $(masterview).after($(view_detail_container).find('div.master_view').addClass('toRemove'));
    }

    // Load first tab content
    reload_content('content_' + details_info.tabs[0]['id'] + '_' + elem_id, elem_id, true);
}

// Callback when click on remove icon for a row
function removeGridEntry (grid_id, id, url, method) {
    var dialog_height   = 120;
    var dialog_width    = 300;
    var delete_url      = url.split('?')[0] + '/' + id;
    var call_type       = 'DELETE';
    if (method) {
        delete_url += '/' + method;
        call_type = 'POST';
    }
    $("#"+grid_id).jqGrid(
            'delGridRow',
            id,
            {
                url             : delete_url,
                ajaxDelOptions  : { type : call_type },
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

function editEntityRights(grid, rowid, rowdata, rowelem, options) {
    var callback;
    var details = {
        tabs : [ { label : 'Assigned permissions',
                   id : 'rights',
                   onLoad : function(cid, eid) {
                                callback = loadPermissionsModal(cid, eid, options.elem_name);
                            }
                 } ],

        title : 'Assigned permissions',
        onOk : function () { callback(); }
    };
    show_detail('entity_rights', 'entity_rights', rowelem.pk, rowdata, details);
    return false;
}

function create_grid(options) {

    var content_container = $('#' + options.content_container_id);
    var pager_id = options.grid_id + '_pager';

    // Grid class allow to manipulate grid (show_detail of a row) even if grid is associated to an instance (same grid logic but different id)
    var grid_class = options.grid_class || options.grid_id;

    if (! options.before_container) {
        content_container.append($("<table>", {'id' : options.grid_id, 'class' : grid_class}));

    } else {
        options.before_container.before($("<table>", {'id' : options.grid_id, 'class' : grid_class}));
    }

    if (!options.pager) {
        content_container.append("<div id='" + pager_id + "'></div>");
    }

    $.each(options.colModel, function (model) {
        model.searchoptions = searchoptions;
        model.search = true;
    });

    options.afterInsertRow  = options.afterInsertRow || $.noop;
    options.gridComplete    = options.gridComplete || $.noop;

    var deleteHandler = $.noop;
    var actions_col_idx = options.colNames.length;
    if (options.action_delete === undefined || options.action_delete != 'no' || options.rights) {
        // Delete handler
        var delete_url_base    = (options.action_delete && options.action_delete.url) || options.url;
        var delete_method_call = (options.action_delete && options.action_delete.method) || null;
        if (options.action_delete && options.action_delete.callback) {
            deleteHandler = options.action_delete.callback;
        } else {
            deleteHandler = function(rowid) {
                removeGridEntry( options.grid_id, rowid, delete_url_base, delete_method_call );
            }
        }

        options.colNames.push('');
        options.colModel.push({index:'actions', width : '40px', formatter:
            function(cell, formatopts, row) {
                var action = '';
                // Add delete action column (by default)
                if (options.action_delete === undefined || options.action_delete != 'no') {
                    // We can't directly use 'actions' default formatter because it not support DELETE
                    // So we implement our own action delete formatter based on default 'actions' formatter behavior
                    action += '<div class="ui-pg-div ui-inline-del"';
                    action += 'onmouseout="jQuery(this).removeClass(\'ui-state-hover\');"';
                    action += 'onmouseover="jQuery(this).addClass(\'ui-state-hover\');"';
                    action += ' style="float:left;margin-left:5px;" title="Delete this ' + (options.elem_name || 'element') + '">';
                    action += '<span class="ui-icon ui-icon-trash"></span>';
                    action += '</div>';
                }

                if (options.rights) {
                    // We can't directly use 'actions' default formatter because it not support DELETE
                    // So we implement our own action delete formatter based on default 'actions' formatter behavior
                    action += '<div class="ui-pg-div ui-inline-perms"';
                    action += 'onmouseout="jQuery(this).removeClass(\'ui-state-hover\');"';
                    action += 'onmouseover="jQuery(this).addClass(\'ui-state-hover\');"';
                    action += ' style="float:left;margin-left:5px;" title="Edit permissions for ' + (options.elem_name || 'element') + '">';
                    action += '<span class="ui-icon ui-icon-key"></span>';
                    action += '</div>';
                }

                return action;
            }
        });
    } else if (options.treeGrid === true) {
        // TreeGrids strangely want an additional column so we push an empty one...
        options.colNames.push('');
        options.colModel.push({hidden : true});
    }

    var grid = $('#' + options.grid_id).jqGrid({ 
        jsonReader : {
            root: "rows",
            page: "page",
            total: "pages",
            records: "records",
            repeatitems: false,
        },

        gridComplete    : options.gridComplete,
        treeGrid        : options.treeGrid      || false,
        treeGridModel   : options.treeGridModel || '',
        ExpandColumn    : options.ExpandColumn  || '',
        caption         : options.caption || '',
        height          : options.height || 'auto',
        autowidth       : true,
        shrinkToFit     : true,
        colNames        : options.colNames,
        colModel        : options.colModel,
        sortname        : options.sortname,
        sortorder       : options.sortorder,
        pager           : options.pager || '#' + pager_id,
        altRows         : true,
        rowNum          : options.rowNum || 10,
        rowList         : options.rowList || undefined,
        autoencode      : true,

        afterInsertRow  : function(rowid, rowdata, rowelem) {
            // Manage delete action callback
            $(this).find('#'+rowid+' .ui-inline-del').click( function() { deleteHandler(rowid) } );

            // Manage permissions
            $(this).find('#'+rowid+' .ui-inline-perms').click( function() { editEntityRights(grid, rowid, rowdata, rowelem, options) } );

            // Callback custom handler
            return options.afterInsertRow(this, rowid, rowdata, rowelem);
        },

        onCellSelect    : function(rowid, index, contents, target) {
            // Test if some options disable details
            if (index != actions_col_idx && ! options.deactivate_details && ! options.colModel[index].nodetails) {
                // Callback before show details, must return true if defined
                if ((! options.beforeShowDetails) || options.beforeShowDetails(options.grid_id, rowid)) {
                    var row_data = $('#' + options.grid_id).getRowData(rowid);
                    show_detail(options.grid_id, grid_class, rowid, row_data, options.details)
                }
            }
        },

        loadError       : function (xhr, status, error) {
            var error_msg = xhr.responseText;
            alert('ERROR ' + error_msg + ' | status : ' + status + ' | error : ' + error); 
        },

        url             : options.url, // not used by jqGrid (handled by datatype option, see below) but we want this info in grid
        datatype        : (options.hasOwnProperty('url')) ? function (postdata) {
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

            var thegrid = jQuery('#' + options.grid_id)[0];
            $.getJSON(options.url, data, function (data) {
                thegrid.addJSONData(data);
            });
        } : 'local',
        data: (options.hasOwnProperty('data')) ? options.data : []
    });

    $('#' + options.grid_id).jqGrid(
            'navGrid',
            '#' + pager_id,
            { edit: false, add: false, del: false },    // pager actions
            {},
            {},
            {},
            { closeAfterSearch: true }                  // search options
    );

    // If exists details conf then we set row as selectable
    if (options.details || details_def[grid_class]) {
       grid.addClass('selectable_rows');
    }

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

function createTreeGrid(params, pageSize) {
    var grid = create_grid(params);
    $(grid)[0].addJSONData({
        total   : params.data.length / pageSize,
        page    : 1,
        records : params.data.length,
        rows    : params.data
    });
    grid.trigger('reloadGrid');
}

$(document).ready(function () {

});



