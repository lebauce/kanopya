function usersList (container_id, elem_id) {
    function createAddUserButton(cid) {
        var user_fields = {
            user_firstname: {
                label: 'First Name',
                type: 'text'
            },
            user_lastname: {
                label: 'Last Name'
            },
            user_email: {
                label: 'Email'
            },
            user_desc: {
                label: 'Description',
                type: 'textarea'
            },
            user_login: {
                label: 'Login'
            },
            user_password: {
                label: 'Password'
            },
        };
        var user_opts = {
            title: 'Add a user',
            name: 'user',
            fields: user_fields,
        };
                    
        var button = $("<button>", {html : 'Add a user'});
        button.bind('click', function() {
            new ModalForm(user_opts).start();
        });   
        $('#' + cid).append(button);
    };
    
    var container = $('#' + container_id);
    create_grid({
        url: '/api/user',
        content_container_id: container_id,
        grid_id: 'users_list',
        colNames: [ 'user id', 'user login', 'user email' ],
        colModel: [
            { name: 'user_id', index: 'user_id', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'user_login', index: 'user_login', width: 90, sorttype: "date" },
            { name: 'user_email', index: 'user_email', width: 200}
        ]
    });
    createAddUserButton(container_id);
}

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
                    
        var button = $("<button>", {html : 'Add a group'});
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
