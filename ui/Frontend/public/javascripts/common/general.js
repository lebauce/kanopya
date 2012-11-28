/* This file is a collection of general and common tools for javascript/jQuery Kanopya UI */

Object.size = function(obj) {
    var size = 0, key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) size++;
    }
    return size;
};

// getMathematicOperator is function that take in input a formula and return the mathemathic operand present in.

function getMathematicOperator(formula) {
    symbols = ['+','-','\/','*','%'];
    var encounteredSymbol;
    // detect if there a math symbol in formula :
    for ( var i=0; i<symbols.length; i++) {
        var nbOfCurrentSymbol = formula.split(/symbols[i]/g).length - 1;
        if ( nbOfCurrentSymbol != 0 ) {
            encounteredSymbol = symbols[i];            
        }
    }
    return encounteredSymbol;
}

/*
 * Allow to call a method using api, with a password as param
 * This method handle password dialog and waiting popup
 *  - login        : 'username',
 *  - dialog_title : 'Title',
 *  - url          : '/api/entity/xxx/methodName',
 *  - data         : {}, extra data to transmit besides password
 *  - success      : function(data) { }
 */
function callMethodWithPassword( options ) {
    var dialog = $("<div>", { css : { 'text-align' : 'center' } });

    dialog.append($("<label>", { for : 'meth_password', text : 'Please enter ' + options.login + ' password :' }));
    dialog.append($("<input>", { id : 'meth_password', name : 'meth_password', type : 'password' }));
    dialog.append($("<div>", { id : "meth_passworderror", class : 'ui-corner-all' }));
    // Create the modal dialog
    $(dialog).dialog({
        modal           : true,
        title           : options.dialog_title,
        resizable       : false,
        closeOnEscape   : false,
        buttons         : {
            'Ok'    : function() {
                $("div#meth_passworderror").removeClass("ui-state-error").empty();
                var passwd          = $("input#meth_password").attr('value');
                var ok              = false;
                // If a password was typen, then we can submit the form
                if (passwd !== "" && passwd !== undefined) {
                    // Display waiting popup
                    var waitingPopup    = $("<div>", { text : 'Waiting...' }).css('text-align', 'center').dialog({
                        resizable   : false,
                        onClose     : function() { $(this).remove(); }
                    });
                    $(waitingPopup).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();

                    var req_data = { password : passwd };
                    $.extend(req_data, options.data);

                    var response_data;
                    $.ajax({
                        url         : options.url,
                        type        : 'POST',
                        async       : false,
                        data        : JSON.stringify(req_data),
                        contentType : 'application/json',
                        complete    : function(data) {
                            $(waitingPopup).dialog('close');
                        },
                        success     : function(data) {
                            if (data.error) {
                                alert(data.error);
                            } else {
                                ok  = true;
                                response_data = data;
                            }
                        },
                        error       : function(data) {
                            var error_msg;
                            try {
                                error_msg = JSON.parse(data.responseText).reason;
                            }
                            catch (e) {
                                // Can't parse response due to special characters
                                if (data.responseText.indexOf('Invalid login/password') > -1) {
                                    error_msg = "Invalid login/password";
                                } else {
                                    error_msg = data.responseText;
                                }
                            }
                            $("input#meth_password").val("");
                            $("div#meth_passworderror").text(error_msg).addClass('ui-state-error');
                        }
                    });
                    // If the form succeed, then we can close the dialog
                    if (ok === true) {
                        $(this).remove();
                        options.success(response_data);
                    }
                } else {
                    $("input#meth_password").css('border', '1px solid #f00');
                }
            },
            'Cancel': function() {
                $(this).remove();
            }
        }
    });
    $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
}


/*
* convertUnits is used to convert units specified unitIn argument in value with specified unitOut unit.
* Args :
*   - value     : value in anyway unit
*   - unitIn    : unit attached to value (B,K,M,G,T,P)
*   - unitOut   : expected unit for the value (B,K,M,G,T,P)
*/

function convertUnits(value, unitIn, unitOut) {
    // First, convert the value in bytes :
    var inBytesValue;
    var toReturnValue;
    if (unitIn == "B") {
        inBytesValue = value;
    } else if (unitIn == "K") {
        inBytesValue = value*1024;
    } else if (unitIn == "M") {
        inBytesValue = value*1024*1024;
    } else if (unitIn == "G") {
        inBytesValue = value*1024*1024*1024;
    } else if (unitIn == "T") {
        inBytesValue = value*1024*1024*1024*1024;
    } else if (unitIn == "P") {
        inBytesValue = value*1024*1024*1024*1024*1024;
    }
    // Second, convert the inBytesValue to the expected value :
    if (unitOut == "B") {
        toReturnValue = inBytesValue;
    } else if (unitOut == "K") {
        toReturnValue = inBytesValue/1024;
    } else if (unitOut == "M") {
        toReturnValue = inBytesValue/1024/1024;
    } else if (unitOut == "G") {
        toReturnValue = inBytesValue/1024/1024/1024;
    } else if (unitOut == "T") {
        toReturnValue = inBytesValue/1024/1024/1024/1024;
    } else if (unitOut == "P") {
        toReturnValue = inBytesValue/1024/1024/1024/1024/1024;
    }
    return toReturnValue;
}

/*
* getReadableSize is used to convert value in bytes in the most appropriate unit
* Args :
*   - sizeInBytes           : value in bytes unit
*   - exactValue (option)   : if defined then return non floatting exact value (e.g 1153433600 B => 1100 MB instead of 1.1 GB)
*/

function getReadableSize(sizeInBytes, exactValue) {

    var i = 0;
    var byteUnits = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    while ((exactValue && sizeInBytes % 1024 == 0) || (!exactValue && sizeInBytes >= 1024)) {
        sizeInBytes = sizeInBytes / 1024;
        i++;
    }

    return {
        value   : Math.max(sizeInBytes, 0.1).toFixed(exactValue ? 0 : 1),
        unit    : byteUnits[i]
    };
};

/*
 * Add unit info for a input field
 * if unit is 'byte' then add a dropdown list to chose unit (KB,MB,GB,..)
 * Use getUnitMultiplicator() to retrieve selected byte unit to apply to input value
 */

function addFieldUnit(field_info, cont, id, selected_unit) {
    if (field_info && field_info.unit) {
        if (field_info.unit == 'byte') {
            var select_unit     = $('<select>', { id: id });//, width: 50 });
            //var unit_options    = {'B' : 1, 'KB' : 1024, 'MB' : 1024*1024, 'GB' : 1024*1024*1024};
            var unit_options    = {'MB' : 1024*1024, 'GB' : 1024*1024*1024};
            $.each(unit_options, function(label, byte) { select_unit.append($('<option>', { value: byte, html: label}))});
            $(cont).append( select_unit );
            if (selected_unit) {
                select_unit.find('[value="'+ unit_options[selected_unit] +'"]').attr('selected', 'selected');
            }
            select_unit.addClass('wizard-ignore');
        } else {
            $(cont).append($("<label>", { text : ' ' + field_info.unit }));
        }
    }
    return select_unit;
}

// Retrieve selected unit (see addFieldUnit())
function getUnitMultiplicator(id) {
    var select_unit = $('#' + id)[0];
    if (select_unit !== undefined) {
        return $(select_unit).attr('value');
    }
    return 1;
}

/* 
 * Compute the html input type corresponding to
 * the database attribute type.
 */
function toInputType(type) {
    var types = { integer  : 'text',
                  string   : 'text',
                  text     : 'textarea',
                  boolean  : 'checkbox',
                  enum     : 'select',
                  relation : 'select' };

    return types[type] !== undefined ? types[type] : type;
}

/*
 * Return the final value from user input and selected unit (if exists)
 * Manage the case where input can contain '+' and '-'
 */

function getRawValue(val, unit_field_id) {
    var prefix = val.substr(0,1);
    if (prefix == '+' || prefix == '-') {
        val = val.substr(1);
        return prefix + (val * getUnitMultiplicator(unit_field_id));
    }
    return isNaN(parseInt(val)) ? val : val * getUnitMultiplicator(unit_field_id);
}

function ajax(method, route, data, onsuccess, onerror) {
    var response;
    var opts = {
        type        : method,
        async       : false,
        url         : route,
        data        : data,
        dataType    : 'json',
        error       : onerror ? onerror : function(xhr, status, error) {
            console.log('Ajax call failled: ' + xhr.status);
        },
        success     :  function(d) {
            response = d;
            if(onsuccess) {
                onsuccess(d);
            }
        },
    }
    if (data && method === 'POST') {
        opts.data = JSON.stringify(data);
        opts.contentType = 'application/json';
    }
    $.ajax(opts);
    return response;
}

function ucfirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

String.prototype.ucfirst    = function() { return ucfirst(this); };

/*
 * Inform user and display a confirm dialog for deletion for object with potential dependencies (i.e implementing getDependencies)
 * Display the dependencies tree
 * Args:
 *  url         : base route to access object
 *  id          : target entity id
 *  grid_ids    : arrays of the grid id impacted by dependencies deletion (if defined then refresh the grids)
 */
function confirmDeleteWithDependencies(url, id, grid_ids) {
    $.post(
            url + id + '/getDependencies',
            function(dependencies) {
                function makejsTree(data) {
                    var treedata = [];
                    $.each(data, function(k,v) {
                        var treenode = {
                                data    : k
                        }
                        if (Object.size(v) > 0) {
                            treenode.state = 'open';
                            treenode.children = makejsTree( v );
                        }
                        treedata.push( treenode );
                    });
                    return treedata;
                };

                var confirm_button_label;
                var cancel_button_label;
                var browser = $('<div>');
                if (Object.size(dependencies) > 0) {
                    var tree_cont = $('<div>', {style : 'height:300px'});
                    var msg = $('<span>', {html : 'This object has some dependencies. Are you sure you want to delete it and all its dependencies?'});
                    browser.append(msg).append($('<hr>')).append($('<h3>', {html : 'Dependencies :'}));
                    browser.append(tree_cont);
                    require('jquery/jquery.jstree.js');
                    tree_cont.jstree({
                        "plugins"   : ["themes","json_data","ui"],
                        "themes"    : {
                            url : "css/jstree_themes/default/style.css",
                            icons : false
                        },
                        "json_data" : {
                            "data"                  : makejsTree(dependencies),
                            "progressive_render"    : true
                        }
                    });
                    confirm_button_label = 'Delete all';
                    cancel_button_label  = 'Cancel';
                } else {
                    browser.append($('<span>', { html : 'Are you sure?'}));
                    confirm_button_label = 'Yes';
                    cancel_button_label  = 'No';
                }

                var buttons = {};
                buttons[confirm_button_label] = function () {
                    $.ajax({
                        type    : 'DELETE',
                        url     : url + id,
                        success : function() {
                            $.each( grid_ids, function(idx,grid_id) {$('#' + grid_id).trigger('reloadGrid')});
                        }
                    });
                    $(this).dialog("close");
                }
                buttons[cancel_button_label] = function () {
                    $(this).dialog("close");
                }

                browser.dialog({
                    title   : 'Confirm delete',
                    modal   : true,
                    width   : '400px',
                    buttons : buttons,
                    close: function (event, ui) {
                        $(this).remove();
                    }
                });
            }
    );
}

// On load we bind keydown event
// If 'enter' is pressed we trigger click on 'Ok' button
$(document).ready(function () {
    $(document).keydown( function(e) {
        if(e.which == 13) { // enter pressed
            if(!$("input,textarea").is(":focus")){
                $('.ui-button:contains("Ok"):visible').click();
            }
        }
    });
});
