/* This file is a collection of general and common tools for javascript/jQuery Kanopya UI */

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
        draggable       : false,
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
                        draggable   : false,
                        resizable   : false,
                        onClose     : function() { $(this).remove(); }
                    });
                    $(waitingPopup).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
                    var response_data;
                    $.ajax({
                        url         : options.url,
                        type        : 'POST',
                        async       : false,
                        data        : JSON.stringify({
                            password    : passwd
                        }),
                        contentType : 'application/json',
                        complete    : function(data) { $(waitingPopup).dialog('close'); },
                        success     : function(data) {
                            if (data.error) {
                                alert(data.error);
                            } else {
                                ok  = true;
                                response_data = data;
                            }
                        },
                        error       : function(data) {
                            //$("input#meth_password").val("");
                            //$("div#meth_passworderror").text(JSON.parse(data.responseText).reason).addClass('ui-state-error');
                        }
                    });
                    // If the form succeed, then we can close the dialog
                    if (ok === true) {
                        $(this).dialog('destroy');
                        options.success(response_data);
                    }
                } else {
                    $("input#meth_password").css('border', '1px solid #f00');
                }
            },
            'Cancel': function() {
                $(this).dialog('destroy');
            }
        }
    });
    $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
}
