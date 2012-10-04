require('detailstable.js');
require('common/formatters.js');
require('kanopyaformwizard.js');
require('modalform.js');

var g_user_id = undefined;

function user_addbutton_action(e, displayed) {
    // When called from user details, e is the user id, event instead.
    var displayed;
    var relations;
    if (e instanceof Object && e.data.displayed !== undefined) {
        displayed = e.data.displayed;
        relations = e.data.relations;
    } else {
        displayed = [ 'user_firstname', 'user_lastname', 'user_email', 
                      'user_desc', 'user_login', 'user_password', 
                      'user_lastaccess', 'user_creationdate',
                      'user_sshkey', 'user_profiles' ];

        relations = { 'quotas' : [ 'resource', 'current', 'quota' ] };
    }

    (new KanopyaFormWizard({
        title      : 'Add a user',
        type       : 'user',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : displayed,
        relations  : relations,
    })).start();
}

/* users class */
function Users() {
    Users.prototype.load_content = function(container_id, elem_id) {
        g_user_id = elem_id;
        create_grid({
            url: '/api/user',
            content_container_id: container_id,
            grid_id: 'users_list',
            details: { onSelectRow : user_addbutton_action },
            colNames: [ 'user id', 'first name', 'last name', 'login', 'email' ],
            colModel: [
                { name: 'user_id', index: 'user_id', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'user_firstname', index: 'user_firstname', width: 90, sorttype: "text" },
                { name: 'user_lastname', index: 'user_lastname', width: 90, sorttype: "text" },
                { name: 'user_login', index: 'user_login', width: 90, sorttype: "text" },
                { name: 'user_email', index: 'user_email', width: 200}
            ]
        });
        var user_addbutton  = $('<a>', { text : 'Add a user' }).appendTo('#' + container_id)
                                  .button({ icons : { primary : 'ui-icon-plusthick' } });

        var creation_attrs = [ 'user_firstname', 'user_lastname', 'user_email', 'user_desc',
                               'user_login', 'user_password', 'user_sshkey', 'user_profiles' ];
        var creation_relations = { 'quotas' : [ 'resource', 'quota' ] };
        $(user_addbutton).bind('click', { displayed : creation_attrs, relations : creation_relations }, user_addbutton_action);
    };
  
    Users.prototype.load_details = function(container_id, elem_id) {
        var users_opts = {
            name   : 'user',
            title  : 'User details',
            fields : { user_firstname   : {label: 'First name'},
                       user_lastname    : {label: 'Last name'},
                       user_email       : {label: 'Email'},
                       user_login       : {label: 'Login'},
                       user_creationdate: {label: 'Creation date'},
                       user_desc        : {label: 'Description'},
                    },
        };
        
        var details = new DetailsTable(container_id, elem_id, users_opts);
       
        details.addAction({label: 'update', action: function() {
            var form = new ModalForm({
                id       : elem_id,
                title    : 'Update user',
                name     : 'user',
                fields   : users_opts.fields,
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
    };
    
    Users.prototype.load_profiles = function(container_id, elem_id) {
        /* retrieve profiles list  */
        var container = $('#'+container_id);
        var table = $('<table>',  {id: 'profiles_table'});
        table.appendTo(container);
        
        var grid = table.jqGrid({
            datatype: 'local',
            colNames:['profile'],
            colModel :[ 
              {name:'profile_name', index:'profile_name', width:500, align:'left'}, 

            ],
            rowNum:10,
            sortorder: 'desc',
            viewrecords: true,
            gridview: true,
            autoencode: true,
        }); 

        $.ajax({
            url: '/api/user/'+elem_id+'/getProfiles',
            type: 'POST', 
            async: false, 
            //data: undefined, 
            //contentType: 'application/json',
            //dataType: 'json', 
            success: function(data) { 
                for(var i=0;i<data.length;i++) grid.jqGrid('addRowData',i+1,{ profile_name: data[i]});
                grid.trigger("reloadGrid");
            }
        });
    };
}
  
var users = new Users();

/* groups functions */

function loadGroups (container_id, elem_id) {
    create_grid({
        url: '/api/gp?gp_type=User',
        content_container_id: container_id,
        grid_id: 'groups_list',
        colNames: [ 'group id', 'group name', 'group type' ],
        colModel: [ 
            { name: 'gp_id', index: 'gp_id', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'gp_name', index: 'gp_name', width: 90, sorttype: "date"},
            { name: 'gp_type', index: 'gp_type', width: 200 }
        ]
    });
}

function groupsList (container_id, elem_id) {
    function createAddGroupButton(cid) {   
        var group_fields = {
            gp_name: {
                label: 'Group Name',
                type: 'text'
            },
            gp_type: {
                type: 'select',
                options:  [ 'User', 'Cluster', 'System image', 'Host',
                            'Processor model', 'Host model', 'Powersupply card model',
                            'Distribution', 'Kernel'
                ]
            },
            gp_system: {
                type: 'hidden',
                value: '0'
            },
            gp_desc: {
                label: 'Description',
                type: 'textarea'
            },
        };
        var group_opts = {
            title: 'Add a Group',
            name: 'gp',
            fields: group_fields,
        };
                    
        var button = $("<button>", {html : 'Add a group'}).button({
          icons : { primary : 'ui-icon-plusthick' }
        });
        button.bind('click', function() {
            new ModalForm(group_opts).start();
        });   
        $('#' + cid).append(button);
    };
    
    var container = $('#' + container_id);
    create_grid({
        url: '/api/gp?gp_type=User',
        content_container_id: container_id,
        grid_id: 'groups_list',
        colNames: [ 'group id', 'group name', 'group type' ],
        colModel: [
            { name: 'gp_id', index: 'gp_id', width:60, sorttype: "int", hidden: true, key: true },
            { name: 'gp_name', index: 'gp_name', width: 90, sorttype: "date"},
            { name: 'gp_type', index: 'gp_type', width: 200,}
        ]
    });
    
    createAddGroupButton(container_id);
}

/* permissions functions */

function _generatePermissionsSelect(container, condition, changeCallback, callback) {
    changeCallback  = changeCallback || $.noop;
    callback        = callback || $.noop;
    $.ajax({
        url     : '/api/gp?' + condition,
        type    : 'GET',
        success : function(data) {
            var gpselect    = $('<select>', { rel : $(container).attr('rel') }).prependTo(container).bind('change', changeCallback);
            for (var i in data) if (data.hasOwnProperty(i)) {
                $(gpselect).append($("<option>", { html : data[i].gp_name, rel : 'gp', value : data[i].gp_id }));
            }
            if (changeCallback !== $.noop) {
                $(gpselect).change();
            }
            callback(gpselect);
        }
    });
}

function permissions(cid) {
    var     container           = $('#' + cid);
    var     struct              = $('<table>').appendTo(container);
    var     groupSelector       = $('<td>', { colspan : 2 }).appendTo($('<tr>').appendTo(struct));
    var     line                = $('<tr>').appendTo(struct);
    var     userGroupSelector   = $('<td>', { rel : 'users' }).appendTo(line);
    var     targetGroupSelector = $('<td>', { rel : 'target' }).appendTo(line);

    var     lastUsrGrpSel   = {};

    var cb                      = function(select) {
        var name;
        $(groupSelector).children('select').children('option').each(function() {
            if ($(this).attr('selected') != null) {
                name    = $(this).text().toLowerCase();
            }
        });
        $.ajax({
            url     : '/api/' + name,
            type    : 'GET',
            success : function(data) {
                $(select).prepend($('<option>', { rel : 'discard', text : 'Groups : ' }));
                if (data.length > 0) {
                    $(select).append($('<option>', { rel : 'discard', text : 'Entities : ' }));
                    for (var i in data) if (data.hasOwnProperty(i)) {
                        var id      = data[i].pk;
                        var text    = data[i][name + '_name'];
                        // Ugly workaround for user
                        if (name === 'user') {
                            text    = data[i]['user_login'];
                        }
                        $(select).append($('<option>', { rel : name, text : text, value : id }));
                    }
                }
            }
        });
    }

    var showtable               = function(event) {
        var a   = $(event.currentTarget).attr('rel');
        // Prevent from selecting option with rel=discard
        for (var i = 0; i < event.currentTarget.childElementCount; ++i) {
            if (event.currentTarget[i].value == event.currentTarget.value) {
                if ($(event.currentTarget[i]).attr('rel') === 'discard') {
                    $(lastUsrGrpSel[a]).attr('selected', true);
                } else {
                    lastUsrGrpSel[a]   = event.currentTarget[i];
                }
                break;
            }
        }

        var a   = $(userGroupSelector).children('select').val();
        var b   = $(targetGroupSelector).children('select').val();
    }

    var groupSelectorChange     = function(event) {
        $(targetGroupSelector).empty();
        var     gname;
        for (var i = 0; i < event.currentTarget.childElementCount; ++i) {
            if (event.currentTarget[i].value == event.currentTarget.value) {
                gname   = event.currentTarget[i].label;
                break;
            }
        }
        _generatePermissionsSelect(targetGroupSelector, 'gp_type=' + gname, showtable, cb);
    }

    _generatePermissionsSelect(groupSelector, 'gp_system=1', groupSelectorChange);
    _generatePermissionsSelect(userGroupSelector, 'gp_system=0&gp_type=User', showtable);

    $.ajax({
        url     : '/api/user?user_system=0',
        type    : 'GET',
        success : function(data) {  
            var select  = $(userGroupSelector).children('select').first();
            $(select).prepend($('<option>', { rel : 'discard', text : 'Groups :' }));
            $(select).append($('<option>', { rel : 'discard', text : 'Users :' }));
            for (var i in data) if (data.hasOwnProperty(i)) {
                $(select).append($('<option>', { rel : 'user', value : data[i].user_id, text : data[i].user_login }));
            }
        }
    });
}
