require('common/formatters.js');

function loadPermissionsModal (container_id, elem_id, element) {
    var container = $('#' + container_id);
    var id = elem_id;
    var methods = [];
    var consumer;

    container.append("Rights for : ");
    var consumer_input = $("<select>", { id : 'consumer' }).appendTo(container);
    var users;
    $.ajax({
        type     : 'GET',
        async    : false,
        url      : '/api/user',
        dataType : 'json',
        success  : $.proxy(function(d) {
            users = d;
        }, this)
    });

    var optGroup = $("<optgroup>", { "label" : "Users" });
    consumer_input.append(optGroup);
    for (var user in users) {
         $("<option>", { value : users[user].pk,
                         text : users[user].user_firstname + ' ' + users[user].user_lastname }
        ).appendTo(optGroup);
    }

    var groups;
    $.ajax({
        type     : 'GET',
        async    : false,
        url      : '/api/gp',
        dataType : 'json',
        success  : $.proxy(function(d) {
            groups = d;
        }, this)
    });

    optGroup = $("<optgroup>", { "label" : "Groups" });
    consumer_input.append(optGroup);
    for (var group in groups) {
         $("<option>", { value : groups[group].pk,
                         text : groups[group].gp_name }
        ).appendTo(optGroup);
    }

    var grid = create_grid( {
        dataType: 'local',
        content_container_id: container_id,
        grid_id: 'entity_permissions_list_' + elem_id,
        grid_class: 'entity_permissions_list',
        rowNum : 25,
        colNames: [ 'name', 'description', 'allowed', 'inherited' ],
        colModel: [ {
                        name: 'name',
                        index: 'name',
                        key: true
                    },
                    {
                        name: 'description',
                        index: 'description'
                    },
                    {
                        name: 'allowed',
                        index: 'allowed',
                        editable: true,
                        edittype: 'checkbox',
                        editoptions: {
                            value: "True:False"
                        },
                        formatter: "checkbox",
                        formatoptions: { disabled : false },
                        width: 20,
                    },
                    {
                        name: 'inherited',
                        index: 'inherited',
                        editable: false,
                        edittype: 'checkbox',
                        editoptions: {
                            value: "True:False"
                        },
                        formatter: "checkbox",
                        formatoptions: { disabled : true },
                        width: 20,
                    } ],
        action_delete : 'no'
    } );

    grid.clearGridData(true);

    grid.bind('reloadGrid', function () {
        $.ajax( {
            url : '/api/attributes/' + element,
            async : false,
            success : function (data) {
                          $.each(data.methods, function (index, value) {
                              value.allowed = "False";
                              value.inherited = "False";
                          } );
                          methods = data.methods;
                      }
        } );

        $.ajax({
            type     : 'GET',
            async    : false,
            url      : '/api/entity/' + $("#consumer").val(),
            dataType : 'json',
            success  : function(e) {
                consumer = e;
            }
        });

        function getRights(data, inherited) {
            $.each(data, function (index, value) {
                var method = methods[value.entityright_method];
                if (method) {
                    if (inherited) {
                        method.inherited = "True";
                    } else {
                        method.allowed = "True";
                    }
                    method.entityright_id = value.entityright_id;
                }
            } );
        }

        // Does the consumer have rights on the entity ?
        $.ajax( {
            url : '/api/' + element + '/' + id + '/entityright_entityrights_consumed?entityright_consumer_id=' + $("#consumer").val(),
            async : false,
            success: function (data) { getRights(data); }
        } );

        // Is the entity in a group the consumer has rights on ?
        $.ajax( {
            url : '/api/' + element + '/' + id + '/gps/entityright_entityrights_consumed?entityright_consumer_id=' + $("#consumer").val(),
            async : false,
            success: function (data) { getRights(data, true); }
        } );

        // Is the entity in a group the consumer groups have rights on ?
        $.ajax( {
            url : '/api/entity/' + $("#consumer").val() + '/gps/entityright_entityright_consumers?entityright_consumed_id=' + id,
            async : false,
            success: function (data) { getRights(data, true); }
        } );

        // Is the consumer in a group that have rights on the entity ?
        $.ajax( {
            url : '/api/entity/' + $("#consumer").val() + '/gps/entityright_entityright_consumers?entityright_consumed_id=' + id,
            async : false,
            success: function (data) { getRights(data, true); }
        } );

        grid.clearGridData(true);

        var methodsArray = new Array();
        var n = 0;
        $.each(methods, function(index, value) { 
            grid.addRowData(n + 1, {
                "name" : index,
                "description" : value.description,
                "allowed" : value.allowed,
                "inherited" : value.inherited
            } );
        } );
    });

    $(grid).trigger("reloadGrid");

    consumer_input.change(
        function (e) {
            $(grid).trigger("reloadGrid");
        }
    );

    function save() {
        var rows = $(grid).getRowData();
        for (var i = 0; i < rows.length; i++) {
            var data = rows[i];
            var method = methods[data.name];
            if (data.allowed == "True" && method.allowed == "False") {
                $.ajax( {
                    url: "/api/entity/" + id + "/addPerm",
                    contentType   : 'application/json',
                    data: JSON.stringify( {
                        consumer: consumer,
                        method: data.name
                    } ),
                    type: "POST"
                } );
            } else if (data.allowed == "False" && method.allowed == "True") {
                $.ajax( {
                    url: "/api/entity/" + id + "/removePerm",
                    contentType   : 'application/json',
                    data: JSON.stringify( {
                        consumer: consumer,
                        method: data.name
                    } ),
                    type: "POST"
                } );
            }
        }
    }

    return save;
}

